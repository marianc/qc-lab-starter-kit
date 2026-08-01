import React, { useEffect, useState, useCallback } from 'react';
import { useAuthStore } from '@/store/authStore';
import CertificationDialog from '@/components/receptions/CertificationDialog';
import VerificationDialog from '@/components/receptions/VerificationDialog';
import CategoryVerificationDialog from '@/components/receptions/CategoryVerificationDialog';
import CertificationDetailView from '@/components/receptions/CertificationDetailView';
import VerificationDetailView from '@/components/receptions/VerificationDetailView';
import CategoryVerificationDetailView from '@/components/receptions/CategoryVerificationDetailView';
import styles from './ReceptionsPage.module.css';
import type { ReceptionDto } from '@/types/reception';
import type { ReceptionTypeDto } from '@/types/receptionType';
import type { UserDto } from '@/types/user';
import type { MaterialDto } from '@/types/material';
import type { TestDto } from '@/types/test';
import type { FormDto } from '@/types/form';
import receptionTypesService from '@/services/receptionTypesService';
import usersService from '@/services/usersService';
import materialsService from '@/services/materialsService';
import testsService from '@/services/testsService';
import formsService from '@/services/formsService';
import receptionsService from '@/services/receptionsService';
import { formatDate } from '@/lib/utils';

const ReceptionsPage: React.FC = () => {
  const { user: currentUser } = useAuthStore();
  const [receptions, setReceptions] = useState<ReceptionDto[]>([]);
  const [receptionTypes, setReceptionTypes] = useState<ReceptionTypeDto[]>([]);
  const [submittedUsers, setSubmittedUsers] = useState<UserDto[]>([]);
  const [materials, setMaterials] = useState<MaterialDto[]>([]);
  const [allTests, setAllTests] = useState<TestDto[]>([]);
  const [allForms, setAllForms] = useState<FormDto[]>([]);

  const [currentPage, setCurrentPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const perPage = 15;

  // Filters
  const [filterSubmittedBy, setFilterSubmittedBy] = useState<string>('');
  const [filterType, setFilterType] = useState<string>('');
  const [filterMaterial, setFilterMaterial] = useState<string>('');
  const [filterTestingReport, setFilterTestingReport] = useState<string>('');
  const [filterStatus, setFilterStatus] = useState<string>('');
  const [filterSubmissionYear, setFilterSubmissionYear] = useState<string>('');
  const [filterSubmissionMonth, setFilterSubmissionMonth] = useState<string>('');

  const [selectedReceptionId, setSelectedReceptionId] = useState<number | null>(null);
  const [selectedReceptionTypeId, setSelectedReceptionTypeId] = useState<number | null>(null);
  const [lastVisitedReceptionId, setLastVisitedReceptionId] = useState<number | null>(null);

  const [isCertificationDialogOpen, setIsCertificationDialogOpen] = useState(false);
  const [isVerificationDialogOpen, setIsVerificationDialogOpen] = useState(false);
  const [isCategoryVerificationDialogOpen, setIsCategoryVerificationDialogOpen] = useState(false);

  const [yearOptions, setYearOptions] = useState<number[]>([]);
  const monthOptions = Array.from({ length: 12 }, (_, i) => i + 1);

  useEffect(() => {
    const currentYear = new Date().getFullYear();
    setYearOptions(Array.from({ length: 5 }, (_, i) => currentYear - i));
    fetchDropdownData();
  }, []);

  useEffect(() => {
    if (currentUser) {
      fetchReceptions(1, false);
    }
  }, [currentUser]);

  const fetchDropdownData = async () => {
    try {
      const [types, users, mats, tests, forms] = await Promise.all([
        receptionTypesService.getAllReceptionTypes(),
        usersService.getAllUsers(),
        materialsService.getAllMaterials(),
        testsService.getAllTests(),
        formsService.getAllForms()
      ]);
      setReceptionTypes(types);
      setSubmittedUsers(users);
      setMaterials(mats);
      setAllTests(tests);
      setAllForms(forms);
    } catch (err) {
      console.error('Failed to fetch dropdown data:', err);
    }
  };

  const fetchReceptions = async (page = 1, loadMore = false, refreshAll = false) => {
    if (!currentUser) return;

    const pageToFetch = refreshAll ? 1 : page;
    const countToFetch = refreshAll ? currentPage * perPage : perPage;

    const params: Record<string, any> = {
      page: pageToFetch,
      per_page: countToFetch,
      user_id: currentUser.id
    };

    if (filterSubmittedBy) params.submitted_by = filterSubmittedBy;
    if (filterType) params.type_id = filterType;
    if (filterMaterial) params.material_id = filterMaterial;
    if (filterTestingReport) params.report_submitted = filterTestingReport;
    if (filterStatus) params.status = filterStatus;
    if (filterSubmissionYear) params.submission_year = filterSubmissionYear;
    if (filterSubmissionMonth) params.submission_month = filterSubmissionMonth;

    try {
      const result = await receptionsService.getAllReceptions(params);
      if (loadMore) {
        setReceptions(prev => [...prev, ...result.receptions]);
      } else {
        setReceptions(result.receptions);
      }
      setTotalPages(Math.ceil(result.totalCount / perPage));
      if (!refreshAll) {
        setCurrentPage(result.currentPage);
      }
    } catch (err) {
      console.error('Failed to fetch receptions:', err);
    }
  };

  const applyFilters = () => {
    setCurrentPage(1);
    fetchReceptions(1, false);
  };

  const loadMoreReceptions = () => {
    if (currentPage < totalPages) {
      fetchReceptions(currentPage + 1, true);
    }
  };

  const addNewReception = (typeId: number) => {
    if (typeId === 1) setIsCertificationDialogOpen(true);
    else if (typeId === 2) setIsVerificationDialogOpen(true);
    else if (typeId === 3) setIsCategoryVerificationDialogOpen(true);
  };

  const openDetails = (reception: ReceptionDto) => {
    setSelectedReceptionId(reception.id);
    setSelectedReceptionTypeId(reception.typeId);
    setLastVisitedReceptionId(reception.id);
  };

  const handleCloseDetails = async () => {
    setSelectedReceptionId(null);
    setSelectedReceptionTypeId(null);
    await fetchReceptions(1, false, true);
  };

  const handleDialogSave = async (id: number) => {
    setLastVisitedReceptionId(id);
    setCurrentPage(1);
    await fetchReceptions(1, false);
  };

  return (
    <div className="page-container">
      <h1 className="page-title">Sample Receptions</h1>

      <div className={styles.addButtons}>
        {receptionTypes.map(type => (
          <button key={type.id} onClick={() => addNewReception(type.id)} className="action-button primary">
            Add New {type.name}
          </button>
        ))}
      </div>

      <div className={styles.filters}>
        <div className={styles.filterGroup}>
          <label>Submitted By:</label>
          <select value={filterSubmittedBy} onChange={e => setFilterSubmittedBy(e.target.value)} className="form-control">
            <option value="">All</option>
            {submittedUsers.map(user => (
              <option key={user.id} value={user.id}>{user.tag}</option>
            ))}
          </select>
        </div>
        <div className={styles.filterGroup}>
          <label>Type:</label>
          <select value={filterType} onChange={e => setFilterType(e.target.value)} className="form-control">
            <option value="">All</option>
            {receptionTypes.map(type => (
              <option key={type.id} value={type.id}>{type.name}</option>
            ))}
          </select>
        </div>
        {(filterType === '1' || filterType === '2') && (
          <div className={styles.filterGroup}>
            <label>Material:</label>
            <select value={filterMaterial} onChange={e => setFilterMaterial(e.target.value)} className="form-control">
              <option value="">All</option>
              {materials.map(material => (
                <option key={material.id} value={material.id}>{material.name}</option>
              ))}
            </select>
          </div>
        )}
        <div className={styles.filterGroup}>
          <label>Testing Report:</label>
          <select value={filterTestingReport} onChange={e => setFilterTestingReport(e.target.value)} className="form-control">
            <option value="">All</option>
            <option value="true">Yes</option>
            <option value="false">No</option>
          </select>
        </div>
        <div className={styles.filterGroup}>
          <label>Status:</label>
          <select value={filterStatus} onChange={e => setFilterStatus(e.target.value)} className="form-control">
            <option value="">All</option>
            <option value="Pending">Pending</option>
            <option value="Submitted">Submitted</option>
            <option value="Received">Received</option>
            <option value="Rejected">Rejected</option>
          </select>
        </div>
        <div className={styles.filterGroup}>
          <label>Year:</label>
          <select value={filterSubmissionYear} onChange={e => setFilterSubmissionYear(e.target.value)} className="form-control">
            <option value="">All</option>
            {yearOptions.map(year => (
              <option key={year} value={year}>{year}</option>
            ))}
          </select>
        </div>
        {filterSubmissionYear && (
          <div className={styles.filterGroup}>
            <label>Month:</label>
            <select value={filterSubmissionMonth} onChange={e => setFilterSubmissionMonth(e.target.value)} className="form-control">
              <option value="">All</option>
              {monthOptions.map(month => (
                <option key={month} value={month}>{month}</option>
              ))}
            </select>
          </div>
        )}
        <button onClick={applyFilters} className={`action-button primary ${styles.filterApplyButton}`}>Apply Filters</button>
      </div>

      <div className={styles.pageInfo}>
        <span>Loaded pages: {currentPage} / {totalPages}</span>
      </div>

      <table className="data-table">
        <thead>
          <tr>
            <th>ID</th>
            <th>Submitted By</th>
            <th>Submitted Date</th>
            <th>Type</th>
            <th>Material</th>
            <th>Control Code/Category</th>
            <th className="text-center">Testing Report</th>
            <th>Status</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          {receptions.map(reception => (
            <tr key={reception.id} className={reception.id === lastVisitedReceptionId ? 'highlighted-row' : ''}>
              <td>{reception.id}</td>
              <td>{reception.userSubmittedTag}</td>
              <td>{formatDate(reception.dateSubmitted || '')}</td>
              <td>{reception.receptionTypeName}</td>
              <td>{reception.materialName}</td>
              <td>
                {reception.typeId === 3 ? reception.categoryName : reception.controlCodeName}
              </td>
              <td className="text-center">{reception.reportSubmitted ? 'Yes' : '-'}</td>
              <td>
                <span style={{ 
                  color: reception.status === 'Pending' ? 'orange' : reception.status === 'Submitted' ? 'red' : reception.status === 'Received' ? 'green' : 'inherit',
                  fontWeight: 'bold'
                }}>
                  {reception.status}
                </span>
              </td>
              <td>
                <button onClick={() => openDetails(reception)} className={`action-button ${reception.reportSubmitted ? 'secondary' : 'primary'} small-button`}>Details</button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>

      {currentPage < totalPages && (
        <div className={styles.loadMoreContainer}>
          <button onClick={loadMoreReceptions} className="action-button secondary">Load next 15 records</button>
        </div>
      )}

      {selectedReceptionId && (
        <>
          {selectedReceptionTypeId === 1 && (
            <CertificationDetailView 
              receptionId={selectedReceptionId} 
              onClose={handleCloseDetails} 
              breadcrumbs={['Receptions']} 
              allTests={allTests} 
              allForms={allForms} 
            />
          )}
          {selectedReceptionTypeId === 2 && (
            <VerificationDetailView 
              receptionId={selectedReceptionId} 
              onClose={handleCloseDetails} 
              breadcrumbs={['Receptions']} 
              allTests={allTests} 
              allForms={allForms} 
            />
          )}
          {selectedReceptionTypeId === 3 && (
            <CategoryVerificationDetailView 
              receptionId={selectedReceptionId} 
              onClose={handleCloseDetails} 
              breadcrumbs={['Receptions']} 
              allTests={allTests} 
              allForms={allForms} 
            />
          )}
        </>
      )}
      
      {isCertificationDialogOpen && (
        <CertificationDialog 
          open={true} 
          onSave={handleDialogSave} 
          onClose={() => setIsCertificationDialogOpen(false)} 
        />
      )}

      {isVerificationDialogOpen && (
        <VerificationDialog 
          open={true} 
          onSave={handleDialogSave} 
          onClose={() => setIsVerificationDialogOpen(false)} 
        />
      )}

      {isCategoryVerificationDialogOpen && (
        <CategoryVerificationDialog 
          open={true} 
          onSave={handleDialogSave} 
          onClose={() => setIsCategoryVerificationDialogOpen(false)} 
        />
      )}
    </div>
  );
};

export default ReceptionsPage;
