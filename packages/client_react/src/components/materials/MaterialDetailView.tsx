import React, { useState, useEffect } from 'react';
import { 
  DetailView, 
  DetailViewHeader, 
  DetailViewContent, 
  DetailContainer, 
  DetailColumn, 
  DetailItem 
} from '../common/ui';
import { 
  ConfirmationDialog, 
  CommentDialog, 
  SelectDialog 
} from '../common';
import MaterialDialog from './MaterialDialog';
import styles from './MaterialDetailView.module.css';
import type { MaterialDto, MaterialTestDto } from '@/types/material';
import type { TestDto } from '@/types/test';
import type { FormDto } from '@/types/form';
import materialsService from '@/services/materialsService';
import formsService from '@/services/formsService';
import type { SelectableItem } from '@/types/models';
import { formatDate } from '@/lib/utils';

interface MaterialDetailViewProps {
  materialId: number;
  onClose: (savedId?: number | null) => void;
  onMaterialUpdated?: (updatedMaterial: MaterialDto) => void;
  breadcrumbs?: string[];
  allTests: TestDto[];
}

const MaterialDetailView: React.FC<MaterialDetailViewProps> = ({ 
  materialId, 
  onClose, 
  onMaterialUpdated,
  breadcrumbs = [],
  allTests
}) => {
  const [material, setMaterial] = useState<MaterialDto | null>(null);
  const [associatedTests, setAssociatedTests] = useState<MaterialTestDto[]>([]);
  const [allForms, setAllForms] = useState<FormDto[]>([]);
  const [showEditDialog, setShowEditDialog] = useState(false);
  const [showTestDialog, setShowTestDialog] = useState(false);
  const [showApplicableFormsDialog, setShowApplicableFormsDialog] = useState(false);
  const [showConfirmationDialog, setShowConfirmationDialog] = useState(false);
  const [showDeactivateCommentDialog, setShowDeactivateCommentDialog] = useState(false);

  const [pendingFormTestIds, setPendingFormTestIds] = useState<number[]>([]);
  const [missingTestNames, setMissingTestNames] = useState<string[]>([]);

  const fetchMaterialData = async () => {
    try {
      const data = await materialsService.getMaterial(materialId);
      setMaterial(data);
      if (onMaterialUpdated) {
        onMaterialUpdated(data);
      }
      const tests = await materialsService.getMaterialTests(materialId);
      setAssociatedTests(tests);
    } catch (err) {
      console.error('Failed to fetch material data', err);
    }
  };

  const fetchFormsData = async () => {
    try {
      const forms = await formsService.getAllForms();
      setAllForms(forms);
    } catch (err) {
      console.error('Failed to fetch forms', err);
    }
  };

  useEffect(() => {
    fetchMaterialData();
    fetchFormsData();
  }, [materialId]);

  const handleEditDialogClose = (savedId?: number | null) => {
    setShowEditDialog(false);
    if (savedId) {
      fetchMaterialData();
    }
  };

  const handleTestSelectionSave = async (selectedIds: number[]) => {
    try {
      await materialsService.updateMaterialTests(materialId, { testIds: selectedIds });
      setShowTestDialog(false);
      const tests = await materialsService.getMaterialTests(materialId);
      setAssociatedTests(tests);
    } catch (err) {
      console.error('Failed to update tests', err);
    }
  };

  const handleApplicableFormsSave = async (selectedFormIds: number[]) => {
    if (selectedFormIds.length === 0) {
      setShowApplicableFormsDialog(false);
      return;
    }

    try {
      // Gather all test IDs from the selected forms' formParams, filtering out test parameters (isParam === true)
      const formTestIdSet = new Set<number>();
      for (const formId of selectedFormIds) {
        const params = await formsService.getFormParams(formId);
        params.forEach(p => {
          const testObj = allTests.find(t => t.id === p.testId);
          if (testObj && !testObj.isParam) {
            formTestIdSet.add(p.testId);
          }
        });
      }

      const currentTestIds = new Set(associatedTests.map(t => t.id));
      const missingIds = Array.from(formTestIdSet).filter(id => !currentTestIds.has(id));

      if (missingIds.length > 0) {
        const sortedMissingTests = missingIds
          .map(id => allTests.find(t => t.id === id))
          .filter((t): t is TestDto => t !== undefined)
          .sort((a, b) => a.nrOrd - b.nrOrd);

        const names = sortedMissingTests.map(t => t.name);
        setMissingTestNames(names);
        setPendingFormTestIds(Array.from(formTestIdSet));
        setShowApplicableFormsDialog(false);
        setShowConfirmationDialog(true);
      } else {
        // No missing tests, update immediately or merge
        const combinedIds = Array.from(new Set([...currentTestIds, ...formTestIdSet]));
        await materialsService.updateMaterialTests(materialId, { testIds: combinedIds });
        setShowApplicableFormsDialog(false);
        fetchMaterialData();
      }
    } catch (err) {
      console.error('Failed to process applicable forms', err);
    }
  };

  const handleConfirmAddMissingTests = async () => {
    try {
      const currentTestIds = associatedTests.map(t => t.id);
      const combinedIds = Array.from(new Set([...currentTestIds, ...pendingFormTestIds]));
      await materialsService.updateMaterialTests(materialId, { testIds: combinedIds });
      setShowConfirmationDialog(false);
      setPendingFormTestIds([]);
      setMissingTestNames([]);
      fetchMaterialData();
    } catch (err) {
      console.error('Failed to update material tests with applicable forms', err);
    }
  };

  const handleToggleStatusClick = () => {
    if (!material) return;
    if (material.isObsolete) {
      setShowConfirmationDialog(true);
    } else {
      setShowDeactivateCommentDialog(true);
    }
  };

  const handleConfirmActivation = async () => {
    try {
      await materialsService.toggleObsolete(materialId, { isObsolete: false });
      setShowConfirmationDialog(false);
      fetchMaterialData();
    } catch (err) {
      console.error('Failed to activate material', err);
    }
  };

  const handleDeactivateSubmit = async (comment: string) => {
    try {
      await materialsService.toggleObsolete(materialId, { isObsolete: true, comments: comment });
      setShowDeactivateCommentDialog(false);
      fetchMaterialData();
    } catch (err) {
      console.error('Failed to deactivate material', err);
    }
  };

  if (!material) return null;

  const selectableTests: SelectableItem[] = allTests
    .filter(t => !t.isParam)
    .map(t => ({ id: t.id, name: `${t.name} (${t.code})` }));

  const validForms: SelectableItem[] = allForms
    .filter(f => f.isValidated && !f.isCancelled)
    .map(f => ({ id: f.id, name: f.name }));

  return (
    <DetailView>
      <DetailViewHeader 
        title={`Material ${material.id}`} 
        onBack={() => onClose(materialId)} 
        breadcrumbs={breadcrumbs} 
      />
      <DetailViewContent>
        <div className="page-container">
          <DetailContainer>
            <DetailColumn>
              <DetailItem label="Name" value={material.name} />
              <DetailItem label="Code" value={material.code} />
              <DetailItem label="Description" value={material.description || "-"} />
              <DetailItem label="Norm" value={material.normName || "N/A"} />
              <DetailItem label="Is Product" value={material.isProduct ? "Yes" : "No"} />
              <DetailItem label="Is Raw Material" value={material.isRawMaterial ? "Yes" : "No"} />
              <DetailItem label="Date Created" value={formatDate(material.dateCreated)} />
              <DetailItem label="Is Obsolete" value={material.isObsolete ? "Yes" : "No"} />
              <DetailItem label="Date Obsolete" value={formatDate(material.dateObsolete)} />
              {material.isObsolete && material.commentsObsolete && (
                <DetailItem label="Obsolete Comment" value={material.commentsObsolete} />
              )}
            </DetailColumn>
          </DetailContainer>

          <div className={styles.actionButtons}>
            <button onClick={() => setShowEditDialog(true)} className="action-button edit-button">Edit</button>
            <button 
              onClick={handleToggleStatusClick} 
              className={`action-button ${material.isObsolete ? 'secondary' : 'delete-button'}`}
            >
              {material.isObsolete ? 'Activate' : 'Deactivate'}
            </button>
          </div>

          <h3 className="section-title">Associated Tests</h3>
          {associatedTests.length > 0 ? (
            <ul className="item-list">
              {associatedTests.map(test => {
                const fullTest = allTests.find(t => t.id === test.id);
                const displayName = fullTest ? `${test.name} (${fullTest.code})` : test.name;
                return (
                  <li key={test.id}>{displayName}</li>
                );
              })}
            </ul>
          ) : (
            <p>No associated tests</p>
          )}

          <div className={styles.manageTestsContainer}>
            <button onClick={() => setShowTestDialog(true)} className="action-button secondary">Manage Tests</button>
            <button onClick={() => setShowApplicableFormsDialog(true)} className="action-button secondary">Applicable Forms</button>
          </div>
        </div>
      </DetailViewContent>

      {showEditDialog && (
        <MaterialDialog 
          open={true} 
          materialId={materialId} 
          onClose={handleEditDialogClose} 
        />
      )}

      {showTestDialog && (
        <SelectDialog 
          open={true}
          title="Select Tests"
          items={selectableTests}
          selectedIds={associatedTests.map(t => t.id)}
          onSave={handleTestSelectionSave}
          onClose={() => setShowTestDialog(false)}
          idPrefix="test"
        />
      )}

      {showApplicableFormsDialog && (
        <SelectDialog 
          open={true}
          title="Select Applicable Forms"
          items={validForms}
          selectedIds={[]}
          onSave={handleApplicableFormsSave}
          onClose={() => setShowApplicableFormsDialog(false)}
          idPrefix="form"
        />
      )}

      {showConfirmationDialog && missingTestNames.length > 0 ? (
        <ConfirmationDialog 
          open={true}
          title="Add Missing Tests"
          message={
            <div>
              <p>The following tests present in the selected forms are not currently associated with this material and will be added:</p>
              <br />
              <ul style={{ listStyleType: 'disc', paddingLeft: '20px', margin: 0 }}>
                {missingTestNames.map((testName, idx) => (
                  <li key={idx}>{testName}</li>
                ))}
              </ul>
              <br />
              <p>Do you want to proceed?</p>
            </div>
          }
          onConfirm={handleConfirmAddMissingTests}
          onCancel={() => {
            setShowConfirmationDialog(false);
            setPendingFormTestIds([]);
            setMissingTestNames([]);
          }}
        />
      ) : showConfirmationDialog ? (
        <ConfirmationDialog 
          open={true}
          title="Confirm Material Activation"
          message={`Are you sure you want to activate material ${material.name}?`}
          onConfirm={handleConfirmActivation}
          onCancel={() => setShowConfirmationDialog(false)}
        />
      ) : null}

      {showDeactivateCommentDialog && (
        <CommentDialog 
          open={true}
          onSubmit={handleDeactivateSubmit}
          onClose={() => setShowDeactivateCommentDialog(false)}
        />
      )}
    </DetailView>
  );
};

export default MaterialDetailView;
