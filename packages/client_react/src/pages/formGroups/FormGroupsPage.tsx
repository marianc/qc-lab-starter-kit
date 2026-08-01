import React, { useState, useEffect } from 'react';
import FormGroupDetailView from '@/components/formGroups/FormGroupDetailView';
import FormGroupDialog from '@/components/formGroups/FormGroupDialog';
import { DragHandle } from '@/components/common/ui';
import type { FormGroupDto, UpdateFormGroupDto } from '@/types/formGroup';
import type { TestDto } from '@/types/test';
import formGroupsService from '@/services/formGroupsService';
import testsService from '@/services/testsService';
import authService from '@/services/authService';
import formsService from '@/services/formsService';

const FormGroupsPage: React.FC = () => {
  const [formGroups, setFormGroups] = useState<FormGroupDto[]>([]);
  const [allTests, setAllTests] = useState<TestDto[]>([]);
  const [selectedFormGroupId, setSelectedFormGroupId] = useState<number | null>(null);
  const [lastEditedFormGroupId, setLastEditedFormGroupId] = useState<number | null>(null);
  const [showAddDialog, setShowAddDialog] = useState(false);
  const [isDetailOpen, setIsDetailOpen] = useState(false);
  const [draggedItemIndex, setDraggedItemIndex] = useState<number | null>(null);
  const [isDragHandleActive, setIsDragHandleActive] = useState(false);

  const fetchData = async () => {
    try {
      const [groups, tests] = await Promise.all([
        formGroupsService.getAllFormGroups(),
        testsService.getAllTests()
      ]);
      setFormGroups(groups.sort((a, b) => a.nrOrd - b.nrOrd));
      setAllTests(tests);
    } catch (err) {
      console.error('Failed to fetch form groups data', err);
    }
  };

  useEffect(() => {
    fetchData();
  }, []);

  const handleDragStart = (index: number) => {
    if (!isDragHandleActive) return;
    setDraggedItemIndex(index);
  };

  const handleDragEnter = (index: number) => {
    if (draggedItemIndex === null || draggedItemIndex === index) return;
    const newGroups = [...formGroups];
    const draggedItem = newGroups[draggedItemIndex];
    newGroups.splice(draggedItemIndex, 1);
    newGroups.splice(index, 0, draggedItem);
    setFormGroups(newGroups);
    setDraggedItemIndex(index);
  };

  const handleDragEnd = async () => {
    setDraggedItemIndex(null);
    setIsDragHandleActive(false);
    
    const reordered = formGroups.map((g, idx) => ({ ...g, nrOrd: idx + 1 }));
    setFormGroups(reordered);

    try {
      const updateDtos: UpdateFormGroupDto[] = reordered.map(g => ({
        id: g.id,
        name: g.name,
        description: g.description,
        nrOrd: g.nrOrd
      }));
      await formGroupsService.bulkUpdateFormGroups(updateDtos);
    } catch (err) {
      console.error('Failed to save order', err);
      fetchData();
    }
  };

  const handleAddSave = async (formGroup: FormGroupDto) => {
    try {
      const res = await formGroupsService.createFormGroup({
        name: formGroup.name,
        description: formGroup.description,
        nrOrd: formGroup.nrOrd
      });
      const newId = res.id;

      const user = await authService.me();
      if (user) {
        await formsService.createForm({
          formGroupId: newId,
          version: "v0",
          customNav: null,
          isCustomized: false,
          submittedUserId: user.id,
          submittedDate: new Date().toISOString()
        });
      }

      setShowAddDialog(false);
      fetchData();
      setLastEditedFormGroupId(newId);
    } catch (err) {
      console.error('Failed to add form group', err);
    }
  };

  const handleViewDetails = (id: number) => {
    setSelectedFormGroupId(id);
    setIsDetailOpen(true);
  };

  const handleDetailClose = async (savedId?: number | null) => {
    setIsDetailOpen(false);
    setSelectedFormGroupId(null);
    await fetchData();
    if (savedId) {
      setLastEditedFormGroupId(savedId);
    }
  };

  return (
    <div className="page-container">
      <h2 className="page-title">Form Groups</h2>
      <button onClick={() => setShowAddDialog(true)} className="action-button primary">Add New Form Group</button>
      <table className="data-table">
        <thead>
          <tr>
            <th>ID</th>
            <th>Name</th>
            <th>Description</th>
            <th>Order</th>
            <th>Actions</th>
            <th className="drag-handle-col"></th>
          </tr>
        </thead>
        <tbody>
          {formGroups.map((group, index) => (
            <tr 
              key={group.id}
              className={`${group.id === lastEditedFormGroupId ? "highlighted-row" : ""} ${draggedItemIndex === index ? "dragging" : ""}`}
              draggable={true}
              onDragStart={() => handleDragStart(index)}
              onDragOver={(e) => e.preventDefault()}
              onDragEnter={() => handleDragEnter(index)}
              onDragEnd={handleDragEnd}
            >
              <td>{group.id}</td>
              <td>{group.name}</td>
              <td>{group.description}</td>
              <td>{group.nrOrd}</td>
              <td>
                <button 
                  onClick={() => handleViewDetails(group.id)} 
                  className={`action-button ${group.isFormValidated ? 'secondary' : 'edit-button'} small-button`}
                >
                  Details
                </button>
              </td>
              <td>
                <DragHandle 
                  onMouseDown={() => setIsDragHandleActive(true)} 
                  onMouseUp={() => setIsDragHandleActive(false)} 
                />
              </td>
            </tr>
          ))}
        </tbody>
      </table>

      {isDetailOpen && selectedFormGroupId !== null && (
        <FormGroupDetailView 
          formGroupId={selectedFormGroupId}
          onClose={handleDetailClose}
          breadcrumbs={["Form Groups"]}
          allTests={allTests}
        />
      )}

      {showAddDialog && (
        <FormGroupDialog 
          open={true}
          onSave={handleAddSave}
          onClose={() => setShowAddDialog(false)} 
        />
      )}
    </div>
  );
};

export default FormGroupsPage;
