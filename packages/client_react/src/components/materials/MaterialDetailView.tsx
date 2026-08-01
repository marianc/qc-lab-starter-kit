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
import materialsService from '@/services/materialsService';
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
  const [showEditDialog, setShowEditDialog] = useState(false);
  const [showTestDialog, setShowTestDialog] = useState(false);
  const [showConfirmationDialog, setShowConfirmationDialog] = useState(false);
  const [showDeactivateCommentDialog, setShowDeactivateCommentDialog] = useState(false);

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

  useEffect(() => {
    fetchMaterialData();
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
    .map(t => ({ id: t.id, name: t.name }));

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
              {associatedTests.map(test => (
                <li key={test.id}>{test.name}</li>
              ))}
            </ul>
          ) : (
            <p>No associated tests</p>
          )}

          <div className={styles.manageTestsContainer}>
            <button onClick={() => setShowTestDialog(true)} className="action-button secondary">Manage Tests</button>
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

      {showConfirmationDialog && (
        <ConfirmationDialog 
          open={true}
          title="Confirm Material Activation"
          message={`Are you sure you want to activate material ${material.name}?`}
          onConfirm={handleConfirmActivation}
          onCancel={() => setShowConfirmationDialog(false)}
        />
      )}

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
