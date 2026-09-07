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
import MeasurementTestDialog from './MeasurementTestDialog';
import type { TestDto, TestEquipmentDto } from '@/types/test';
import type { MeasurementSopVersionDto, SopDto } from '@/types/sop';
import type { EquipmentDto } from '@/types/equipment';
import type { FormDto } from '@/types/form';
import type { ReceptionDetailDto } from '@/types/reception';
import type { MeasurementTestDetailDto, MeasurementTestDto } from '@/types/measurement';
import measurementsService from '@/services/measurementsService';
import equipmentsService from '@/services/equipmentsService';
import { formatDate } from '@/lib/utils';

interface Props {
  measurementId: number;
  onClose: () => void;
  breadcrumbs: string[];
  allTests: TestDto[];
  allForms: FormDto[];
  reception: ReceptionDetailDto;
}

const TestResultsDetailView: React.FC<Props> = ({ 
  measurementId, 
  onClose, 
  breadcrumbs, 
  allTests, 
  allForms,
  reception
}) => {
  const { user: currentUser } = useAuthStore();
  const [measurement, setMeasurement] = useState<MeasurementTestDetailDto | null>(null);
  const [applicableTests, setApplicableTests] = useState<{id: number, name: string}[]>([]);
  const [associatedEquipments, setAssociatedEquipments] = useState<TestEquipmentDto[]>([]);
  const [associatedSopVersions, setAssociatedSopVersions] = useState<MeasurementSopVersionDto[]>([]);
  const [allEquipments, setAllEquipments] = useState<EquipmentDto[]>([]);
  const [showDialog, setShowDialog] = useState(false);
  const [showCommentDialog, setShowCommentDialog] = useState(false);
  const [showEquipmentDialog, setShowEquipmentDialog] = useState(false);
  const [showSopVersionsDialog, setShowSopVersionsDialog] = useState(false);
  const [applicableSopVersions, setApplicableSopVersions] = useState<SopVersionSelectItem[]>([]);
  const [showDeleteConfirmation, setShowDeleteConfirmation] = useState(false);
  const [editableTest, setEditableTest] = useState<MeasurementTestDto | undefined>();

  useEffect(() => {
    fetchMeasurement();
    equipmentsService.getAllEquipments().then(setAllEquipments);
  }, [measurementId]);

  const fetchMeasurement = async () => {
    try {
      const data = await measurementsService.getMeasurementTest(measurementId);
      setMeasurement(data);
      
      const appTests = allTests
        .filter(t => reception.applicableTests.includes(t.id))
        .map(t => ({ 
          id: t.id, 
          name: `${t.name} (${t.isArray ? `[${t.typeName}]` : t.typeName})` 
        }));
      setApplicableTests(appTests);

      const equipments = await measurementsService.getMeasurementEquipments(measurementId);
      setAssociatedEquipments(equipments);

      const sops = await measurementsService.getMeasurementSopVersions(measurementId);
      setAssociatedSopVersions(sops);

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

    } catch (err) {
      console.error('Failed to fetch measurement:', err);
    }
  };

  const handleEquipmentSelectionSave = async (selectedIds: number[]) => {
    try {
      await measurementsService.updateMeasurementEquipments(measurementId, { equipmentIds: selectedIds });
      setShowEquipmentDialog(false);
      const equipments = await measurementsService.getMeasurementEquipments(measurementId);
      setAssociatedEquipments(equipments);
    } catch (err) {
      console.error('Failed to update measurement equipments', err);
    }
  };

  const handleSopVersionsSelectionSave = async (selectedIds: number[]) => {
    try {
      await measurementsService.updateMeasurementSopVersions(measurementId, { sopVersionIds: selectedIds });
      setShowSopVersionsDialog(false);
      const sops = await measurementsService.getMeasurementSopVersions(measurementId);
      setAssociatedSopVersions(sops);
    } catch (err) {
      console.error('Failed to update measurement SOP versions', err);
    }
  };

  const getTestName = (testId: number) => {
    const test = allTests.find(t => t.id === testId);
    if (!test) return 'Unknown';
    return `${test.name} (${test.isArray ? `[${test.typeName}]` : test.typeName})`;
  };

  const getTestUnit = (testId: number) => {
    const test = allTests.find(t => t.id === testId);
    return test?.unitName || '';
  };

  const getFormattedValues = (test: MeasurementTestDto) => {
    const details = allTests.find(t => t.id === test.testId);
    let values: any[] = Array.isArray(test.value) ? test.value : [test.value];

    if (!details) return values.map(v => v?.toString() || '-');

    return values.map(v => {
      if (v === null || v === undefined || v === '') return '-';
      if (details.typeId === 3) return v === 1 || v === true || v.toString().toLowerCase() === 'true' ? 'Yes' : 'No';
      if (details.typeId === 4 && details.enums) {
        const entry = details.enums.find(e => e.value.toString() === v.toString());
        return entry ? entry.name : v.toString();
      }
      return v.toString();
    });
  };

  const openAddDialog = () => {
    setEditableTest({ testId: 0, value: 0, note: null });
    setShowDialog(true);
  };

  const openEditDialog = (test: MeasurementTestDto) => {
    setEditableTest({ ...test });
    setShowDialog(true);
  };

  const handleSaveTest = async (savedTest: MeasurementTestDto) => {
    if (!measurement || !currentUser) return;
    
    try {
      const tests = [...(measurement.tests || [])];
      const existingIdx = tests.findIndex(t => t.testId === savedTest.testId);
      if (existingIdx > -1) {
        tests[existingIdx] = savedTest;
      } else {
        tests.push(savedTest);
      }

      await measurementsService.updateMeasurementTest(measurement.id, {
        comments: measurement.comments || null,
        useDefaultEquipment: measurement.useDefaultEquipment,
        isReported: measurement.isReported,
        userUpdateId: currentUser.id,
        tests
      });

      setShowDialog(false);
      fetchMeasurement();
    } catch (err) {
      console.error('Failed to save test:', err);
    }
  };

  const deleteTest = async (testToDelete: MeasurementTestDto) => {
    if (!measurement || !currentUser) return;
    if (measurement.tests?.length === 1) {
      setShowDeleteConfirmation(true);
      return;
    }

    try {
      const newTests = measurement.tests?.filter(t => t.testId !== testToDelete.testId);
      await measurementsService.updateMeasurementTest(measurement.id, {
        comments: measurement.comments || null,
        useDefaultEquipment: measurement.useDefaultEquipment,
        isReported: measurement.isReported,
        userUpdateId: currentUser.id,
        tests: newTests
      });
      fetchMeasurement();
    } catch (err) {
      console.error('Failed to delete test:', err);
    }
  };

  const handleSaveMeasurement = async (comment: string, useDefaultEquipment: boolean) => {
    if (!measurement || !currentUser) return;
    try {
      await measurementsService.updateMeasurementTest(measurement.id, {
        comments: comment,
        useDefaultEquipment: useDefaultEquipment,
        isReported: measurement.isReported,
        userUpdateId: currentUser.id,
        tests: measurement.tests
      });
      setShowCommentDialog(false);
      fetchMeasurement();
    } catch (err) {
      console.error('Failed to save measurement details:', err);
    }
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

  if (!measurement) return <div>Loading measurement details...</div>;

  const availableTestsForDialog = applicableTests.filter(t => 
    t.id === editableTest?.testId || !measurement.tests?.some(mt => mt.testId === t.id)
  );

  return (
    <DetailView>
      <DetailViewHeader title="Test Results" onBack={onClose} breadcrumbs={breadcrumbs} />
      <DetailViewContent>
        <div className="test-results-form">
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

          <h2 className="section-title">Tests</h2>
          {!measurement.isReadonly && (
            <button onClick={openAddDialog} className="action-button primary add-test-button">Add Test</button>
          )}
          <table className="data-table">
            <thead>
              <tr>
                <th>Test</th>
                <th>Unit</th>
                <th>Value</th>
                <th>Note</th>
                {!measurement.isReadonly && <th>Actions</th>}
              </tr>
            </thead>
            <tbody>
              {measurement.tests?.map((test, idx) => (
                <tr key={idx}>
                  <td>{getTestName(test.testId)}</td>
                  <td>{getTestUnit(test.testId)}</td>
                  <td>
                    {getFormattedValues(test).map((val, vidx) => (
                      <div key={vidx}>{val}</div>
                    ))}
                  </td>
                  <td>{test.note}</td>
                  {!measurement.isReadonly && (
                    <td>
                      <button onClick={() => openEditDialog(test)} className="action-button edit-button small-button">Edit</button>
                      <button onClick={() => deleteTest(test)} className="action-button delete-button small-button">Delete</button>
                    </td>
                  )}
                </tr>
              ))}
            </tbody>
          </table>

          <div className="action-buttons">
            {!measurement.isReported && !measurement.isReadonly && (
              <button onClick={() => setShowDeleteConfirmation(true)} className="action-button delete-button">Delete Measurement</button>
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

          {!measurement.isReadonly && (
            <div className="manageTestsContainer" style={{ marginTop: '1rem' }}>
              <button onClick={() => setShowEquipmentDialog(true)} className="action-button secondary">Manage Equipments</button>
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

          {!measurement.isReadonly && (
            <div className="manageTestsContainer" style={{ marginTop: '1rem' }}>
              <button onClick={() => setShowSopVersionsDialog(true)} className="action-button secondary">Manage SOP Versions</button>
            </div>
          )}
        </div>

        {showDialog && (
          <MeasurementTestDialog 
            open={true}
            test={editableTest}
            availableTests={availableTestsForDialog}
            allTests={allTests}
            onSave={handleSaveTest}
            onClose={() => setShowDialog(false)}
            isEditMode={editableTest?.testId !== 0}
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

        <ConfirmationDialog 
          open={showDeleteConfirmation}
          title="Delete Measurement"
          message="Are you sure you want to delete this measurement and all its tests?"
          onConfirm={handleDeleteConfirm}
          onCancel={() => setShowDeleteConfirmation(false)}
        />
      </DetailViewContent>
    </DetailView>
  );
};

export default TestResultsDetailView;
