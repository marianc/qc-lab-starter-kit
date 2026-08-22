import React, { useState, useEffect, useCallback } from 'react';
import type { AuditLogDto } from '@/types/auditLog';
import auditLogsService, { type AuditLogFilterParams } from '@/services/auditLogsService';
import { formatDate } from '@/lib/utils';
import styles from './AuditLogsTable.module.css';

const AuditLogsTable: React.FC = () => {
  const [logs, setLogs] = useState<AuditLogDto[]>([]);
  const [loading, setLoading] = useState(false);
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const pageSize = 15;

  const [tableName, setTableName] = useState('');
  const [action, setAction] = useState('');
  const [selectedLog, setSelectedLog] = useState<AuditLogDto | null>(null);

  const fetchLogs = useCallback(async () => {
    try {
      setLoading(true);
      const params: AuditLogFilterParams = {
        page,
        pageSize,
        tableName: tableName || null,
        action: action || null,
      };
      const result = await auditLogsService.getAuditLogs(params);
      setLogs(result.auditLogs);
      setTotalPages(Math.ceil(result.totalCount / pageSize));
    } catch (err) {
      console.error('Failed to fetch audit logs:', err);
    } finally {
      setLoading(false);
    }
  }, [page, tableName, action]);

  useEffect(() => {
    fetchLogs();
  }, [fetchLogs]);

  const getActionBadgeClass = (act: string) => {
    switch (act.toUpperCase()) {
      case 'INSERT': return styles.actionInsert;
      case 'UPDATE': return styles.actionUpdate;
      case 'DELETE': return styles.actionDelete;
      default: return '';
    }
  };

  const formatJsonString = (jsonStr: string | null) => {
    if (!jsonStr) return 'N/A';
    try {
      return JSON.stringify(JSON.parse(jsonStr), null, 2);
    } catch {
      return jsonStr;
    }
  };

  const formatRecordKeys = (keys: Record<string, any>) => {
    if (!keys || typeof keys !== 'object') return 'N/A';
    return Object.entries(keys)
      .map(([k, v]) => `${k}: ${v}`)
      .join(', ');
  };

  return (
    <div className={styles.auditTableContainer}>
      <div className={styles.filtersRow}>
        <div className={styles.filterGroup}>
          <label>Table Name</label>
          <input 
            type="text" 
            className={styles.filterInput} 
            placeholder="e.g. measurements" 
            value={tableName} 
            onChange={(e) => { setTableName(e.target.value); setPage(1); }}
          />
        </div>
        <div className={styles.filterGroup}>
          <label>Action</label>
          <select 
            className={styles.filterInput} 
            value={action} 
            onChange={(e) => { setAction(e.target.value); setPage(1); }}
          >
            <option value="">All Actions</option>
            <option value="INSERT">INSERT</option>
            <option value="UPDATE">UPDATE</option>
            <option value="DELETE">DELETE</option>
          </select>
        </div>
      </div>

      <div className={styles.tableWrapper}>
        <table className={styles.table}>
          <thead>
            <tr>
              <th>ID</th>
              <th>Timestamp (UTC)</th>
              <th>Table</th>
              <th>Record Keys</th>
              <th>Action</th>
              <th>User</th>
              <th>Reason for Change</th>
              <th>Client IP</th>
              <th>Details</th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr><td colSpan={9} style={{ textAlign: 'center' }}>Loading audit logs...</td></tr>
            ) : logs.length === 0 ? (
              <tr><td colSpan={9} style={{ textAlign: 'center' }}>No audit trail records found.</td></tr>
            ) : (
              logs.map((log) => (
                <tr key={log.id}>
                  <td>{log.id}</td>
                  <td>{formatDate(log.timestamp)}</td>
                  <td><code>{log.tableName}</code></td>
                  <td><code>{formatRecordKeys(log.recordKeys)}</code></td>
                  <td>
                    <span className={`${styles.actionBadge} ${getActionBadgeClass(log.action)}`}>
                      {log.action}
                    </span>
                  </td>
                  <td>{log.userTag}</td>
                  <td>{log.reasonForChange || '-'}</td>
                  <td>{log.clientIp || '-'}</td>
                  <td>
                    <button 
                      className="action-button secondary small-button" 
                      onClick={() => setSelectedLog(log)}
                    >
                      View Diff
                    </button>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>

      <div className={styles.pagination}>
        <button 
          className="action-button secondary" 
          disabled={page === 1} 
          onClick={() => setPage(p => Math.max(p - 1, 1))}
        >
          Previous
        </button>
        <span>Page {page} of {totalPages || 1}</span>
        <button 
          className="action-button secondary" 
          disabled={page >= totalPages} 
          onClick={() => setPage(p => p + 1)}
        >
          Next
        </button>
      </div>

      {selectedLog && (
        <div className={styles.modalOverlay} onClick={() => setSelectedLog(null)}>
          <div className={styles.modalContent} onClick={(e) => e.stopPropagation()}>
            <div className={styles.modalHeader}>
              <h3>Audit Log Details #{selectedLog.id}</h3>
              <button className={styles.closeButton} onClick={() => setSelectedLog(null)}>&times;</button>
            </div>
            <div className={styles.modalBody}>
              <div className={styles.detailRow}>
                <strong>Table:</strong> <code>{selectedLog.tableName}</code>
              </div>
              <div className={styles.detailRow}>
                <strong>Record Keys:</strong> <code>{JSON.stringify(selectedLog.recordKeys, null, 2)}</code>
              </div>
              <div className={styles.detailRow}>
                <strong>Action:</strong> <span className={`${styles.actionBadge} ${getActionBadgeClass(selectedLog.action)}`}>{selectedLog.action}</span>
              </div>
              <div className={styles.detailRow}>
                <strong>User:</strong> {selectedLog.userTag}
              </div>
              <div className={styles.detailRow}>
                <strong>Timestamp:</strong> {formatDate(selectedLog.timestamp)}
              </div>
              <div className={styles.detailRow}>
                <strong>Client IP:</strong> {selectedLog.clientIp || 'N/A'}
              </div>
              <div className={styles.detailRow}>
                <strong>Reason for Change:</strong> {selectedLog.reasonForChange || 'N/A'}
              </div>
              {selectedLog.changedFields && selectedLog.changedFields.length > 0 && (
                <div className={styles.detailRow}>
                  <strong>Changed Fields:</strong> {selectedLog.changedFields.join(', ')}
                </div>
              )}
              
              <div className={styles.diffContainer}>
                <div className={styles.diffBox}>
                  <h4>Old Data</h4>
                  <pre>{formatJsonString(selectedLog.oldData)}</pre>
                </div>
                <div className={styles.diffBox}>
                  <h4>New Data</h4>
                  <pre>{formatJsonString(selectedLog.newData)}</pre>
                </div>
              </div>
            </div>
            <div className={styles.modalFooter}>
              <button className="action-button secondary" onClick={() => setSelectedLog(null)}>Close</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default AuditLogsTable;
