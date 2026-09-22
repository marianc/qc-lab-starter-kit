import React, { useEffect, useState, useMemo } from 'react';
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
import ArrayItemDialog from '@/components/common/ArrayItemDialog';
import SelectDialog from '@/components/common/SelectDialog';
import SelectSopVersionsDialog, { type SopVersionSelectItem } from './SelectSopVersionsDialog';
import SelectReagentLotsDialog from './SelectReagentLotsDialog';
import type { TestDto, TestEnumDto, TestEquipmentDto } from '@/types/test';
import type { MeasurementSopVersionDto, SopDto } from '@/types/sop';
import type { EquipmentDto } from '@/types/equipment';
import type { FormDto, FormParamDto } from '@/types/form';
import type { ReceptionDetailDto } from '@/types/reception';
import type { MeasurementParamDetailDto, MeasurementReagentLotDto, MeasurementApplicableReagentLotDto } from '@/types/measurement';
import measurementsService from '@/services/measurementsService';
import equipmentsService from '@/services/equipmentsService';
import { formatDate } from '@/lib/utils';
import styles from './TestFormDetailView.module.css';

interface Props {
  measurementId: number;
  formId: number;
  receptionId: number;
  onClose: () => void;
  breadcrumbs: string[];
  allTests: TestDto[];
  allForms: FormDto[];
  reception: ReceptionDetailDto;
}

const TestFormDetailView: React.FC<Props> = ({ 
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
  const [formParams, setFormParams] = useState<FormParamDto[]>([]);
  const [formName, setFormName] = useState('');
  const [allFormParamEnums, setAllFormParamEnums] = useState<TestEnumDto[]>([]);
  const [associatedEquipments, setAssociatedEquipments] = useState<TestEquipmentDto[]>([]);
  const [associatedSopVersions, setAssociatedSopVersions] = useState<MeasurementSopVersionDto[]>([]);
  const [associatedReagentLots, setAssociatedReagentLots] = useState<MeasurementReagentLotDto[]>([]);
  const [allEquipments, setAllEquipments] = useState<EquipmentDto[]>([]);
  
  const [showCommentDialog, setShowCommentDialog] = useState(false);
  const [showDeleteConfirmation, setShowDeleteConfirmation] = useState(false);
  const [showArrayItemDialog, setShowArrayItemDialog] = useState(false);
  const [showEquipmentDialog, setShowEquipmentDialog] = useState(false);
  const [showSopVersionsDialog, setShowSopVersionsDialog] = useState(false);
  const [showReagentLotsDialog, setShowReagentLotsDialog] = useState(false);
  const [applicableSopVersions, setApplicableSopVersions] = useState<SopVersionSelectItem[]>([]);
  const [applicableReagentLots, setApplicableReagentLots] = useState<MeasurementApplicableReagentLotDto[]>([]);
  
  const [groupedParamsForDialog, setGroupedParamsForDialog] = useState<FormParamDto[]>([]);
  const [editingArrayIndex, setEditingArrayIndex] = useState<number>(-1);
  const [initialArrayItemValue, setInitialArrayItemValue] = useState<Record<string, any>>({});

  useEffect(() => {
    loadInitialData();
    equipmentsService.getAllEquipments().then(setAllEquipments);
  }, [measurementId, formId]);

  const loadInitialData = async () => {
    const f = allForms.find(form => form.id === formId);
    if (!f) return;

    setFormName(f.name);
    
    const params: FormParamDto[] = f.formParams.map(fp => {
      const test = allTests.find(t => t.id === fp.testId);
      return {
        formId: f.id,
        testId: fp.testId,
        isCalculated: fp.isCalculated,
        formula: null, // Not needed for saving
        codeRelatedArrays: fp.codeRelatedArrays,
        isRequired: fp.isRequired,
        defaultValue: fp.defaultValue,
        nrOrd: fp.nrOrd,
        nrOrdCalc: 0,
        code: test?.code || 'Unknown',
        name: test?.name || 'Unknown',
        typeId: test?.typeId || 0,
        isArray: test?.isArray || false,
        unitName: test?.unitName || null,
        dependencies: '',
        isFormSubmitted: false,
        hasCondition: false,
        condition: null,
        conditionNote: null,
        evals: []
      };
    })
    .filter(p => !p.isCalculated)
    .sort((a, b) => a.nrOrd - b.nrOrd);

    setFormParams(params);

    const enumParamTestIds = params.filter(p => p.typeId === 4).map(p => p.testId);
    const enums = allTests
      .filter(t => enumParamTestIds.includes(t.id) && t.enums)
      .flatMap(t => t.enums!);
    setAllFormParamEnums(enums);

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
      const initialData: Record<string, any> = {};
      params.forEach(p => {
        if (p.isArray) initialData[p.code] = [];
      });
      setFormData(initialData);
      setAssociatedEquipments([]);
    } else {
      try {
        const data = await measurementsService.getMeasurementParam(measurementId);
        setMeasurement(data);
        const combinedData = { ...data.measurementData, ...data.calculatedResults };
        
        // Ensure all array params have at least an empty array
        params.forEach(p => {
          if (p.isArray && (!combinedData[p.code] || !Array.isArray(combinedData[p.code]))) {
            combinedData[p.code] = [];
          }
        });
        setFormData(combinedData);

        const equipments = await measurementsService.getMeasurementEquipments(measurementId);
        setAssociatedEquipments(equipments);

        const sops = await measurementsService.getMeasurementSopVersions(measurementId);
        setAssociatedSopVersions(sops);

        const reagentLots = await measurementsService.getMeasurementReagentLots(measurementId);
        setAssociatedReagentLots(reagentLots);

        const applicableSops = await measurementsService.getMeasurementApplicableSopVersions(measurementId);
        const selectableItems: SopVersionSelectItem[] = applicableSops.map((sop: MeasurementSopVersionDto) => ({
          id: sop.id,
          sopId: sop.sopId,
          docCode: sop.docCode,
          title: sop.title,
          versionNumber: sop.versionNumber,
          isActive: sop.isActive,
          name: `${sop.docCode} (v${sop.versionNumber}) - ${sop.title}`
        }));
        setApplicableSopVersions(selectableItems);

        const applicableReagents = await measurementsService.getMeasurementApplicableReagentLots(measurementId);
        setApplicableReagentLots(applicableReagents);
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

  const handleReagentLotsSelectionSave = async (selectedIds: number[]) => {
    try {
      if (measurement && measurement.id > 0) {
        await measurementsService.updateMeasurementReagentLots(measurement.id, { controlCodeIds: selectedIds });
        setShowReagentLotsDialog(false);
        const reagentLots = await measurementsService.getMeasurementReagentLots(measurement.id);
        setAssociatedReagentLots(reagentLots);
        const applicableReagents = await measurementsService.getMeasurementApplicableReagentLots(measurement.id);
        setApplicableReagentLots(applicableReagents);
      }
    } catch (err) {
      console.error('Failed to update measurement reagent lots', err);
    }
  };

  const nonArrayParams = useMemo(() => formParams.filter(p => !p.isArray), [formParams]);
  const standaloneArrayParams = useMemo(() => formParams.filter(p => p.isArray && !p.codeRelatedArrays), [formParams]);
  const groupedArrayParams = useMemo(() => {
    const groups: Record<string, FormParamDto[]> = {};
    formParams.filter(p => p.isArray && p.codeRelatedArrays).forEach(p => {
      const key = p.codeRelatedArrays!;
      if (!groups[key]) groups[key] = [];
      groups[key].push(p);
    });
    return groups;
  }, [formParams]);

  const handleFormChange = (code: string, val: any) => {
    setFormData(prev => ({ ...prev, [code]: val }));
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
          isReported: measurement.isReported
        });
        finalId = res.id;
      }

      // Filter out calculated fields - formParams only contains non-calculated ones
      const dataToSave: Record<string, any> = {};
      formParams.forEach(p => {
        if (formData[p.code] !== undefined) {
          dataToSave[p.code] = cleanNumericData(formData[p.code], p.isArray);
        } else if (p.isArray) {
          dataToSave[p.code] = [];
        }
      });

      await measurementsService.updateMeasurementParam(finalId, {
        comments: measurement.comments || null,
        useDefaultEquipment: measurement.useDefaultEquipment,
        isReported: measurement.isReported,
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

  const getDisplayValue = (param: FormParamDto, val: any) => {
    if (val === null || val === undefined || val === '') return '-';
    if (param.typeId === 3) return val === 1 || val === true || val.toString() === '1' ? 'Yes' : 'No';
    if (param.typeId === 4) {
      return allFormParamEnums.find(e => e.testId === param.testId && e.value.toString() === val.toString())?.name || val.toString();
    }
    return val.toString();
  };

  const renderControl = (param: FormParamDto) => {
    const value = formData[param.code] ?? '';
    const onChange = (e: React.ChangeEvent<any>) => {
      let val = e.target.value;
      if (param.typeId === 1 || param.typeId === 2) {
        val = val === '' ? null : parseFloat(val);
      }
      handleFormChange(param.code, val);
    };

    switch (param.typeId) {
      case 1: // Integer
        return <input type="number" step="1" value={value ?? ''} onChange={onChange} className="form-control" />;
      case 2: // Real
        return <input type="number" step="any" value={value ?? ''} onChange={onChange} className="form-control" />;
      case 3: // Boolean
        return (
          <select value={value ?? ''} onChange={onChange} className="form-control">
            <option value="">-- No Selection --</option>
            <option value="1">Yes</option>
            <option value="0">No</option>
          </select>
        );
      case 4: // Enum
        return (
          <select value={value ?? ''} onChange={onChange} className="form-control">
            <option value="">-- Select --</option>
            {allFormParamEnums.filter(e => e.testId === param.testId).map(e => (
              <option key={e.value} value={e.value}>{e.name}</option>
            ))}
          </select>
        );
      default:
        return <input type="text" value={value ?? ''} onChange={onChange} className="form-control" />;
    }
  };

  const openArrayItemDialog = (param: FormParamDto) => {
    setEditingArrayIndex(-1);
    setInitialArrayItemValue({});
    if (param.codeRelatedArrays) {
      setGroupedParamsForDialog(formParams.filter(p => p.isArray && p.codeRelatedArrays === param.codeRelatedArrays));
    } else {
      setGroupedParamsForDialog([param]);
    }
    setShowArrayItemDialog(true);
  };

  const editArrayItem = (param: FormParamDto, idx: number) => {
    setEditingArrayIndex(idx);
    const group = param.codeRelatedArrays 
      ? formParams.filter(p => p.isArray && p.codeRelatedArrays === param.codeRelatedArrays)
      : [param];
    
    setGroupedParamsForDialog(group);
    const vals: Record<string, any> = {};
    group.forEach(p => {
      vals[p.code] = formData[p.code][idx];
    });
    setInitialArrayItemValue(vals);
    setShowArrayItemDialog(true);
  };

  const handleArrayItemSave = (itemValues: Record<string, any>) => {
    const newFormData = { ...formData };
    groupedParamsForDialog.forEach(p => {
      const list = [...(newFormData[p.code] || [])];
      if (editingArrayIndex === -1) {
        list.push(itemValues[p.code]);
      } else {
        list[editingArrayIndex] = itemValues[p.code];
      }
      newFormData[p.code] = list;
    });
    setFormData(newFormData);
    setShowArrayItemDialog(false);
  };

  const deleteArrayItem = (param: FormParamDto, idx: number) => {
    const newFormData = { ...formData };
    const group = param.codeRelatedArrays 
      ? formParams.filter(p => p.isArray && p.codeRelatedArrays === param.codeRelatedArrays)
      : [param];
    
    group.forEach(p => {
      const list = [...(newFormData[p.code] || [])];
      list.splice(idx, 1);
      newFormData[p.code] = list;
    });
    setFormData(newFormData);
  };

  if (!measurement) return <div>Loading measurement details...</div>;

  return (
    <DetailView>
      <DetailViewHeader title={`Testing Form: ${formName}`} onBack={onClose} breadcrumbs={breadcrumbs} />
      <DetailViewContent>
        <div className="testing-form-generic">
          <DetailContainer>
            <DetailColumn>
              <DetailItem label="Measurement ID" value={measurement.id.toString()} />
              <DetailItem label="Comments" value={measurement.comments || "-"} />
              <DetailItem label="Use Default Equipment" value={measurement.useDefaultEquipment ? "Yes" : "No"} />
              {!measurement.isReadonly && (
                <div className="comment-actions">
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

          <h2>Form Data</h2>
          {nonArrayParams.map(param => (
            <div key={param.testId} className="form-group">
              <label htmlFor={param.code}>
                {param.name}{param.unitName ? ` [${param.unitName}]` : ''}:
              </label>
              {measurement.isReadonly ? (
                <p>{getDisplayValue(param, formData[param.code])}</p>
              ) : (
                renderControl(param)
              )}
            </div>
          ))}

          {standaloneArrayParams.map(param => (
            <div key={param.testId} className="form-group">
              <p>Array parameter: {param.name}{param.unitName ? ` [${param.unitName}]` : ''}</p>
              {!measurement.isReadonly && (
                <button type="button" onClick={() => openArrayItemDialog(param)} className="action-button primary small-button">+</button>
              )}
              <table className="data-table">
                <tbody>
                  {(formData[param.code] || []).map((val: any, idx: number) => (
                    <tr key={idx}>
                      <td>{getDisplayValue(param, val)}</td>
                      {!measurement.isReadonly && (
                        <td>
                          <button type="button" onClick={() => editArrayItem(param, idx)} className="action-button edit-button small-button">Edit</button>
                          <button type="button" onClick={() => deleteArrayItem(param, idx)} className="action-button delete-button small-button">Delete</button>
                        </td>
                      )}
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          ))}

          {Object.entries(groupedArrayParams).map(([groupKey, group]) => (
            <div key={groupKey} className="form-group">
              <p>Array parameter group: {groupKey}</p>
              {!measurement.isReadonly && (
                <button type="button" onClick={() => openArrayItemDialog(group[0])} className="action-button primary small-button">+</button>
              )}
              <table className="data-table">
                <thead>
                  <tr>
                    {group.map(p => <th key={p.testId}>{p.name}{p.unitName ? ` [${p.unitName}]` : ''}</th>)}
                    {!measurement.isReadonly && <th>Actions</th>}
                  </tr>
                </thead>
                <tbody>
                  {(formData[group[0].code] || []).map((_: any, idx: number) => (
                    <tr key={idx}>
                      {group.map(p => (
                        <td key={p.testId}>{getDisplayValue(p, formData[p.code][idx])}</td>
                      ))}
                      {!measurement.isReadonly && (
                        <td>
                          <button type="button" onClick={() => editArrayItem(group[0], idx)} className="action-button edit-button small-button">Edit</button>
                          <button type="button" onClick={() => deleteArrayItem(group[0], idx)} className="action-button delete-button small-button">Delete</button>
                        </td>
                      )}
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          ))}

          <div className="form-actions-bar">
            {!measurement.isReadonly && (
              <>
                <button onClick={saveChanges} className="action-button primary">Save Changes</button>
                <button onClick={onClose} className="action-button secondary">Cancel</button>
              </>
            )}
            {!measurement.isReported && !measurement.isReadonly && measurement.id > 0 && (
              <button onClick={() => setShowDeleteConfirmation(true)} className="action-button delete-button">Delete</button>
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
            <div className={`manageTestsContainer ${styles.mt1}`}>
              <button type="button" onClick={() => setShowEquipmentDialog(true)} className="action-button secondary">Manage Equipments</button>
            </div>
          )}

          <h3 className={`section-title ${styles.mt15}`}>Associated SOP Versions</h3>
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
            <div className={`manageTestsContainer ${styles.mt1}`}>
              <button type="button" onClick={() => setShowSopVersionsDialog(true)} className="action-button secondary">Manage SOP Versions</button>
            </div>
          )}

          <h3 className={`section-title ${styles.mt15}`}>Associated Reagent Lots</h3>
          {associatedReagentLots.length > 0 ? (
            <ul className="item-list">
              {associatedReagentLots.map(lot => (
                <li key={lot.controlCodeId}>
                  {lot.materialName} - {lot.controlCode}
                </li>
              ))}
            </ul>
          ) : (
            <p>No associated reagent lots</p>
          )}

          {!measurement.isReadonly && measurement.id > 0 && (
            <div className={`manageTestsContainer ${styles.mt1}`}>
              <button type="button" onClick={() => setShowReagentLotsDialog(true)} className="action-button secondary">Manage Reagent Lots</button>
            </div>
          )}
        </div>

        {showArrayItemDialog && (
          <ArrayItemDialog 
            open={true}
            groupedParams={groupedParamsForDialog}
            initialValues={initialArrayItemValue}
            allFormParamEnums={allFormParamEnums}
            isEditing={editingArrayIndex !== -1}
            onSave={handleArrayItemSave}
            onClose={() => setShowArrayItemDialog(false)}
          />
        )}

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

        {showReagentLotsDialog && (
          <SelectReagentLotsDialog
            open={true}
            title="Manage Reagent Lots"
            items={applicableReagentLots}
            onSave={handleReagentLotsSelectionSave}
            onClose={() => setShowReagentLotsDialog(false)}
            idPrefix="reagent-lot"
          />
        )}

        <ConfirmationDialog 
          open={showDeleteConfirmation}
          title="Delete Measurement"
          message="Are you sure you want to delete this measurement?"
          onConfirm={handleDeleteConfirm}
          onCancel={() => setShowDeleteConfirmation(false)}
        />
      </DetailViewContent>
    </DetailView>
  );
};

export default TestFormDetailView;
