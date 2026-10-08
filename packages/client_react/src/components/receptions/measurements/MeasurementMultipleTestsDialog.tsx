import React, { useEffect, useState, useMemo } from 'react';
import { 
  Dialog, 
  DialogHeader, 
  DialogContent, 
  DialogFooter 
} from '@/components/common/ui';
import styles from './MeasurementMultipleTestsDialog.module.css';
import type { MeasurementTestDto } from '@/types/measurement';
import type { TestDto } from '@/types/test';

interface Props {
  open: boolean;
  applicableTests: { id: number; name: string }[];
  allTests: TestDto[];
  existingTests?: MeasurementTestDto[];
  onSave: (tests: MeasurementTestDto[]) => void;
  onClose: () => void;
  isEditMode?: boolean;
}

interface TestValueState {
  scalarValue: string;
  arrayValues: (number | string)[];
  newArrayInput: string;
  editingArrayIndex: number | null;
  draggedIndex: number | null;
}

const MeasurementMultipleTestsDialog: React.FC<Props> = ({
  open,
  applicableTests,
  allTests,
  existingTests = [],
  onSave,
  onClose,
  isEditMode = false
}) => {
  // Sort tests ascending by nrOrd
  const sortedApplicableTests = useMemo(() => {
    return [...applicableTests]
      .map(at => {
        const fullTest = allTests.find(t => t.id === at.id);
        return {
          id: at.id,
          name: at.name,
          fullTest,
          nrOrd: fullTest?.nrOrd ?? 0
        };
      })
      .sort((a, b) => a.nrOrd - b.nrOrd);
  }, [applicableTests, allTests]);

  const [testStates, setTestStates] = useState<Record<number, TestValueState>>({});
  const [activeDragTestId, setActiveDragTestId] = useState<number | null>(null);

  // Initialize state only when dialog opens
  useEffect(() => {
    if (!open) return;

    const initialStates: Record<number, TestValueState> = {};

    sortedApplicableTests.forEach(({ id, fullTest }) => {
      const existing = existingTests.find(et => et.testId === id);
      const isArray = fullTest?.isArray || false;

      let scalarValue = '';
      let arrayValues: (number | string)[] = [];

      if (existing && existing.value !== null && existing.value !== undefined) {
        if (isArray) {
          const raw = Array.isArray(existing.value) ? existing.value : [existing.value];
          arrayValues = raw.map(v => {
            if (fullTest?.typeId === 1 || fullTest?.typeId === 2 || fullTest?.typeId === 3 || fullTest?.typeId === 4) {
              const num = parseFloat(v);
              return isNaN(num) ? v : num;
            }
            return v;
          });
        } else {
          scalarValue = existing.value.toString();
        }
      }

      initialStates[id] = {
        scalarValue,
        arrayValues,
        newArrayInput: '',
        editingArrayIndex: null,
        draggedIndex: null
      };
    });

    setTestStates(initialStates);
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [open]);

  const handleScalarChange = (testId: number, val: string) => {
    setTestStates(prev => ({
      ...prev,
      [testId]: {
        ...(prev[testId] || {
          scalarValue: '',
          arrayValues: [],
          newArrayInput: '',
          editingArrayIndex: null,
          draggedIndex: null
        }),
        scalarValue: val
      }
    }));
  };

  const handleNewArrayInputChange = (testId: number, val: string) => {
    setTestStates(prev => ({
      ...prev,
      [testId]: {
        ...(prev[testId] || {
          scalarValue: '',
          arrayValues: [],
          newArrayInput: '',
          editingArrayIndex: null,
          draggedIndex: null
        }),
        newArrayInput: val
      }
    }));
  };

  const addOrUpdateArrayItem = (testId: number, fullTest?: TestDto) => {
    const state = testStates[testId];
    if (!state || state.newArrayInput.toString().trim() === '') return;

    let finalVal: any = state.newArrayInput;
    if (fullTest?.typeId === 1 || fullTest?.typeId === 2) {
      const num = parseFloat(state.newArrayInput);
      if (!isNaN(num)) finalVal = num;
    } else if (fullTest?.typeId === 3 || fullTest?.typeId === 4) {
      const num = parseInt(state.newArrayInput);
      if (!isNaN(num)) finalVal = num;
    }

    const newArr = [...state.arrayValues];
    if (state.editingArrayIndex !== null) {
      newArr[state.editingArrayIndex] = finalVal;
    } else {
      newArr.push(finalVal);
    }

    setTestStates(prev => ({
      ...prev,
      [testId]: {
        ...prev[testId],
        arrayValues: newArr,
        newArrayInput: '',
        editingArrayIndex: null
      }
    }));
  };

  const editArrayItem = (testId: number, index: number) => {
    const state = testStates[testId];
    if (!state) return;

    setTestStates(prev => ({
      ...prev,
      [testId]: {
        ...prev[testId],
        editingArrayIndex: index,
        newArrayInput: String(state.arrayValues[index] ?? '')
      }
    }));
  };

  const cancelEditArrayItem = (testId: number) => {
    setTestStates(prev => ({
      ...prev,
      [testId]: {
        ...prev[testId],
        editingArrayIndex: null,
        newArrayInput: ''
      }
    }));
  };

  const removeArrayItem = (testId: number, index: number) => {
    const state = testStates[testId];
    if (!state) return;

    const newArr = state.arrayValues.filter((_, i) => i !== index);
    setTestStates(prev => ({
      ...prev,
      [testId]: {
        ...prev[testId],
        arrayValues: newArr,
        editingArrayIndex: state.editingArrayIndex === index ? null : state.editingArrayIndex,
        newArrayInput: state.editingArrayIndex === index ? '' : state.newArrayInput
      }
    }));
  };

  // Drag-and-drop array reordering
  const handleDragStart = (testId: number, index: number) => {
    if (activeDragTestId !== testId) return;
    setTestStates(prev => ({
      ...prev,
      [testId]: {
        ...prev[testId],
        draggedIndex: index
      }
    }));
  };

  const handleDragEnter = (testId: number, index: number) => {
    const state = testStates[testId];
    if (!state || state.draggedIndex === null || state.draggedIndex === index) return;

    const newArr = [...state.arrayValues];
    const draggedItem = newArr[state.draggedIndex];
    newArr.splice(state.draggedIndex, 1);
    newArr.splice(index, 0, draggedItem);

    setTestStates(prev => ({
      ...prev,
      [testId]: {
        ...prev[testId],
        arrayValues: newArr,
        draggedIndex: index
      }
    }));
  };

  const handleDragEnd = (testId: number) => {
    setTestStates(prev => ({
      ...prev,
      [testId]: {
        ...prev[testId],
        draggedIndex: null
      }
    }));
    setActiveDragTestId(null);
  };

  const getDisplayValue = (fullTest: TestDto | undefined, val: any) => {
    if (!fullTest) return val?.toString() || '';
    if (fullTest.typeId === 3) {
      return val === 1 || val === true || val.toString() === '1' ? 'Yes' : 'No';
    }
    if (fullTest.typeId === 4 && fullTest.enums) {
      const entry = fullTest.enums.find(e => e.value.toString() === val.toString());
      return entry ? entry.name : val.toString();
    }
    return val?.toString() || '';
  };

  const renderControl = (
    fullTest: TestDto | undefined,
    value: string,
    onChange: (val: string) => void,
    placeholder: string = '-- Select --'
  ) => {
    if (!fullTest) return <input type="text" className="form-control" disabled />;

    switch (fullTest.typeId) {
      case 1: // Integer
        return (
          <input 
            type="number" 
            step="1" 
            value={value} 
            onChange={e => onChange(e.target.value)} 
            className="form-control" 
          />
        );
      case 2: // Real
        return (
          <input 
            type="number" 
            step="any" 
            value={value} 
            onChange={e => onChange(e.target.value)} 
            className="form-control" 
          />
        );
      case 3: // Boolean
        return (
          <select 
            value={value} 
            onChange={e => onChange(e.target.value)} 
            className="form-control"
          >
            <option value="">{placeholder}</option>
            <option value="1">Yes</option>
            <option value="0">No</option>
          </select>
        );
      case 4: // Enum
        return (
          <select 
            value={value} 
            onChange={e => onChange(e.target.value)} 
            className="form-control"
          >
            <option value="">{placeholder}</option>
            {fullTest.enums?.map(e => (
              <option key={e.value} value={e.value}>{e.name}</option>
            ))}
          </select>
        );
      default:
        return (
          <input 
            type="text" 
            value={value} 
            onChange={e => onChange(e.target.value)} 
            className="form-control" 
          />
        );
    }
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();

    const resultsToSave: MeasurementTestDto[] = [];

    sortedApplicableTests.forEach(({ id, fullTest }) => {
      const state = testStates[id];
      if (!state) return;

      const isArray = fullTest?.isArray || false;
      const existing = existingTests.find(et => et.testId === id);
      const note = existing?.note || null;

      if (isArray) {
        if (state.arrayValues.length > 0) {
          resultsToSave.push({
            testId: id,
            value: state.arrayValues,
            note
          });
        }
      } else {
        if (state.scalarValue.trim() !== '') {
          let parsedVal: any = state.scalarValue;
          if (fullTest?.typeId === 1 || fullTest?.typeId === 2) {
            const num = parseFloat(state.scalarValue);
            if (!isNaN(num)) parsedVal = num;
          } else if (fullTest?.typeId === 3 || fullTest?.typeId === 4) {
            const num = parseInt(state.scalarValue);
            if (!isNaN(num)) parsedVal = num;
          }

          resultsToSave.push({
            testId: id,
            value: parsedVal,
            note
          });
        }
      }
    });

    onSave(resultsToSave);
  };

  return (
    <Dialog open={open} onClose={onClose} className={styles.dialogWide}>
      <DialogHeader>
        <h2>{isEditMode ? 'Edit Multiple Tests' : 'Add Multiple Test Results'}</h2>
      </DialogHeader>
      <DialogContent>
        <form id="multiple-tests-form" onSubmit={handleSubmit}>
          {sortedApplicableTests.length === 0 ? (
            <p className={styles.noTestsMessage}>No applicable tests found for this reception.</p>
          ) : (
            sortedApplicableTests.map(({ id, fullTest }) => {
              const state = testStates[id] || {
                scalarValue: '',
                arrayValues: [],
                newArrayInput: '',
                editingArrayIndex: null,
                draggedIndex: null
              };

              const isArray = fullTest?.isArray || false;
              const testLabel = `${fullTest?.name || 'Unknown'}${fullTest?.unitName ? ` [${fullTest.unitName}]` : ''}:`;

              return (
                <div key={id} className={styles.testRow}>
                  <label htmlFor={`test-${id}`} className={styles.label}>
                    {testLabel}
                  </label>

                  {isArray ? (
                    <div>
                      {state.arrayValues.length > 0 && (
                        <ul className={`${styles.arrayItemList} item-list`}>
                          {state.arrayValues.map((val, idx) => (
                            <li 
                              key={idx}
                              className={`${styles.arrayItem} ${state.draggedIndex === idx ? styles.dragging : ''}`}
                              draggable
                              onDragStart={() => handleDragStart(id, idx)}
                              onDragEnter={() => handleDragEnter(id, idx)}
                              onDragOver={(e) => e.preventDefault()}
                              onDragEnd={() => handleDragEnd(id)}
                            >
                              <span>{getDisplayValue(fullTest, val)}</span>
                              <div className={styles.arrayItemActions}>
                                <button 
                                  type="button" 
                                  onClick={() => editArrayItem(id, idx)} 
                                  className="action-button edit-button small-button"
                                >
                                  Edit
                                </button>
                                <button 
                                  type="button" 
                                  onClick={() => removeArrayItem(id, idx)} 
                                  className="action-button delete-button small-button"
                                >
                                  Delete
                                </button>
                                <span 
                                  className={`drag-handle ${styles.dragHandle}`}
                                  onMouseDown={() => setActiveDragTestId(id)}
                                  onMouseUp={() => setActiveDragTestId(null)}
                                >
                                  ⠿
                                </span>
                              </div>
                            </li>
                          ))}
                        </ul>
                      )}

                      <div className={styles.arrayInputContainer}>
                        <div className={styles.arrayInput}>
                          {renderControl(
                            fullTest, 
                            state.newArrayInput, 
                            val => handleNewArrayInputChange(id, val),
                            '-- Select Value --'
                          )}
                        </div>
                        <button 
                          type="button" 
                          onClick={() => addOrUpdateArrayItem(id, fullTest)} 
                          className="action-button primary small-button"
                        >
                          {state.editingArrayIndex !== null ? 'Update' : 'Add'}
                        </button>
                        {state.editingArrayIndex !== null && (
                          <button 
                            type="button" 
                            onClick={() => cancelEditArrayItem(id)} 
                            className="action-button secondary small-button"
                          >
                            Cancel
                          </button>
                        )}
                      </div>
                    </div>
                  ) : (
                    <div>
                      {renderControl(
                        fullTest,
                        state.scalarValue,
                        val => handleScalarChange(id, val),
                        '-- No Selection --'
                      )}
                    </div>
                  )}
                </div>
              );
            })
          )}
        </form>
      </DialogContent>
      <DialogFooter>
        <button type="submit" form="multiple-tests-form" className="action-button primary">
          Save
        </button>
        <button type="button" onClick={onClose} className="action-button secondary">
          Cancel
        </button>
      </DialogFooter>
    </Dialog>
  );
};

export default MeasurementMultipleTestsDialog;
