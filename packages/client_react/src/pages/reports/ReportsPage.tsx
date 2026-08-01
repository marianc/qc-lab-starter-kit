import React, { useState, useEffect, useCallback } from 'react';
import ReportDetailView from '@/components/reports/ReportDetailView';
import styles from './ReportsPage.module.css';
import type { ReportDto } from '@/types/report';
import type { ReceptionTypeDto } from '@/types/receptionType';
import type { MaterialDto } from '@/types/material';
import type { UserSessionDto } from '@/types/auth';
import authService from '@/services/authService';
import reportsService from '@/services/reportsService';
import receptionTypesService from '@/services/receptionTypesService';
import materialsService from '@/services/materialsService';
import { formatDate } from '@/lib/utils';

const ReportsPage: React.FC = () => {
  const [reports, setReports] = useState<ReportDto[]>([]);
  const [receptionTypes, setReceptionTypes] = useState<ReceptionTypeDto[]>([]);
  const [materials, setMaterials] = useState<MaterialDto[]>([]);
  const [currentUser, setCurrentUser] = useState<UserSessionDto | null>(null);
  const [currentPage, setCurrentPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const perPage = 15;

  const [selectedReceptionType, setSelectedReceptionType] = useState<number | null>(null);
  const [selectedMaterialId, setSelectedMaterialId] = useState<number | null>(null);
  const [filterSubmissionYear, setFilterSubmissionYear] = useState<number | null>(null);
  const [filterSubmissionMonth, setFilterSubmissionMonth] = useState<number | null>(null);

  const [selectedReportId, setSelectedReportId] = useState<number | null>(null);
  const [isDetailsOpen, setIsDetailsOpen] = useState(false);
  const [lastViewedReportId, setLastViewedReportId] = useState<number | null>(null);
  const [isInitialized, setIsInitialized] = useState(false);

  const currentYear = new Date().getFullYear();
  const yearOptions = Array.from({ length: 5 }, (_, i) => currentYear - i);
  const monthOptions = Array.from({ length: 12 }, (_, i) => i + 1);

  const fetchReports = useCallback(async (page = 1, loadMore = false, refreshAll = false) => {
    const user = await authService.me();
    if (!user) return;

    const pageToFetch = refreshAll ? 1 : page;
    const countToFetch = refreshAll ? currentPage * perPage : perPage;

    try {
      const result = await reportsService.getAllReports({
        page: pageToFetch,
        pageSize: countToFetch,
        userId: user.id,
        receptionTypeId: selectedReceptionType,
        materialId: selectedMaterialId,
        submissionYear: filterSubmissionYear,
        submissionMonth: filterSubmissionMonth
      });

      if (loadMore) {
        setReports(prev => [...prev, ...result.reports]);
      } else {
        setReports(result.reports);
      }
      
      setTotalPages(Math.ceil(result.totalCount / perPage));
      if (!refreshAll) {
        setCurrentPage(result.currentPage);
      }
    } catch (err) {
      console.error('Failed to fetch reports', err);
    }
  }, [selectedReceptionType, selectedMaterialId, filterSubmissionYear, filterSubmissionMonth, currentPage]);

  useEffect(() => {
    const init = async () => {
      const user = await authService.me();
      setCurrentUser(user);
      
      const [types, mats] = await Promise.all([
        receptionTypesService.getAllReceptionTypes(),
        materialsService.getAllMaterials()
      ]);
      setReceptionTypes(types);
      setMaterials(mats);
      
      // Initial fetch
      if (user) {
        const result = await reportsService.getAllReports({
          page: 1,
          pageSize: perPage,
          userId: user.id
        });
        setReports(result.reports);
        setTotalPages(Math.ceil(result.totalCount / perPage));
      }
      setIsInitialized(true);
    };
    init();
  }, []);

  const handleApplyFilters = () => {
    setCurrentPage(1);
    fetchReports(1, false);
  };

  const handleExportExcel = async () => {
    try {
      await reportsService.exportExcel({
        receptionTypeId: selectedReceptionType,
        materialId: selectedMaterialId,
        submissionYear: filterSubmissionYear,
        submissionMonth: filterSubmissionMonth,
        loadedPages: currentPage
      });
    } catch (err) {
      console.error('Failed to export reports to Excel', err);
    }
  };

  const handleLoadMore = () => {
    if (currentPage < totalPages) {
      fetchReports(currentPage + 1, true);
    }
  };

  const handleViewDetails = (id: number) => {
    setSelectedReportId(id);
    setIsDetailsOpen(true);
  };

  const handleDetailsClose = async (viewedId?: number | null) => {
    setIsDetailsOpen(false);
    setSelectedReportId(null);
    await fetchReports(1, false, true);
    if (viewedId) {
      setLastViewedReportId(viewedId);
    }
  };

  return (
    <div className="page-container">
      <h2 className="page-title">Testing Reports</h2>

      <div className={styles.filters}>
        <div className={styles.filterGroup}>
          <label htmlFor="receptionType">Reception Type:</label>
          <select 
            id="receptionType" 
            className="form-control"
            value={selectedReceptionType || ''} 
            onChange={e => setSelectedReceptionType(e.target.value ? Number(e.target.value) : null)}
          >
            <option value="">All</option>
            {receptionTypes.map(type => (
              <option key={type.id} value={type.id}>{type.name}</option>
            ))}
          </select>
        </div>

        {(selectedReceptionType === 1 || selectedReceptionType === 2) && (
          <div className={styles.filterGroup}>
            <label htmlFor="material">Material:</label>
            <select 
              id="material" 
              className="form-control"
              value={selectedMaterialId || ''} 
              onChange={e => setSelectedMaterialId(e.target.value ? Number(e.target.value) : null)}
            >
              <option value="">All</option>
              {materials.map(m => (
                <option key={m.id} value={m.id}>{m.name}</option>
              ))}
            </select>
          </div>
        )}

        <div className={styles.filterGroup}>
          <label>Year:</label>
          <select 
            className="form-control"
            value={filterSubmissionYear || ''} 
            onChange={e => setFilterSubmissionYear(e.target.value ? Number(e.target.value) : null)}
          >
            <option value="">All</option>
            {yearOptions.map(year => (
              <option key={year} value={year}>{year}</option>
            ))}
          </select>
        </div>

        {filterSubmissionYear && (
          <div className={styles.filterGroup}>
            <label>Month:</label>
            <select 
              className="form-control"
              value={filterSubmissionMonth || ''} 
              onChange={e => setFilterSubmissionMonth(e.target.value ? Number(e.target.value) : null)}
            >
              <option value="">All</option>
              {monthOptions.map(month => (
                <option key={month} value={month}>{month}</option>
              ))}
            </select>
          </div>
        )}

        <button onClick={handleApplyFilters} className="action-button primary filter-apply-button">Apply Filters</button>
        <button onClick={handleExportExcel} className="action-button secondary filter-export-button">Export to Excel</button>
      </div>

      <div className="page-info">
        <span>Loaded pages: {currentPage} / {totalPages}</span>
      </div>

      <table className="data-table">
        <thead>
          <tr>
            <th>ID</th>
            <th>Submitted By</th>
            <th>Submitted Date</th>
            <th>Reception Type</th>
            <th>Material</th>
            <th>Control Code/Category</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          {reports.map(report => (
            <tr key={report.id} className={report.id === lastViewedReportId ? "highlighted-row" : ""}>
              <td>{report.id}</td>
              <td>{report.userSubmittedTag}</td>
              <td>{formatDate(report.dateSubmitted)}</td>
              <td>{report.receptionTypeName}</td>
              <td>{report.materialName}</td>
              <td>{report.controlCodeCategory}</td>
              <td>
                <button onClick={() => handleViewDetails(report.id)} className="action-button secondary small-button">Details</button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>

      {currentPage < totalPages && (
        <div className={styles.loadMoreContainer}>
          <button onClick={handleLoadMore} className="action-button secondary">Load next 15 records</button>
        </div>
      )}

      {isDetailsOpen && selectedReportId !== null && (
        <ReportDetailView 
          reportId={selectedReportId}
          onClose={handleDetailsClose}
          currentUser={currentUser}
          breadcrumbs={["Reports"]}
        />
      )}
    </div>
  );
};

export default ReportsPage;
