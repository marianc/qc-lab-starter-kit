import React, { useEffect, useState, useCallback, useMemo } from 'react';
import CertificateDialog from '@/components/certificates/CertificateDialog';
import CertificationStatusDialog from '@/components/certificates/CertificationStatusDialog';
import CertificateDetailView from '@/components/certificates/CertificateDetailView';
import styles from './CertificatesPage.module.css';
import type { CertificateDto } from '@/types/certificate';
import type { MaterialDto } from '@/types/material';
import type { TestDto } from '@/types/test';
import type { UserSessionDto } from '@/types/auth';
import type { CertificationStatusDto } from '@/types/certificationStatus';
import certificatesService from '@/services/certificatesService';
import authService from '@/services/authService';
import materialsService from '@/services/materialsService';
import testsService from '@/services/testsService';
import certificationStatusService from '@/services/certificationStatusService';
import { formatDate } from '@/lib/utils';

const PER_PAGE = 15;

const CertificatesPage: React.FC = () => {
  const [certificates, setCertificates] = useState<CertificateDto[]>([]);
  const [materials, setMaterials] = useState<MaterialDto[]>([]);
  const [allTests, setAllTests] = useState<TestDto[]>([]);
  const [currentUser, setCurrentUser] = useState<UserSessionDto | null>(null);
  const [isQCPersonnel, setIsQCPersonnel] = useState(false);
  
  const [currentPage, setCurrentPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [loading, setLoading] = useState(false);

  const [selectedMaterialId, setSelectedMaterialId] = useState<number | undefined>(undefined);
  const [filterSubmissionYear, setFilterSubmissionYear] = useState<number | undefined>(undefined);
  const [filterSubmissionMonth, setFilterSubmissionMonth] = useState<number | undefined>(undefined);

  const [showDialog, setShowDialog] = useState(false);
  const [showStatusDialog, setShowStatusDialog] = useState(false);
  const [certificationStatusItems, setCertificationStatusItems] = useState<CertificationStatusDto[]>([]);
  
  const [selectedCertificateId, setSelectedCertificateId] = useState<number | null>(null);
  const [isDetailsOpen, setIsDetailsOpen] = useState(false);
  const [lastViewedCertificateId, setLastViewedCertificateId] = useState<number | null>(null);

  const yearOptions = useMemo(() => {
    const currentYear = new Date().getFullYear();
    return Array.from({ length: 5 }, (_, i) => currentYear - i);
  }, []);

  const monthOptions = Array.from({ length: 12 }, (_, i) => i + 1);

  const fetchCertificates = useCallback(async (page: number, loadMore: boolean = false, refreshAll: boolean = false) => {
    setLoading(true);
    try {
      let pageToFetch = refreshAll ? 1 : page;
      let countToFetch = PER_PAGE;
      
      if (refreshAll) {
        // We want to fetch all currently loaded records
        // Use a functional update or a local variable if we could, 
        // but since we need it for the API call, we'll use the state value.
        // To avoid stale closures without depending on currentPage, we'll pass it if needed, 
        // but for refreshAll we can just use the current state value safely enough if called from inside the component.
        countToFetch = currentPage * PER_PAGE;
      }

      const result = await certificatesService.getAllCertificates(
        pageToFetch,
        countToFetch,
        isQCPersonnel,
        selectedMaterialId,
        filterSubmissionYear,
        filterSubmissionMonth
      );

      if (loadMore) {
        setCertificates(prev => [...prev, ...result.certificates]);
      } else {
        setCertificates(result.certificates);
      }
      setTotalPages(Math.ceil(result.totalCount / PER_PAGE));
      if (!refreshAll) {
        setCurrentPage(result.currentPage);
      }
    } catch (err) {
      console.error('Error fetching certificates:', err);
    } finally {
      setLoading(false);
    }
  }, [isQCPersonnel, selectedMaterialId, filterSubmissionYear, filterSubmissionMonth, currentPage]);

  useEffect(() => {
    const init = async () => {
      const user = await authService.me();
      setCurrentUser(user);
      if (user) {
        const isQC = user.roles.includes('QcPers');
        setIsQCPersonnel(isQC);
        
        const [materialsData, testsData, result] = await Promise.all([
          materialsService.getAllMaterials(),
          testsService.getAllTests(),
          certificatesService.getAllCertificates(
            1,
            PER_PAGE,
            isQC,
            selectedMaterialId,
            filterSubmissionYear,
            filterSubmissionMonth
          )
        ]);
        setMaterials(materialsData);
        setAllTests(testsData);
        setCertificates(result.certificates);
        setTotalPages(Math.ceil(result.totalCount / PER_PAGE));
        setCurrentPage(result.currentPage);
      }
    };
    init();
  }, []); // Only on mount

  useEffect(() => {
    if (currentUser) {
      fetchCertificates(1);
    }
  }, [selectedMaterialId, filterSubmissionYear, filterSubmissionMonth]);

  const handleApplyFilters = () => {
    setCurrentPage(1);
    fetchCertificates(1, false);
  };

  const handleExportExcel = async () => {
    try {
      await certificatesService.exportExcel({
        isQCPersonnel,
        materialId: selectedMaterialId,
        submissionYear: filterSubmissionYear,
        submissionMonth: filterSubmissionMonth,
        loadedPages: currentPage
      });
    } catch (err) {
      console.error('Failed to export quality certificates to Excel', err);
    }
  };

  const handleLoadMore = () => {
    if (currentPage < totalPages) {
      fetchCertificates(currentPage + 1, true);
    }
  };

  const openStatusDialog = async () => {
    try {
      const items = await certificationStatusService.getCertificationStatus();
      setCertificationStatusItems(items);
      setShowStatusDialog(true);
    } catch (err) {
      console.error('Error fetching certification status:', err);
    }
  };

  const handleAddCertificate = async (item: CertificationStatusDto) => {
    if (!currentUser) return;
    try {
      const res = await certificatesService.generateCertificate({
        materialId: item.materialId,
        controlCodeId: item.controlCodeId,
        userId: currentUser.id
      });
      setShowStatusDialog(false);
      await fetchCertificates(1, false, true);
      if (res) {
        setSelectedCertificateId(res.id);
        setIsDetailsOpen(true);
      }
    } catch (err) {
      console.error('Error generating certificate:', err);
    }
  };

  const handleDetailsClose = async (viewedId?: number) => {
    setIsDetailsOpen(false);
    setSelectedCertificateId(null);
    await fetchCertificates(1, false, true);
    if (viewedId !== undefined) {
      setLastViewedCertificateId(viewedId);
    }
  };

  const handleCertificateCreated = (id: number) => {
    setShowDialog(false);
    fetchCertificates(1, false, true);
    setSelectedCertificateId(id);
    setIsDetailsOpen(true);
  };

  return (
    <div className="page-container">
      <h1 className="page-title">Quality Certificates</h1>
      {isQCPersonnel && (
        <div className={styles.addButtons}>
          <button onClick={() => setShowDialog(true)} className="action-button primary">Add New Certificate</button>
          <button onClick={openStatusDialog} className="action-button secondary">Certification Status</button>
        </div>
      )}

      <div className={styles.filters}>
        <div className={styles.filterGroup}>
          <label htmlFor="material">Material:</label>
          <select 
            id="material" 
            value={selectedMaterialId || ''} 
            onChange={(e) => setSelectedMaterialId(e.target.value ? parseInt(e.target.value) : undefined)}
            className="form-control"
          >
            <option value="">All</option>
            {materials.map(m => (
              <option key={m.id} value={m.id}>{m.name}</option>
            ))}
          </select>
        </div>

        <div className={styles.filterGroup}>
          <label>Year:</label>
          <select 
            value={filterSubmissionYear || ''} 
            onChange={(e) => setFilterSubmissionYear(e.target.value ? parseInt(e.target.value) : undefined)}
            className="form-control"
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
              value={filterSubmissionMonth || ''} 
              onChange={(e) => setFilterSubmissionMonth(e.target.value ? parseInt(e.target.value) : undefined)}
              className="form-control"
            >
              <option value="">All</option>
              {monthOptions.map(month => (
                <option key={month} value={month}>{month}</option>
              ))}
            </select>
          </div>
        )}

        <button onClick={handleApplyFilters} className="action-button primary">Apply Filters</button>
        <button onClick={handleExportExcel} className="action-button secondary">Export to Excel</button>
      </div>

      <div className="page-info">
        <span>Loaded pages: {currentPage} / {totalPages}</span>
      </div>

      <table className="data-table">
        <thead>
          <tr>
            <th>ID</th>
            <th>Material Name</th>
            <th>Control Code</th>
            <th>Is Conforming</th>
            <th>Date Submitted</th>
            <th>Replaced Certificate ID</th>
            <th>Date Cancelled</th>
            <th>Status</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          {certificates.map(certificate => (
            <tr key={certificate.id} className={certificate.id === lastViewedCertificateId ? 'highlighted-row' : ''}>
              <td>{certificate.id}</td>
              <td>{certificate.materialName}</td>
              <td>{certificate.controlCode}</td>
              <td>{certificate.isConformingSpec ? 'Yes' : 'No'}</td>
              <td>{formatDate(certificate.dateSubmitted)}</td>
              <td>{certificate.certificateReplacedId || '-'}</td>
              <td>{formatDate(certificate.dateCancelled)}</td>
              <td>
                <span style={{ 
                  color: certificate.status === 'Draft' ? 'red' : certificate.status === 'Cancelled' ? 'orange' : certificate.status === 'Submitted' ? 'green' : 'inherit',
                  fontWeight: 'bold'
                }}>
                  {certificate.status}
                </span>
                {certificate.hasTestFromCancelledReport && certificate.isSubmitted && (
                  <span className={styles.warningMark} title="Has test from cancelled report"> !</span>
                )}
              </td>
              <td>
                <button 
                  onClick={() => { setSelectedCertificateId(certificate.id); setIsDetailsOpen(true); }} 
                  className={`action-button ${certificate.status === 'Draft' ? 'primary' : 'secondary'} small-button`}
                >
                  Details
                </button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>

      {currentPage < totalPages && (
        <div className={styles.loadMoreContainer}>
          <button onClick={handleLoadMore} className="action-button secondary" disabled={loading}>
            {loading ? 'Loading...' : 'Load next 15 records'}
          </button>
        </div>
      )}

      {showDialog && (
        <CertificateDialog 
          open={showDialog} 
          onClose={() => setShowDialog(false)} 
          onCreated={handleCertificateCreated} 
        />
      )}
      
      {showStatusDialog && (
        <CertificationStatusDialog 
          open={showStatusDialog} 
          items={certificationStatusItems} 
          onClose={() => setShowStatusDialog(false)} 
          onAddCertificate={handleAddCertificate} 
        />
      )}

      {isDetailsOpen && selectedCertificateId !== null && (
        <CertificateDetailView 
          certificateId={selectedCertificateId} 
          onClose={handleDetailsClose} 
          allTests={allTests}
          currentUser={currentUser}
          breadcrumbs={['Certificates']} 
        />
      )}
    </div>
  );
};

export default CertificatesPage;