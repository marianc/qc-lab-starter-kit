import React, { useEffect, useState } from 'react';
import { useAuthStore } from '@/store/authStore';
import { 
  DetailView, 
  DetailViewHeader, 
  DetailViewContent, 
  DetailContainer, 
  DetailColumn, 
  DetailItem 
} from '@/components/common/ui';
import MeasurementEditDialog from './MeasurementEditDialog';
import ConfirmationDialog from '@/components/common/ConfirmationDialog';
import SelectDialog from '@/components/common/SelectDialog';
import SelectSopVersionsDialog, { type SopVersionSelectItem } from './SelectSopVersionsDialog';
import styles from './TestingFormA.module.css';
import type { TestDto, TestEnumDto, TestEquipmentDto } from '@/types/test';
import type { MeasurementSopVersionDto } from '@/types/sop';
import type { EquipmentDto } from '@/types/equipment';
import type { FormDto } from '@/types/form';
import type { ReceptionDetailDto } from '@/types/reception';
import type { MeasurementParamDetailDto } from '@/types/measurement';
import measurementsService from '@/services/measurementsService';
import equipmentsService from '@/services/equipmentsService';
import { formatDate } from '@/lib/utils';

interface Props {
  measurementId: number;
  formId: number; // usually 1
  receptionId: number;
  onClose: () => void;
  breadcrumbs: string[];
  allTests: TestDto[];
  allForms: FormDto[];
  reception: ReceptionDetailDto;
}

const TestingFormA: React.FC<Props> = ({ 
  measurementId, 
  formId, 
  receptionId,
  onClose, 
  breadcrumbs, 
  allTests, 
  allForms,
  reception
}) => {
  const { user: currentUser } = useAuthStore();
  const [measurement, setMeasurement] = useState<MeasurementParamDetailDto | null>(null);
  const [formData, setFormData] = useState<Record<string, any>>({});
  const [enumParamAc, setEnumParamAc] = useState<TestEnumDto[]>([]);
  const [associatedEquipments, setAssociatedEquipments] = useState<TestEquipmentDto[]>([]);
  const [associatedSopVersions, setAssociatedSopVersions] = useState<MeasurementSopVersionDto[]>([]);
  const [allEquipments, setAllEquipments] = useState<EquipmentDto[]>([]);
  const [showDeleteConfirmation, setShowDeleteConfirmation] = useState(false);
  const [showCommentDialog, setShowCommentDialog] = useState(false);
  const [showEquipmentDialog, setShowEquipmentDialog] = useState(false);
  const [showSopVersionsDialog, setShowSopVersionsDialog] = useState(false);
  const [applicableSopVersions, setApplicableSopVersions] = useState<SopVersionSelectItem[]>([]);
  const [formName, setFormName] = useState('Testing Form A');

  useEffect(() => {
    loadInitialData();
    equipmentsService.getAllEquipments().then(setAllEquipments);
  }, [measurementId, formId]);

  const loadInitialData = async () => {
    const f = allForms.find(form => form.id === formId);
    if (f) {
      setFormName(f.name);
    }

    // Retrieve enums for test ID 8
    const test8 = allTests.find(t => t.id === 8);
    if (test8?.enums) {
      setEnumParamAc(test8.enums);
    }

    if (measurementId === 0) {
      setMeasurement({
        id: 0,
        receptionId: receptionId,
        formId: formId,
        isReported: false,
        useDefaultEquipment: true,
        isReadonly: false,
        userUpdateId: currentUser?.id || 0,
        userUpdateTag: currentUser?.name || '',
        userReportedTag: null,
        dateUpdate: new Date().toISOString(),
        comments: null,
        measurementData: {},
        calculatedResults: {},
        conditionPass: {}
      });
      setFormData({
        param_aa: null,
        param_ab: null,
        param_ac: null,
        param_ad: null,
        param_ae: null,
        param_af: null
      });
      setAssociatedEquipments([]);
      setAssociatedSopVersions([]);
      } else {
      try {
        const data = await measurementsService.getMeasurementParam(measurementId);
        setMeasurement(data);
        setFormData({
          ...data.measurementData,
          ...data.calculatedResults
        });

        const equipments = await measurementsService.getMeasurementEquipments(measurementId);
        setAssociatedEquipments(equipments);

        const sops = await measurementsService.getMeasurementSopVersions(measurementId);
        setAssociatedSopVersions(sops);

        const applicableSops = await measurementsService.getMeasurementApplicableSopVersions(measurementId);
        const selectableItems: SopVersionSelectItem[] = applicableSops.map((sop: MeasurementSopVersionDto) => ({
          id: sop.id,
          sopId: sop.sopId,
          name: `${sop.docCode} (v${sop.versionNumber}) - ${sop.title}`
        }));
        setApplicableSopVersions(selectableItems);
      } catch (err) {
        console.error('Failed to fetch measurement param:', err);
      }
      }
      };

      const handleEquipmentSelectionSave = async (selectedIds: number[]) => {
      try {
      if (measurement && measurement.id > 0) {
      await measurementsService.updateMeasurementEquipments(measurement.id, { equipmentIds: selectedIds });
      const equipments = await measurementsService.getMeasurementEquipments(measurement.id);
      setAssociatedEquipments(equipments);
      }
      setShowEquipmentDialog(false);
      } catch (err) {
      console.error('Failed to update measurement equipments', err);
      }
      };

      const handleSopVersionsSelectionSave = async (selectedIds: number[]) => {
      try {
      if (measurement && measurement.id > 0) {
      await measurementsService.updateMeasurementSopVersions(measurement.id, { sopVersionIds: selectedIds });
      const sops = await measurementsService.getMeasurementSopVersions(measurement.id);
      setAssociatedSopVersions(sops);
      }
      setShowSopVersionsDialog(false);
      } catch (err) {
      console.error('Failed to update measurement SOP versions', err);
      }
      };

  const handleValChange = (key: string, val: any) => {
    setFormData(prev => ({ ...prev, [key]: val }));
  };

  const handleSaveMeasurement = (comment: string, useDefaultEquipment: boolean) => {
    if (measurement) {
      setMeasurement({ ...measurement, comments: comment, useDefaultEquipment: useDefaultEquipment });
    }
    setShowCommentDialog(false);
  };

  const saveChanges = async () => {
    if (!measurement || !currentUser) return;

    try {
      let finalId = measurement.id;
      if (finalId === 0) {
        const res = await measurementsService.createMeasurement({
          receptionId: measurement.receptionId,
          formId: measurement.formId,
            comments: measurement.comments || null,
          isReported: measurement.isReported,
          userUpdateId: currentUser.id
        });
        finalId = res.id;
      }

      const dataToSave: Record<string, any> = {};
      const form = allForms.find(f => f.id === formId);
      if (form) {
        const nonCalculatedParams = form.formParams
          .filter(p => !p.isCalculated)
          .map(p => {
            const test = allTests.find(t => t.id === p.testId);
            return { code: test?.code, isArray: test?.isArray ?? false };
          })
          .filter(p => !!p.code);

        nonCalculatedParams.forEach(p => {
          if (formData[p.code!] !== undefined) {
            dataToSave[p.code!] = cleanNumericData(formData[p.code!], p.isArray);
          } else if (p.isArray) {
            dataToSave[p.code!] = [];
          }
        });
      } else {
        Object.keys(formData).forEach(key => {
          dataToSave[key] = cleanNumericData(formData[key], false);
        });
      }

      await measurementsService.updateMeasurementParam(finalId, {
        comments: measurement.comments || null,
        useDefaultEquipment: measurement.useDefaultEquipment,
        isReported: measurement.isReported,
        userUpdateId: currentUser.id,
        measurementData: dataToSave
      });
      onClose();
    } catch (err) {
      console.error('Failed to save changes:', err);
    }
  };

  const cleanNumericData = (val: any, isArray: boolean) => {
    if (isArray) {
      if (Array.isArray(val)) {
        return val.map(item => toDouble(item));
      }
      return val !== null && val !== undefined ? [toDouble(val)] : [];
    }
    return toDouble(val);
  };

  const toDouble = (val: any) => {
    if (val === null || val === undefined || val === '') return null;
    const num = parseFloat(val);
    return isNaN(num) ? val : num;
  };

  const handleDeleteConfirm = async () => {
    if (!measurement) return;
    try {
      await measurementsService.deleteMeasurement(measurement.id);
      onClose();
    } catch (err) {
      console.error('Failed to delete measurement:', err);
    }
  };

  const getBooleanDisplay = (value: any) => {
    if (value === null || value === undefined || value === '') return "-";
    const s = value.toString();
    if (s === "1" || s.toLowerCase() === "true") return "Yes";
    if (s === "0" || s.toLowerCase() === "false") return "No";
    return "-";
  };

  const getEnumName = (value: any) => {
    if (value === null || value === undefined) return "";
    const item = enumParamAc.find(i => i.value.toString() === value.toString());
    return item ? item.name : value.toString();
  };

  if (!measurement) return <div>Loading...</div>;

  return (
    <DetailView>
      <DetailViewHeader title={`Testing Form: ${formName} (zzz)`} onBack={onClose} breadcrumbs={breadcrumbs} />
      <DetailViewContent>
        <div className={styles.testingFormA}>
          <DetailContainer>
            <DetailColumn>
              <DetailItem label="Measurement ID" value={measurement.id.toString()} />
              <DetailItem label="Comments" value={measurement.comments || "-"} />
              <DetailItem label="Use Default Equipment" value={measurement.useDefaultEquipment ? "Yes" : "No"} />
              {!measurement.isReadonly && (
                <div className={styles.commentActions}>
                  <button onClick={() => setShowCommentDialog(true)} className="action-button primary">Edit</button>
                </div>
              )}
            </DetailColumn>
            <DetailColumn>
              {measurement.userUpdateTag && (
                <DetailItem label="Last Updated By" value={measurement.userUpdateTag} />
              )}
              <DetailItem label="Last Updated Date" value={formatDate(measurement.dateUpdate || '')} />
              <DetailItem label="Is Reported" value={measurement.isReported ? "Yes" : "No"} />
              {measurement.isReported && measurement.userReportedTag && (
                <DetailItem label="User Reported" value={measurement.userReportedTag} />
              )}
            </DetailColumn>
          </DetailContainer>

          <h2>Form A Data</h2>

          <div className="form-group">
            <label htmlFor="param_aa">Parameter AA:</label>
            {measurement.isReadonly ? (
              <p>{formData.param_aa}</p>
            ) : (
              <input 
                type="number" 
                id="param_aa" 
                value={formData.param_aa ?? ''} 
                onChange={e => handleValChange('param_aa', e.target.value === '' ? null : parseFloat(e.target.value))} 
                className="form-control" 
              />
            )}
          </div>

          <div className="form-group">
            <label htmlFor="param_ab">Parameter AB:</label>
            {measurement.isReadonly ? (
              <p>{formData.param_ab}</p>
            ) : (
              <input 
                type="number" 
                id="param_ab" 
                value={formData.param_ab ?? ''} 
                onChange={e => handleValChange('param_ab', e.target.value === '' ? null : parseFloat(e.target.value))} 
                className="form-control" 
              />
            )}
          </div>

          <div className="form-group">
            <label htmlFor="param_ac">Parameter AC:</label>
            {measurement.isReadonly ? (
              <p>{getEnumName(formData.param_ac)}</p>
            ) : (
              <select 
                id="param_ac" 
                value={formData.param_ac ?? ''} 
                onChange={e => handleValChange('param_ac', e.target.value)} 
                className="form-control"
              >
                <option value="">-- Select --</option>
                {enumParamAc.map(item => (
                  <option key={item.value} value={item.value}>{item.name}</option>
                ))}
              </select>
            )}
          </div>

          <div className="form-group">
            <label htmlFor="param_ad">Parameter AD:</label>
            {measurement.isReadonly ? (
              <p>{formData.param_ad}</p>
            ) : (
              <input 
                type="number" 
                id="param_ad" 
                value={formData.param_ad ?? ''} 
                onChange={e => handleValChange('param_ad', e.target.value === '' ? null : parseFloat(e.target.value))} 
                className="form-control" 
              />
            )}
          </div>

          <div className="form-group">
            <label htmlFor="param_ae">Parameter AE:</label>
            {measurement.isReadonly ? (
              <p>{getBooleanDisplay(formData.param_ae)}</p>
            ) : (
              <select 
                id="param_ae" 
                value={formData.param_ae ?? ''} 
                onChange={e => handleValChange('param_ae', e.target.value)} 
                className="form-control"
              >
                <option value="">-- No Selection --</option>
                <option value="1">Yes</option>
                <option value="0">No</option>
              </select>
            )}
          </div>

          <div className="form-group">
            <label htmlFor="param_af">Parameter AF:</label>
            {measurement.isReadonly ? (
              <p>{formData.param_af}</p>
            ) : (
              <input 
                type="number" 
                id="param_af" 
                step="any" 
                value={formData.param_af ?? ''} 
                onChange={e => handleValChange('param_af', e.target.value === '' ? null : parseFloat(e.target.value))} 
                className="form-control" 
              />
            )}
          </div>

          <div className={styles.formActionsBar}>
            {!measurement.isReadonly && (
              <>
                <button onClick={saveChanges} className="action-button primary">Save Changes</button>
                <button onClick={onClose} className="action-button secondary">Cancel</button>
              </>
            )}
            {!measurement.isReported && !measurement.isReadonly && measurement.id > 0 && (
              <button onClick={() => setShowDeleteConfirmation(true)} className={`action-button delete-button ${styles.buttonRed}`}>Delete</button>
            )}
          </div>

          <h3 className="section-title">Associated Equipments</h3>
          {associatedEquipments.length > 0 ? (
            <ul className="item-list">
              {associatedEquipments.map(eq => (
                <li key={eq.id}>{eq.equipmentCode} - {eq.name} {eq.serialNumber ? `(${eq.serialNumber})` : ''}</li>
              ))}
            </ul>
          ) : (
            <p>No associated equipments</p>
          )}

          {!measurement.isReadonly && measurement.id > 0 && (
            <div className="manageTestsContainer" style={{ marginTop: '1rem' }}>
              <button type="button" onClick={() => setShowEquipmentDialog(true)} className="action-button secondary">Manage Equipments</button>
            </div>
          )}

          <h3 className="section-title" style={{ marginTop: '1.5rem' }}>Associated SOP Versions</h3>
          {associatedSopVersions.length > 0 ? (
            <ul className="item-list">
              {associatedSopVersions.map(sop => (
                <li key={sop.id}>
                  {sop.docCode} (v{sop.versionNumber}) - {sop.title} {sop.externalEdmsId ? `[EDMS: ${sop.externalEdmsId}]` : ''}
                </li>
              ))}
            </ul>
          ) : (
            <p>No associated SOP versions</p>
          )}

          {!measurement.isReadonly && measurement.id > 0 && (
            <div className="manageTestsContainer" style={{ marginTop: '1rem' }}>
              <button type="button" onClick={() => setShowSopVersionsDialog(true)} className="action-button secondary">Manage SOP Versions</button>
            </div>
          )}
        </div>

        <ConfirmationDialog 
          open={showDeleteConfirmation}
          title="Delete Measurement"
          message="Are you sure you want to delete this measurement?"
          onConfirm={handleDeleteConfirm}
          onCancel={() => setShowDeleteConfirmation(false)}
        />

        {showCommentDialog && (
          <MeasurementEditDialog 
            open={true}
            title="Edit Measurement Details"
            initialComment={measurement.comments || ""}
            initialUseDefaultEquipment={measurement.useDefaultEquipment}
            onClose={() => setShowCommentDialog(false)}
            onSubmit={handleSaveMeasurement}
          />
        )}

        {showEquipmentDialog && (
          <SelectDialog 
            open={true}
            title="Select Equipments"
            items={allEquipments.map(eq => ({ id: eq.id, name: `${eq.equipmentCode} - ${eq.name}` }))}
            selectedIds={associatedEquipments.map(eq => eq.id)}
            onSave={handleEquipmentSelectionSave}
            onClose={() => setShowEquipmentDialog(false)}
            idPrefix="equipment"
          />
        )}

        {showSopVersionsDialog && (
          <SelectSopVersionsDialog
            open={true}
            title="Select SOP Versions"
            items={applicableSopVersions}
            selectedIds={associatedSopVersions.map(sop => sop.id)}
            onSave={handleSopVersionsSelectionSave}
            onClose={() => setShowSopVersionsDialog(false)}
            idPrefix="sop-version"
          />
        )}
      </DetailViewContent>
    </DetailView>
  );
};

export default TestingFormA;
