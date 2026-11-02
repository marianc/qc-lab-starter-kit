import React, { useState, useMemo } from 'react';
import {
  DetailView,
  DetailViewHeader,
  DetailViewContent,
  Dialog,
  DialogHeader,
  DialogContent,
  DialogFooter
} from '@/components/common/ui';
import type { WorksheetTestItem } from '@/types/worksheet';
import { WorksheetArrayItemDialog } from './WorksheetArrayItemDialog';
import styles from './WorksheetValuesDetailView.module.css';

interface WorksheetValuesDetailViewProps {
  items: WorksheetTestItem[];
  onClose: () => void;
  onSave: (updatedItems: WorksheetTestItem[]) => void;
}

const formatDisplayValue = (item: WorksheetTestItem, val: any): string => {
  if (val === null || val === undefined || val === '') return '-';
  if (item.value_type === 'enum' && item.enums) {
    const num = Number(val);
    if (!isNaN(num) && num >= 1 && num <= item.enums.length) {
      return item.enums[num - 1];
    }
    return String(val);
  }
  if (item.value_type === 'boolean') {
    return (val === true || val === 1 || val === '1' || val === 1.0 || val === 'true') ? 'Yes' : 'No';
  }
  return String(val);
};

const WorksheetValuesDetailView: React.FC<WorksheetValuesDetailViewProps> = ({
  items,
  onClose,
  onSave
}) => {
  const directItems = items.filter(item => !item.formula || item.formula.trim() === '');
  
  const [valuesState, setValuesState] = useState<Record<string, any>>(() => {
    const map: Record<string, any> = {};
    items.forEach(item => {
      map[item.id] = item.value;
    });
    return map;
  });

  const [showArrayItemDialog, setShowArrayItemDialog] = useState(false);
  const [groupedItemsForDialog, setGroupedItemsForDialog] = useState<WorksheetTestItem[]>([]);
  const [editingArrayIndex, setEditingArrayIndex] = useState<number>(-1);
  const [initialArrayItemValue, setInitialArrayItemValue] = useState<Record<string, any>>({});

  const nonArrayItems = useMemo(() => directItems.filter(item => !item.is_array), [directItems]);
  const standaloneArrayItems = useMemo(() => directItems.filter(item => item.is_array && (!item.code_related_arrays || item.code_related_arrays.trim() === '')), [directItems]);
  const groupedArrayItems = useMemo(() => {
    const groups: Record<string, WorksheetTestItem[]> = {};
    directItems.filter(item => item.is_array && item.code_related_arrays && item.code_related_arrays.trim() !== '').forEach(item => {
      const key = item.code_related_arrays!;
      if (!groups[key]) groups[key] = [];
      groups[key].push(item);
    });
    return groups;
  }, [directItems]);

  const handleChange = (id: string, val: any, valueType: string, enums?: string[] | null) => {
    let processed = val;
    if (valueType === 'enum' && enums) {
      if (val === '' || val === null || val === undefined) {
        processed = null;
      } else {
        const index = enums.indexOf(val);
        processed = index >= 0 ? index + 1 : null;
      }
    } else {
      if (valueType === 'integer' || valueType === 'real') {
        processed = val === '' ? null : Number(val);
      } else if (valueType === 'boolean') {
        if (val === '' || val === null || val === undefined) {
          processed = null;
        } else {
          processed = (val === 'true' || val === true || val === 1 || val === '1' || val === 1.0) ? 1 : 0;
        }
      }
    }
    setValuesState(prev => ({ ...prev, [id]: processed }));
  };

  const handleOpenAddArray = (groupItems: WorksheetTestItem[]) => {
    setGroupedItemsForDialog(groupItems);
    setEditingArrayIndex(-1);
    const initial: Record<string, any> = {};
    groupItems.forEach(item => {
      initial[item.id] = null;
    });
    setInitialArrayItemValue(initial);
    setShowArrayItemDialog(true);
  };

  const handleOpenEditArray = (groupItems: WorksheetTestItem[], idx: number) => {
    setGroupedItemsForDialog(groupItems);
    setEditingArrayIndex(idx);
    const initial: Record<string, any> = {};
    groupItems.forEach(item => {
      const arr = valuesState[item.id] || [];
      initial[item.id] = arr[idx] !== undefined ? arr[idx] : null;
    });
    setInitialArrayItemValue(initial);
    setShowArrayItemDialog(true);
  };

  const handleSaveArrayItem = (itemValues: Record<string, any>) => {
    setValuesState(prev => {
      const next = { ...prev };
      groupedItemsForDialog.forEach(item => {
        const arr = [...(next[item.id] || [])];
        const val = itemValues[item.id];
        if (editingArrayIndex === -1) {
          arr.push(val);
        } else {
          arr[editingArrayIndex] = val;
        }
        next[item.id] = arr;
      });
      return next;
    });
    setShowArrayItemDialog(false);
  };

  const handleDeleteArrayItem = (groupItems: WorksheetTestItem[], idx: number) => {
    setValuesState(prev => {
      const next = { ...prev };
      groupItems.forEach(item => {
        const arr = [...(next[item.id] || [])];
        arr.splice(idx, 1);
        next[item.id] = arr;
      });
      return next;
    });
  };

  const handleSave = () => {
    const updated = items.map(item => {
      if (valuesState[item.id] !== undefined) {
        return { ...item, value: valuesState[item.id] };
      }
      return item;
    });
    onSave(updated);
  };

  return (
    <DetailView>
      <DetailViewHeader title="Edit Measurement Values" onBack={onClose} />
      <DetailViewContent>
        <div className="page-container">
          <p className={styles.subtitle}>
            Edit direct measurement values (inputs without formulas). Saving will recalculate all dependent formulas on the server and update the worksheet.
          </p>

          {directItems.length === 0 ? (
            <div className={styles.emptyMessage}>
              No direct measurement items (tests without formulas) found in the worksheet. Add a test without a formula first.
            </div>
          ) : (
            <div>
              {/* Non-array items */}
              {nonArrayItems.map(item => {
                const val = valuesState[item.id];
                let selectVal = '';
                if (item.value_type === 'enum' && item.enums) {
                  const num = Number(val);
                  if (!isNaN(num) && num >= 1 && num <= item.enums.length) {
                    selectVal = item.enums[num - 1];
                  }
                } else if (item.value_type === 'boolean') {
                  if (val === true || val === 1 || val === '1' || val === 1.0 || val === 'true') selectVal = 'true';
                  else if (val === false || val === 0 || val === '0' || val === 0.0 || val === 'false') selectVal = 'false';
                  else selectVal = '';
                } else {
                  selectVal = val !== null && val !== undefined ? val : '';
                }

                return (
                  <div key={item.id} className="form-group">
                    <label htmlFor={item.id}>
                      {item.name} ({item.code}){item.measurement_unit ? ` [${item.measurement_unit}]` : ''}:
                    </label>

                    {item.value_type === 'enum' && item.enums ? (
                      <select
                        id={item.id}
                        className="form-control"
                        value={selectVal}
                        onChange={(e) => handleChange(item.id, e.target.value, item.value_type, item.enums)}
                      >
                        <option value="">-- Select Option --</option>
                        {item.enums.map(opt => (
                          <option key={opt} value={opt}>{opt}</option>
                        ))}
                      </select>
                    ) : item.value_type === 'boolean' ? (
                      <select
                        id={item.id}
                        className="form-control"
                        value={selectVal}
                        onChange={(e) => handleChange(item.id, e.target.value === '' ? null : e.target.value, item.value_type)}
                      >
                        <option value="">-- No Selection --</option>
                        <option value="true">Yes</option>
                        <option value="false">No</option>
                      </select>
                    ) : (
                      <input
                        id={item.id}
                        type={item.value_type === 'integer' || item.value_type === 'real' ? 'number' : 'text'}
                        step={item.value_type === 'real' ? 'any' : '1'}
                        className="form-control"
                        value={selectVal}
                        onChange={(e) => handleChange(item.id, e.target.value, item.value_type)}
                      />
                    )}
                  </div>
                );
              })}

              {/* Standalone Array Items */}
              {standaloneArrayItems.map(item => {
                const arrayValues: any[] = valuesState[item.id] || [];
                return (
                  <div key={item.id} className="form-group">
                    <p>Array parameter: {item.name} ({item.code}){item.measurement_unit ? ` [${item.measurement_unit}]` : ''}</p>
                    <button
                      type="button"
                      onClick={() => handleOpenAddArray([item])}
                      className="action-button primary small-button"
                    >
                      +
                    </button>
                    <table className="data-table">
                      <tbody>
                        {arrayValues.length === 0 ? (
                          <tr>
                            <td colSpan={2} style={{ textAlign: 'center', color: 'var(--text-muted)' }}>No array items</td>
                          </tr>
                        ) : (
                          arrayValues.map((val, idx) => (
                            <tr key={idx}>
                              <td>{formatDisplayValue(item, val)}</td>
                              <td>
                                <button
                                  type="button"
                                  onClick={() => handleOpenEditArray([item], idx)}
                                  className="action-button edit-button small-button"
                                >
                                  Edit
                                </button>
                                <button
                                  type="button"
                                  onClick={() => handleDeleteArrayItem([item], idx)}
                                  className="action-button delete-button small-button"
                                >
                                  Delete
                                </button>
                              </td>
                            </tr>
                          ))
                        )}
                      </tbody>
                    </table>
                  </div>
                );
              })}

              {/* Grouped Code-Related Arrays */}
              {Object.entries(groupedArrayItems).map(([groupKey, groupItems]) => {
                const firstItem = groupItems[0];
                const arrayLength = (valuesState[firstItem.id] || []).length;
                return (
                  <div key={groupKey} className="form-group">
                    <p>Array parameter group: {groupKey}</p>
                    <button
                      type="button"
                      onClick={() => handleOpenAddArray(groupItems)}
                      className="action-button primary small-button"
                    >
                      +
                    </button>
                    <table className="data-table">
                      <thead>
                        <tr>
                          {groupItems.map(item => (
                            <th key={item.id}>
                              {item.name} ({item.code}){item.measurement_unit ? ` [${item.measurement_unit}]` : ''}
                            </th>
                          ))}
                          <th>Actions</th>
                        </tr>
                      </thead>
                      <tbody>
                        {arrayLength === 0 ? (
                          <tr>
                            <td colSpan={groupItems.length + 1} style={{ textAlign: 'center', color: 'var(--text-muted)' }}>
                              No array rows
                            </td>
                          </tr>
                        ) : (
                          Array.from({ length: arrayLength }).map((_, idx) => (
                            <tr key={idx}>
                              {groupItems.map(item => {
                                const arr = valuesState[item.id] || [];
                                return (
                                  <td key={item.id}>
                                    {formatDisplayValue(item, arr[idx])}
                                  </td>
                                );
                              })}
                              <td>
                                <button
                                  type="button"
                                  onClick={() => handleOpenEditArray(groupItems, idx)}
                                  className="action-button edit-button small-button"
                                >
                                  Edit
                                </button>
                                <button
                                  type="button"
                                  onClick={() => handleDeleteArrayItem(groupItems, idx)}
                                  className="action-button delete-button small-button"
                                >
                                  Delete
                                </button>
                              </td>
                            </tr>
                          ))
                        )}
                      </tbody>
                    </table>
                  </div>
                );
              })}

              <div className="form-actions-bar">
                <button onClick={handleSave} className="action-button primary">
                  Save & Recalculate
                </button>
                <button onClick={onClose} className="action-button secondary">
                  Cancel
                </button>
              </div>
            </div>
          )}
        </div>

        {showArrayItemDialog && (
          <WorksheetArrayItemDialog
            open={true}
            groupedItems={groupedItemsForDialog}
            initialValues={initialArrayItemValue}
            isEditing={editingArrayIndex !== -1}
            onSave={handleSaveArrayItem}
            onClose={() => setShowArrayItemDialog(false)}
          />
        )}
      </DetailViewContent>
    </DetailView>
  );
};

export default WorksheetValuesDetailView;
