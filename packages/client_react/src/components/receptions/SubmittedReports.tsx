import React, { useEffect, useState } from 'react';
import { useAuthStore } from '@/store/authStore';
import ReportDetailView from '@/components/reports/ReportDetailView';
import type { ReportSummaryDto } from '@/types/reception';
import receptionsService from '@/services/receptionsService';
import { formatDate } from '@/lib/utils';

interface Props {
  receptionId: number;
  refreshTrigger?: any;
  breadcrumbs: string[];
}

const SubmittedReports: React.FC<Props> = ({ 
  receptionId, 
  refreshTrigger, 
  breadcrumbs 
}) => {
  const { user: currentUser } = useAuthStore();
  const [reports, setReports] = useState<ReportSummaryDto[]>([]);
  const [selectedReportId, setSelectedReportId] = useState<number | null>(null);

  useEffect(() => {
    if (receptionId > 0) {
      loadReports();
    }
  }, [receptionId, refreshTrigger]);

  const loadReports = async () => {
    try {
      const data = await receptionsService.getReceptionReports(receptionId);
      setReports(data);
    } catch (err) {
      console.error('Failed to load reception reports:', err);
    }
  };

  const truncate = (text?: string | null, length: number = 25) => {
    if (!text) return '-';
    return text.length > length ? text.substring(0, length) + '...' : text;
  };

  return (
    <div className="submitted-reports">
      {reports.length > 0 ? (
        <>
          <h2 className="section-title">Submitted Testing Reports</h2>
          <table className="data-table">
            <thead>
              <tr>
                <th>ID</th>
                <th>Submission Date</th>
                <th>Submission Person</th>
                <th>Submission Comment</th>
                <th>Replaced Report ID</th>
                <th>Cancellation Date</th>
                <th>Cancellation Person</th>
                <th>Cancellation Comment</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {reports.map(report => (
                <tr key={report.id}>
                  <td>{report.id}</td>
                  <td>{formatDate(report.dateSubmitted || '')}</td>
                  <td>{report.userSubmittedTag}</td>
                  <td title={report.commentsSubmitted || ''}>{truncate(report.commentsSubmitted)}</td>
                  <td>{report.reportReplacedId || '-'}</td>
                  <td>{formatDate(report.dateCancelled || '')}</td>
                  <td>{report.userCancelledTag || '-'}</td>
                  <td title={report.commentsCancelled || ''}>{truncate(report.commentsCancelled)}</td>
                  <td>
                    <button 
                      onClick={() => setSelectedReportId(report.id)} 
                      className="action-button secondary small-button"
                    >
                      View
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </>
      ) : (
        <p className="no-data-message">No submitted reports</p>
      )}

      {selectedReportId && (
        <ReportDetailView 
          reportId={selectedReportId} 
          onClose={() => setSelectedReportId(null)} 
          onChanged={loadReports}
          breadcrumbs={breadcrumbs} 
        />
      )}
    </div>
  );
};

export default SubmittedReports;
