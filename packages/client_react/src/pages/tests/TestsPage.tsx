import React, { useState, useEffect } from 'react';
import { DragHandle } from '@/components/common/ui';
import TestDialog from '@/components/tests/TestDialog';
import TestDetailView from '@/components/tests/TestDetailView';
import styles from './TestsPage.module.css';
import type { CreateTestDto, ReorderTestDto, TestDto } from '@/types/test';
import type { NormDto } from '@/types/norm';
import type { ValueTypeDto } from '@/types/valueType';
import testsService from '@/services/testsService';
import normsService from '@/services/normsService';
import valueTypesService from '@/services/valueTypesService';

const TestsPage: React.FC = () => {
  const [tests, setTests] = useState<TestDto[]>([]);
  const [norms, setNorms] = useState<NormDto[]>([]);
  const [valueTypes, setValueTypes] = useState<ValueTypeDto[]>([]);
  const [selectedTestId, setSelectedTestId] = useState<number | null>(null);
  const [isDetailOpen, setIsDetailOpen] = useState(false);
  const [showAddDialog, setShowAddDialog] = useState(false);
  const [lastEditedTestId, setLastEditedTestId] = useState<number | null>(null);
  const [draggedItemIndex, setDraggedItemIndex] = useState<number | null>(null);
  const [isDragHandleActive, setIsDragHandleActive] = useState(false);

  const fetchTests = async () => {
    try {
      const data = await testsService.getAllTests();
      setTests([...data].sort((a, b) => a.nrOrd - b.nrOrd));
    } catch (err) {
      console.error('Failed to fetch tests', err);
    }
  };

  useEffect(() => {
    fetchTests();
    normsService.getAllNorms().then(setNorms);
    valueTypesService.getAllValueTypes().then(setValueTypes);
  }, []);

  const handleDragStart = (index: number) => {
    if (!isDragHandleActive) return;
    setDraggedItemIndex(index);
  };

  const handleDragEnter = (index: number) => {
    if (draggedItemIndex === null || draggedItemIndex === index) return;

    const newTests = [...tests];
    const draggedItem = newTests[draggedItemIndex];
    newTests.splice(draggedItemIndex, 1);
    newTests.splice(index, 0, draggedItem);
    setTests(newTests);
    setDraggedItemIndex(index);
  };

  const handleDragEnd = async () => {
    setDraggedItemIndex(null);
    setIsDragHandleActive(false);
    
    const reorderedTests = tests.map((t, idx) => ({ ...t, nrOrd: idx + 1 }));
    setTests(reorderedTests);

    try {
      const orderUpdate: ReorderTestDto[] = reorderedTests.map(t => ({ id: t.id, nrOrd: t.nrOrd }));
      await testsService.reorderTests(orderUpdate);
    } catch (err) {
      console.error('Failed to save order', err);
      fetchTests();
    }
  };

  const getValueTypeName = (test: TestDto) => {
    const typeName = test.typeName;
    return test.isArray ? `[${typeName}]` : typeName;
  };

  const getNormName = (normId?: number | null) => {
    if (!normId) return "";
    return norms.find(n => n.id === normId)?.name || "";
  };

  const viewDetails = (id: number) => {
    setSelectedTestId(id);
    setLastEditedTestId(id);
    setIsDetailOpen(true);
  };

  const handleDetailClose = (savedId?: number | null) => {
    setIsDetailOpen(false);
    setSelectedTestId(null);
    fetchTests();
    if (savedId) {
      setLastEditedTestId(savedId);
    }
  };

  const handleAddSave = async (testData: TestDto) => {
    try {
            const createDto: CreateTestDto = {
              name: testData.name,
              code: testData.code,
              description: testData.description,
              typeId: testData.typeId,
              isArray: testData.isArray,
              isParam: testData.isParam,
              forEnvironmentalControl: testData.forEnvironmentalControl,
              forCertification: testData.forCertification,
              unitId: testData.unitId,
              normId: testData.normId,
              normRef: testData.normRef,
              sopId: testData.sopId,
              nrOrd: testData.nrOrd,
              isObsolete: testData.isObsolete,
              enums: testData.enumListString ? Array.from(new Set(testData.enumListString.split(/[\n\r,;]+/).map(s => s.trim()).filter(s => s !== ''))).map((name, idx) => ({
                name: name,
                value: idx + 1,
                nrOrd: idx + 1
              })) : null
            };      const result = await testsService.createTest(createDto);
      setLastEditedTestId(result.id);
      setShowAddDialog(false);
      fetchTests();
    } catch (err) {
      console.error('Failed to add test', err);
    }
  };

  const handleTestUpdated = (updatedTest: TestDto) => {
    setTests(prev => prev.map(t => t.id === updatedTest.id ? updatedTest : t));
  };

  return (
    <div className="page-container">
      <h2 className="page-title">Tests</h2>
      <button onClick={() => setShowAddDialog(true)} className="action-button primary">Add New Test</button>
      <table className="data-table">
        <thead>
          <tr>
            <th>ID</th>
            <th>Name</th>
            <th>Code</th>
            <th>Value Type</th>
            <th>Unit</th>
            <th>Norm</th>
            <th>Is Param</th>
            <th>For Certification</th>
            <th>Is Form Validated</th>
            <th>Is Obsolete</th>
            <th>Order</th>
            <th>Actions</th>
            <th className={styles.dragHandleCol}></th>
          </tr>
        </thead>
        <tbody>
          {tests.map((test, index) => (
            <tr 
              key={test.id} 
              className={`${test.id === lastEditedTestId ? "highlighted-row" : ""} ${draggedItemIndex === index ? styles.dragging : ""}`}
              draggable
              onDragStart={() => handleDragStart(index)}
              onDragOver={(e) => e.preventDefault()}
              onDragEnter={() => handleDragEnter(index)}
              onDragEnd={handleDragEnd}
            >
              <td>{test.id}</td>
              <td>{test.name}</td>
              <td>{test.code}</td>
              <td>{getValueTypeName(test)}</td>
              <td>{test.unitName}</td>
              <td>{getNormName(test.normId)}</td>
              <td>{test.isParam ? "Yes" : "No"}</td>
              <td>{test.forCertification ? "Yes" : "No"}</td>
              <td>{test.isFormValidated ? "Yes" : "No"}</td>
              <td>{test.isObsolete ? "Yes" : "No"}</td>
              <td>{test.nrOrd}</td>
              <td>
                <button 
                  onClick={() => viewDetails(test.id)} 
                  className={`action-button ${test.isFormValidated ? "secondary" : "edit-button"} small-button`}
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

      {isDetailOpen && selectedTestId !== null && (
        <TestDetailView 
          testId={selectedTestId}
          onClose={handleDetailClose}
          onTestUpdated={handleTestUpdated}
          breadcrumbs={["Tests"]}
        />
      )}

      {showAddDialog && (
        <TestDialog 
          open={true}
          onSave={handleAddSave}
          onClose={() => setShowAddDialog(false)}
        />
      )}
    </div>
  );
};

export default TestsPage;
