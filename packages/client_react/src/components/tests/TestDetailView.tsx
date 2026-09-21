import React, { useState, useEffect } from 'react';
import { 
  DetailView, 
  DetailViewHeader, 
  DetailViewContent, 
  DetailContainer, 
  DetailColumn, 
  DetailItem,
  DragHandle
} from '../common/ui';
import { 
  ConfirmationDialog, 
  CommentDialog,
  SelectDialog
} from '../common';
import TestDialog from './TestDialog';
import TestEnumDialog from './TestEnumDialog';
import styles from './TestDetailView.module.css';
import type { CreateTestEnumDto, ReorderTestEnumDto, TestDto, TestEnumDto, UpdateTestDto, UpdateTestEnumDto, TestEquipmentDto, TestReagentDto } from '@/types/test';
import type { NormDto } from '@/types/norm';
import type { SopDto } from '@/types/sop';
import type { EquipmentDto } from '@/types/equipment';
import type { MaterialDto } from '@/types/material';
import type { SelectableItem } from '@/types/models';
import testsService from '@/services/testsService';
import normsService from '@/services/normsService';
import sopsService from '@/services/sopsService';
import equipmentsService from '@/services/equipmentsService';
import materialsService from '@/services/materialsService';
import { formatDate } from '@/lib/utils';

interface TestDetailViewProps {
  testId: number;
  onClose: (savedId?: number | null) => void;
  onTestUpdated?: (updatedTest: TestDto) => void;
  breadcrumbs?: string[];
}

const TestDetailView: React.FC<TestDetailViewProps> = ({ 
  testId, 
  onClose, 
  onTestUpdated,
  breadcrumbs = []
}) => {
  const [test, setTest] = useState<TestDto | null>(null);
  const [enums, setEnums] = useState<TestEnumDto[]>([]);
  const [norms, setNorms] = useState<NormDto[]>([]);
  const [sops, setSops] = useState<SopDto[]>([]);
  const [associatedEquipments, setAssociatedEquipments] = useState<TestEquipmentDto[]>([]);
  const [allEquipments, setAllEquipments] = useState<EquipmentDto[]>([]);
  const [associatedReagents, setAssociatedReagents] = useState<TestReagentDto[]>([]);
  const [allMaterials, setAllMaterials] = useState<MaterialDto[]>([]);
  const [showEditDialog, setShowEditDialog] = useState(false);
  const [showEnumDialog, setShowEnumDialog] = useState(false);
  const [showEquipmentDialog, setShowEquipmentDialog] = useState(false);
  const [showReagentDialog, setShowReagentDialog] = useState(false);
  const [showConfirmationDialog, setShowConfirmationDialog] = useState(false);
  const [showDeactivateCommentDialog, setShowDeactivateCommentDialog] = useState(false);
  const [currentEnum, setCurrentEnum] = useState<TestEnumDto | null>(null);
  const [draggedItemIndex, setDraggedItemIndex] = useState<number | null>(null);
  const [isDragHandleActive, setIsDragHandleActive] = useState(false);

  const fetchTestData = async () => {
    try {
      const data = await testsService.getTest(testId);
      setTest(data);
      if (onTestUpdated) {
        onTestUpdated(data);
      }
      if (data.typeId === 4) {
        const enumData = await testsService.getTestEnums(testId);
        setEnums([...enumData].sort((a, b) => a.nrOrd - b.nrOrd));
      }
      if (data.normId) {
        sopsService.getSopsByNorm(data.normId).then(setSops);
      } else {
        setSops([]);
      }
      const equipments = await testsService.getTestEquipments(testId);
      setAssociatedEquipments(equipments);
      const reagents = await testsService.getTestReagents(testId);
      setAssociatedReagents(reagents);
    } catch (err) {
      console.error('Failed to fetch test data', err);
    }
  };

  useEffect(() => {
    fetchTestData();
    normsService.getAllNorms().then(setNorms);
    equipmentsService.getAllEquipments().then(setAllEquipments);
    materialsService.getAllMaterials().then(setAllMaterials);
  }, [testId]);

  const handleEquipmentSelectionSave = async (selectedIds: number[]) => {
    try {
      await testsService.updateTestEquipments(testId, { equipmentIds: selectedIds });
      setShowEquipmentDialog(false);
      const equipments = await testsService.getTestEquipments(testId);
      setAssociatedEquipments(equipments);
    } catch (err) {
      console.error('Failed to update test equipments', err);
    }
  };

  const handleReagentSelectionSave = async (selectedIds: number[]) => {
    try {
      await testsService.updateTestReagents(testId, { materialIds: selectedIds });
      setShowReagentDialog(false);
      const reagents = await testsService.getTestReagents(testId);
      setAssociatedReagents(reagents);
    } catch (err) {
      console.error('Failed to update test reagents', err);
    }
  };

  const handleEditSave = async (updatedTest: TestDto) => {
    try {
      const updateDto: UpdateTestDto = {
        name: updatedTest.name,
        code: updatedTest.code,
        description: updatedTest.description,
        typeId: updatedTest.typeId,
        isArray: updatedTest.isArray,
        isParam: updatedTest.isParam,
        forEnvironmentalControl: updatedTest.forEnvironmentalControl,
        forCertification: updatedTest.forCertification,
        relativeUncertaintyPct: updatedTest.relativeUncertaintyPct,
        defaultCoverageFactorK: updatedTest.defaultCoverageFactorK,
        unitId: updatedTest.unitId,
        normId: updatedTest.normId,
        normRef: updatedTest.normRef,
        sopId: updatedTest.sopId,
        nrOrd: updatedTest.nrOrd,
        isObsolete: updatedTest.isObsolete
      };
      await testsService.updateTest(updatedTest.id, updateDto);
      setShowEditDialog(false);
      fetchTestData();
    } catch (err) {
      console.error('Failed to update test', err);
    }
  };

  const handleSaveEnum = async (enumData: TestEnumDto) => {
    try {
      const existing = enums.find(e => e.value === enumData.value);
      if (existing) {
        await testsService.updateTestEnum(testId, enumData.value, { 
          name: enumData.name, 
          nrOrd: enumData.nrOrd, 
          value: enumData.value 
        } as UpdateTestEnumDto);
      } else {
        await testsService.addTestEnum(testId, { 
          name: enumData.name, 
          nrOrd: enumData.nrOrd, 
          value: enumData.value 
        } as CreateTestEnumDto);
      }
      setShowEnumDialog(false);
      fetchTestData();
    } catch (err) {
      console.error('Failed to save enum', err);
    }
  };

  const handleDeleteEnum = async (enumItem: TestEnumDto) => {
    if (window.confirm(`Are you sure you want to delete enum value ${enumItem.name}?`)) {
      try {
        await testsService.deleteTestEnum(testId, enumItem.value);
        fetchTestData();
      } catch (err) {
        console.error('Failed to delete enum', err);
      }
    }
  };

  const handleToggleStatusClick = () => {
    if (!test) return;
    if (test.isObsolete) {
      setShowConfirmationDialog(true);
    } else {
      setShowDeactivateCommentDialog(true);
    }
  };

  const handleConfirmActivation = async () => {
    try {
      await testsService.toggleObsolete(testId, { isObsolete: false });
      setShowConfirmationDialog(false);
      fetchTestData();
    } catch (err) {
      console.error('Failed to activate test', err);
    }
  };

  const handleDeactivateSubmit = async (comment: string) => {
    try {
      await testsService.toggleObsolete(testId, { isObsolete: true, comments: comment });
      setShowDeactivateCommentDialog(false);
      fetchTestData();
    } catch (err) {
      console.error('Failed to deactivate test', err);
    }
  };

  const handleDragStart = (index: number) => {
    if (!isDragHandleActive) return;
    setDraggedItemIndex(index);
  };

  const handleDragEnter = (index: number) => {
    if (draggedItemIndex === null || draggedItemIndex === index) return;

    const newEnums = [...enums];
    const draggedItem = newEnums[draggedItemIndex];
    newEnums.splice(draggedItemIndex, 1);
    newEnums.splice(index, 0, draggedItem);
    setEnums(newEnums);
    setDraggedItemIndex(index);
  };

  const handleDragEnd = async () => {
    setDraggedItemIndex(null);
    setIsDragHandleActive(false);
    
    const reorderedEnums = enums.map((e, idx) => ({ ...e, nrOrd: idx + 1 }));
    setEnums(reorderedEnums);

    try {
      const reorderData: ReorderTestEnumDto[] = reorderedEnums.map(e => ({ value: e.value, nrOrd: e.nrOrd }));
      await testsService.reorderTestEnums(testId, reorderData);
    } catch (err) {
      console.error('Failed to save enum order', err);
      fetchTestData();
    }
  };

  if (!test) return null;

  return (
    <DetailView>
      <DetailViewHeader 
        title={`Test ${test.id}`} 
        onBack={() => onClose(testId)} 
        breadcrumbs={breadcrumbs} 
      />
      <DetailViewContent>
        <div className="page-container">
          <DetailContainer>
            <DetailColumn>
              <DetailItem label="Name" value={test.name} />
              <DetailItem label="Description" value={test.description || "-"} />
              <DetailItem label="Code" value={test.code} />
              <DetailItem label="Value Type" value={test.typeName} />
              <DetailItem label="Is Array" value={test.isArray ? "Yes" : "No"} />
              <DetailItem label="Is Parameter" value={test.isParam ? "Yes" : "No"} />
              <DetailItem label="For Environmental Control" value={test.forEnvironmentalControl ? "Yes" : "No"} />
              <DetailItem label="For Certification" value={test.forCertification ? "Yes" : "No"} />
              {test.forCertification && (
                <>
                  <DetailItem label="Relative Uncertainty (%)" value={test.relativeUncertaintyPct ?? "-"} />
                  <DetailItem label="Coverage Factor (k)" value={test.defaultCoverageFactorK ?? "-"} />
                </>
              )}
            </DetailColumn>
            <DetailColumn>
              <DetailItem label="Unit" value={test.unitName || "-"} />
              <DetailItem label="Norm" value={norms.find(n => n.id === test.normId)?.name || "-"} />
              <DetailItem label="Norm Ref" value={test.normRef || "-"} />
              <DetailItem label="SOP" value={sops.find(s => s.id === test.sopId) ? `${sops.find(s => s.id === test.sopId)?.docCode} - ${sops.find(s => s.id === test.sopId)?.title}` : "-"} />
              <DetailItem label="Is Form Validated" value={test.isFormValidated ? "Yes" : "No"} />
              <DetailItem label="Order" value={test.nrOrd} />
              <DetailItem label="Date Created" value={formatDate(test.dateCreated)} />
              <DetailItem label="Is Obsolete" value={test.isObsolete ? "Yes" : "No"} />
              {test.isObsolete && (
                <>
                  <DetailItem label="Date Obsolete" value={formatDate(test.dateObsolete)} />
                  {test.commentsObsolete && <DetailItem label="Obsolete Comment" value={test.commentsObsolete} />}
                </>
              )}
            </DetailColumn>
          </DetailContainer>

          <div className={styles.actionButtons}>
            {!test.isObsolete && (
              <button onClick={() => setShowEditDialog(true)} className="action-button edit-button">Edit</button>
            )}
            <button 
              onClick={handleToggleStatusClick} 
              className={`action-button ${test.isObsolete ? 'secondary' : 'delete-button'}`}
            >
              {test.isObsolete ? 'Activate' : 'Deactivate'}
            </button>
          </div>

          {test.typeId === 4 && (
            <div className={styles.enumSection}>
              <h3 className="section-title">Enum Values</h3>
              {!test.isFormValidated && (
                <button 
                  type="button" 
                  onClick={() => {
                    const maxVal = enums.length > 0 ? Math.max(...enums.map(e => e.value)) : 0;
                    setCurrentEnum({ testId, value: maxVal + 1, name: '', nrOrd: enums.length + 1 });
                    setShowEnumDialog(true);
                  }} 
                  className={`action-button primary ${styles.addEnumButton}`}
                >
                  Add New Enum Value
                </button>
              )}
              <table className="data-table">
                <thead>
                  <tr>
                    <th>Value</th>
                    <th>Name</th>
                    <th>Order</th>
                    {!test.isFormValidated && (
                      <>
                        <th>Actions</th>
                        <th className={styles.dragHandleCol}></th>
                      </>
                    )}
                  </tr>
                </thead>
                <tbody>
                  {enums.map((enumItem, index) => (
                    <tr 
                      key={enumItem.value}
                      className={draggedItemIndex === index ? styles.dragging : ''}
                      draggable={!test.isFormValidated}
                      onDragStart={() => handleDragStart(index)}
                      onDragOver={(e) => e.preventDefault()}
                      onDragEnter={() => handleDragEnter(index)}
                      onDragEnd={handleDragEnd}
                    >
                      <td>{enumItem.value}</td>
                      <td>{enumItem.name}</td>
                      <td>{enumItem.nrOrd}</td>
                      {!test.isFormValidated && (
                        <>
                          <td>
                            <button 
                              type="button" 
                              onClick={() => {
                                setCurrentEnum(enumItem);
                                setShowEnumDialog(true);
                              }} 
                              className="action-button edit-button small-button"
                            >
                              Edit
                            </button>
                            <button 
                              type="button" 
                              onClick={() => handleDeleteEnum(enumItem)} 
                              className="action-button delete-button small-button"
                            >
                              Delete
                            </button>
                          </td>
                          <td>
                            <DragHandle 
                              onMouseDown={() => setIsDragHandleActive(true)} 
                              onMouseUp={() => setIsDragHandleActive(false)} 
                            />
                          </td>
                        </>
                      )}
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
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

          <div className={styles.manageTestsContainer}>
            <button onClick={() => setShowEquipmentDialog(true)} className="action-button secondary">Manage Equipments</button>
          </div>

          <h3 className="section-title">Associated Reagents</h3>
          {associatedReagents.length > 0 ? (
            <ul className="item-list">
              {associatedReagents.map(reg => (
                <li key={reg.id}>{reg.code} - {reg.name} {reg.casNumber ? `(CAS: ${reg.casNumber})` : ''}</li>
              ))}
            </ul>
          ) : (
            <p>No associated reagents</p>
          )}

          <div className={styles.manageTestsContainer}>
            <button onClick={() => setShowReagentDialog(true)} className="action-button secondary">Manage Reagents</button>
          </div>
        </div>
      </DetailViewContent>

      {showEditDialog && (
        <TestDialog 
          open={true} 
          testData={test} 
          onSave={handleEditSave} 
          onClose={() => setShowEditDialog(false)} 
        />
      )}

      {showEnumDialog && currentEnum && (
        <TestEnumDialog 
          open={true} 
          enumData={currentEnum} 
          isEdit={enums.some(e => e.value === currentEnum.value && currentEnum.name !== '')}
          onSave={handleSaveEnum} 
          onClose={() => setShowEnumDialog(false)} 
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

      {showReagentDialog && (
        <SelectDialog 
          open={true}
          title="Select Reagents"
          items={allMaterials.filter(mat => mat.isReagent).map(mat => ({ id: mat.id, name: `${mat.name} (${mat.code})` }))}
          selectedIds={associatedReagents.map(reg => reg.id)}
          onSave={handleReagentSelectionSave}
          onClose={() => setShowReagentDialog(false)}
          idPrefix="reagent"
        />
      )}

      {showConfirmationDialog && (
        <ConfirmationDialog 
          open={true}
          title="Confirm Test Activation"
          message={`Are you sure you want to activate test ${test.name}?`}
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

export default TestDetailView;
