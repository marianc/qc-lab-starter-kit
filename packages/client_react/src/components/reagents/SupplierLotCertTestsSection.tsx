import React, { useState, useEffect } from 'react';
import type { ReagentLotDto, ReagentSupplierLotCertTestDto } from '@/types/reagent';
import type { TestDto } from '@/types/test';
import reagentsService from '@/services/reagentsService';
import testsService from '@/services/testsService';
import SupplierLotCertTestDialog from './SupplierLotCertTestDialog';
import { ConfirmationDialog } from '@/components/common';
import { 
  DetailContainer, 
  DetailColumn, 
  DetailItem 
} from '@/components/common/ui';
import styles from './SupplierLotCertTestsSection.module.css';

interface SupplierLotCertTestsSectionProps {
  lot: ReagentLotDto;
  onLotUpdated?: () => void;
}

const SupplierLotCertTestsSection: React.FC<SupplierLotCertTestsSectionProps> = ({ lot, onLotUpdated }) => {
  const [certTest, setCertTest] = useState<ReagentSupplierLotCertTestDto | null>(null);
  const [certReferenceTests, setCertReferenceTests] = useState<TestDto[]>([]);
  const [loading, setLoading] = useState(false);
  const [showDialog, setShowDialog] = useState(false);
  const [showDeleteConfirmation, setShowDeleteConfirmation] = useState(false);

  const fetchCertTest = async () => {
    setLoading(true);
    try {
      const [data, tests] = await Promise.all([
        reagentsService.getSupplierLotCertTest(lot.controlCodeId),
        testsService.getCertifiedReferenceTests()
      ]);
      setCertTest(data);
      setCertReferenceTests(tests);
    } catch (err) {
      console.error('Failed to fetch supplier lot certification test or tests', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    if (lot.isCertifiedReference) {
      fetchCertTest();
    }
  }, [lot.controlCodeId, lot.isCertifiedReference]);

  if (!lot.isCertifiedReference) {
    return null;
  }

  const handleAdd = () => {
    setShowDialog(true);
  };

  const handleEdit = () => {
    setShowDialog(true);
  };

  const handleDeleteClick = () => {
    setShowDeleteConfirmation(true);
  };

  const handleDeleteConfirm = async () => {
    try {
      await reagentsService.deleteSupplierLotCertTest(lot.controlCodeId);
      setShowDeleteConfirmation(false);
      fetchCertTest();
      if (onLotUpdated) onLotUpdated();
    } catch (err) {
      console.error('Failed to delete cert test', err);
      alert('Failed to delete cert test');
    }
  };

  const handleDialogClose = (saved: boolean) => {
    setShowDialog(false);
    if (saved) {
      fetchCertTest();
      if (onLotUpdated) onLotUpdated();
    }
  };

  const displayName = certTest ? (certTest.unitName ? `${certTest.testName} [${certTest.unitName}]` : certTest.testName) : '';

  const formatValue = (val: any) => {
    if (val === null || val === undefined || val === '') return '-';
    if (!certTest) return val.toString();
    const testDef = certReferenceTests.find(t => t.id === certTest.testId);
    if (!testDef) return val.toString();

    if (testDef.typeId === 3) {
      return val === 1 || val === true || val.toString().toLowerCase() === 'true' ? 'Yes' : 'No';
    }
    if (testDef.typeId === 4 && testDef.enums) {
      const entry = testDef.enums.find(e => e.value.toString() === val.toString());
      return entry ? entry.name : val.toString();
    }
    return val.toString();
  };

  return (
    <div className={styles.sectionContainer}>
      <div className={styles.sectionHeader}>
        <h3>Certified Reference Material (CRM) Test Value</h3>
        {!lot.isReadonly && !certTest && (
          <button onClick={handleAdd} className="action-button primary">
            Add Test Value
          </button>
        )}
      </div>

      {loading ? (
        <p>Loading certification test...</p>
      ) : !certTest ? (
        <p className={styles.emptyText}>No certification test value added yet.</p>
      ) : (
        <div>
          <DetailContainer>
            <DetailColumn>
              <DetailItem label="Test" value={displayName} />
              <DetailItem label="Value" value={formatValue(certTest.value)} />
              <DetailItem label="Uncertainty" value={certTest.uncertaintyValue?.toString() ?? '-'} />
              <DetailItem label="Coverage Factor (k)" value={certTest.coverageFactorK?.toString() ?? '-'} />
              <DetailItem label="Traceability Statement" value={certTest.traceabilityStatement || '-'} />
            </DetailColumn>
          </DetailContainer>

          {!lot.isReadonly && (
            <div style={{ marginTop: '1rem', display: 'flex', gap: '1rem' }}>
              <button onClick={handleEdit} className="action-button edit-button">
                Edit
              </button>
              <button onClick={handleDeleteClick} className="action-button delete-button">
                Delete
              </button>
            </div>
          )}
        </div>
      )}

      {showDialog && (
        <SupplierLotCertTestDialog
          controlCodeId={lot.controlCodeId}
          materialId={lot.materialId}
          existingTest={certTest}
          onClose={handleDialogClose}
        />
      )}

      <ConfirmationDialog
        open={showDeleteConfirmation}
        title="Delete CRM Test Value"
        message="Are you sure you want to delete this certification test value?"
        onConfirm={handleDeleteConfirm}
        onCancel={() => {
          setShowDeleteConfirmation(false);
        }}
      />
    </div>
  );
};

export default SupplierLotCertTestsSection;
