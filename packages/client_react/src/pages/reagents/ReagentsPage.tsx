import React, { useState, useEffect } from 'react';
import ReagentDialog from '@/components/reagents/ReagentDialog';
import ReagentDetailView from '@/components/reagents/ReagentDetailView';
import styles from './ReagentsPage.module.css';
import type { ReagentDto } from '@/types/reagent';
import reagentsService from '@/services/reagentsService';
import { formatDate } from '@/lib/utils';

const ReagentsPage: React.FC = () => {
  const [reagents, setReagents] = useState<ReagentDto[]>([]);
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState('');
  const [selectedReagentId, setSelectedReagentId] = useState<number | null>(null);
  const [isDetailsOpen, setIsDetailsOpen] = useState(false);
  const [isAddDialogOpen, setIsAddDialogOpen] = useState(false);
  const [lastEditedReagentId, setLastEditedReagentId] = useState<number | null>(null);

  const fetchReagents = async () => {
    try {
      const data = await reagentsService.getAllReagents();
      const sorted = [...data].sort((a, b) => a.name.localeCompare(b.name));
      setReagents(sorted);
    } catch (err) {
      console.error('Failed to fetch reagents', err);
    }
  };

  useEffect(() => {
    fetchReagents();
  }, []);

  const filteredReagents = reagents.filter(r => {
    const searchMatch = !searchTerm || 
      r.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      r.code.toLowerCase().includes(searchTerm.toLowerCase()) ||
      (r.casNumber && r.casNumber.toLowerCase().includes(searchTerm.toLowerCase()));

    const statusMatch = !statusFilter || 
      (statusFilter === 'Active' && !r.isObsolete) ||
      (statusFilter === 'Obsolete' && r.isObsolete);

    return searchMatch && statusMatch;
  });

  const viewReagentDetails = (id: number) => {
    setSelectedReagentId(id);
    setLastEditedReagentId(id);
    setIsDetailsOpen(true);
  };

  const handleDetailsClose = (savedId?: number | null) => {
    setIsDetailsOpen(false);
    setSelectedReagentId(null);
    if (savedId) {
      setLastEditedReagentId(savedId);
      fetchReagents();
    }
  };

  const handleAddDialogClose = (savedId?: number | null) => {
    setIsAddDialogOpen(false);
    if (savedId) {
      setLastEditedReagentId(savedId);
      fetchReagents();
    }
  };

  const handleReagentUpdated = (updatedReagent: ReagentDto) => {
    setReagents(prev => prev.map(r => r.id === updatedReagent.id ? updatedReagent : r));
  };

  return (
    <div className="page-container">
      <h1 className="page-title">Reagents Management</h1>
      <button onClick={() => setIsAddDialogOpen(true)} className="action-button primary">Add New Reagent</button>

      <div className={styles.filters}>
        <div className={styles.filterGroup}>
          <label htmlFor="search-filter">Search:</label>
          <input 
            id="search-filter"
            type="text" 
            className={`form-control ${styles.filterInput}`} 
            placeholder="Name, Code, CAS #" 
            value={searchTerm}
            onChange={e => setSearchTerm(e.target.value)}
          />
        </div>
        <div className={styles.filterGroup}>
          <label htmlFor="status-filter">Status:</label>
          <select 
            id="status-filter"
            className="form-control"
            value={statusFilter}
            onChange={e => setStatusFilter(e.target.value)}
          >
            <option value="">All</option>
            <option value="Active">Active</option>
            <option value="Obsolete">Obsolete</option>
          </select>
        </div>
        <button onClick={fetchReagents} className="action-button primary filter-apply-button">Refresh</button>
      </div>

      <table className="data-table">
        <thead>
          <tr>
            <th>ID</th>
            <th>Name</th>
            <th>Code</th>
            <th>CAS Number</th>
            <th>Norm</th>
            <th>Date Created</th>
            <th>Is Obsolete</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          {filteredReagents.map((reagent) => (
            <tr key={reagent.id} className={reagent.id === lastEditedReagentId ? "highlighted-row" : ""}>
              <td>{reagent.id}</td>
              <td>{reagent.name}</td>
              <td>{reagent.code}</td>
              <td>{reagent.casNumber || "-"}</td>
              <td>{reagent.normName || "-"}</td>
              <td>{formatDate(reagent.dateCreated)}</td>
              <td>
                <span className={`status-badge ${reagent.isObsolete ? 'error' : 'success'}`}>
                  {reagent.isObsolete ? "Yes" : "No"}
                </span>
              </td>
              <td>
                <button 
                  onClick={() => viewReagentDetails(reagent.id)} 
                  className="action-button edit-button small-button"
                >
                  Details
                </button>
              </td>
            </tr>
          ))}
          {filteredReagents.length === 0 && (
            <tr>
              <td colSpan={8} style={{ textAlign: 'center' }}>No reagents found.</td>
            </tr>
          )}
        </tbody>
      </table>

      {isDetailsOpen && selectedReagentId !== null && (
        <ReagentDetailView 
          reagentId={selectedReagentId}
          onClose={handleDetailsClose}
          onReagentUpdated={handleReagentUpdated}
          breadcrumbs={["Reagents"]}
        />
      )}

      {isAddDialogOpen && (
        <ReagentDialog 
          open={true}
          onClose={handleAddDialogClose}
        />
      )}
    </div>
  );
};

export default ReagentsPage;