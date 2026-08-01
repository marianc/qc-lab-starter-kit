import React, { useState, useEffect } from 'react';
import { 
  DetailView, 
  DetailViewHeader, 
  DetailViewContent, 
  DetailContainer, 
  DetailColumn, 
  DetailItem 
} from '../common/ui';
import FormGroupDialog from './FormGroupDialog';
import FormDetailView from './forms/FormDetailView';
import styles from './FormGroupDetailView.module.css';
import type { TestDto } from '@/types/test';
import type { FormGroupDto, FormSummaryDto } from '@/types/formGroup';
import formGroupsService from '@/services/formGroupsService';

interface FormGroupDetailViewProps {
  formGroupId: number;
  onClose: (savedId?: number | null) => void;
  breadcrumbs?: string[];
  allTests: TestDto[];
}

const FormGroupDetailView: React.FC<FormGroupDetailViewProps> = ({ 
  formGroupId, 
  onClose, 
  breadcrumbs = [],
  allTests
}) => {
  const [formGroup, setFormGroup] = useState<FormGroupDto | null>(null);
  const [forms, setForms] = useState<FormSummaryDto[]>([]);
  const [selectedFormId, setSelectedFormId] = useState<number | null>(null);
  const [isFormDetailOpen, setIsFormDetailOpen] = useState(false);
  const [showEditDialog, setShowEditDialog] = useState(false);

  const loadData = async () => {
    try {
      const group = await formGroupsService.getFormGroup(formGroupId);
      setFormGroup(group);
      const groupForms = await formGroupsService.getFormsByGroup(formGroupId);
      setForms(groupForms);
    } catch (err) {
      console.error('Failed to load form group details', err);
    }
  };

  useEffect(() => {
    loadData();
  }, [formGroupId]);

  const getStatus = (form: FormSummaryDto) => {
    if (form.isCancelled) return "Cancelled";
    if (form.isValidated) return "Validated";
    if (form.isSubmitted) return "Submitted";
    return "Draft";
  };

  const handleEditForm = (formId: number) => {
    setSelectedFormId(formId);
    setIsFormDetailOpen(true);
  };

  const handleFormDetailClose = async () => {
    setIsFormDetailOpen(false);
    setSelectedFormId(null);
    await loadData();
  };

  const handleEditSave = async (updatedGroup: FormGroupDto) => {
    try {
      await formGroupsService.updateFormGroup(updatedGroup.id, {
        name: updatedGroup.name,
        description: updatedGroup.description,
        nrOrd: updatedGroup.nrOrd
      });
      setShowEditDialog(false);
      await loadData();
    } catch (err) {
      console.error('Failed to update form group', err);
    }
  };

  if (!formGroup) return null;

  return (
    <DetailView>
      <DetailViewHeader 
        title={`Form Group ${formGroup.id}`} 
        onBack={() => onClose(formGroupId)} 
        breadcrumbs={breadcrumbs} 
      />
      <DetailViewContent>
        <div className="page-container">
          <DetailContainer>
            <DetailColumn>
              <DetailItem label="Name" value={formGroup.name} />
              <DetailItem label="Description" value={formGroup.description || "-"} />
              <DetailItem label="Order" value={formGroup.nrOrd} />
              <DetailItem label="Is Validated" value={formGroup.isFormValidated ? "Yes" : "No"} />
            </DetailColumn>
          </DetailContainer>

          {!formGroup.isFormValidated && (
            <div className={styles.actionButtons}>
              <button onClick={() => setShowEditDialog(true)} className="action-button edit-button">Edit</button>
            </div>
          )}

          <div className={styles.relatedForms}>
            <h3 className="section-title">Forms in this Group</h3>
            <table className="data-table">
              <thead>
                <tr>
                  <th>Version</th>
                  <th>Status</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {forms.map((formItem) => (
                  <tr key={formItem.id}>
                    <td>{formItem.version}</td>
                    <td>{getStatus(formItem)}</td>
                    <td>
                      <button 
                        onClick={() => handleEditForm(formItem.id)} 
                        className={`action-button ${formItem.isValidated && !formItem.isCancelled ? 'secondary' : 'edit-button'} small-button`}
                      >
                        {formItem.isValidated && !formItem.isCancelled ? "Details" : "Edit"}
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>

        {isFormDetailOpen && selectedFormId !== null && (
          <FormDetailView 
            formId={selectedFormId}
            onClose={handleFormDetailClose}
            breadcrumbs={[...breadcrumbs, `Form Group ${formGroup.id}`]}
            allTests={allTests}
          />
        )}

        {showEditDialog && (
          <FormGroupDialog 
            open={true}
            formGroupData={formGroup}
            onSave={handleEditSave}
            onClose={() => setShowEditDialog(false)} 
          />
        )}
      </DetailViewContent>
    </DetailView>
  );
};

export default FormGroupDetailView;
