import React, { useEffect, useState } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import * as z from 'zod';
import { 
  Dialog, 
  DialogHeader, 
  DialogContent, 
  DialogFooter 
} from '@/components/common/ui';
import styles from './MeasurementTestDialog.module.css';
import type { MeasurementTestDto } from '@/types/measurement';
import type { TestDto } from '@/types/test';
import { measurementSchema } from '@/lib/schemas/reception';

interface Props {
  open: boolean;
  test?: MeasurementTestDto;
  availableTests: { id: number, name: string }[];
  allTests: TestDto[];
  onSave: (test: MeasurementTestDto) => void;
  onClose: () => void;
  isEditMode?: boolean;
}

type FormData = z.infer<typeof measurementSchema>;

const MeasurementTestDialog: React.FC<Props> = ({ 
  open, 
  test: initialTest, 
  availableTests, 
  allTests, 
  onSave, 
  onClose, 
  isEditMode 
}) => {
  const [arrayValues, setArrayValues] = useState<any[]>([]);
  const [newArrayValue, setNewArrayValue] = useState<any>('');
  const [editingIndex, setEditingIndex] = useState<number | null>(null);
  const [draggedItemIndex, setDraggedItemIndex] = useState<number | null>(null);
  const [isDragHandleActive, setIsDragHandleActive] = useState(false);

  const { register, handleSubmit, watch, setValue, reset, formState: { errors } } = useForm<FormData>({
    resolver: zodResolver(measurementSchema) as any,
    defaultValues: {
      testId: initialTest?.testId || 0,
      note: initialTest?.note || '',
      value: initialTest?.value ?? ''
    }
  });

  const watchTestId = watch('testId');
  const testDetails = allTests.find(t => t.id === watchTestId);
  const isArray = testDetails?.isArray || false;

  useEffect(() => {
    if (open) {
      const tid = initialTest?.testId || 0;
      const details = allTests.find(t => t.id === tid);
      const isArr = details?.isArray || false;

      const initialValue = initialTest?.value;
      let initialArray: any[] = [];
      if (isArr && initialValue) {
        const raw = Array.isArray(initialValue) ? initialValue : [initialValue];
        initialArray = raw.map(v => {
          if (details?.typeId === 1 || details?.typeId === 2 || details?.typeId === 3 || details?.typeId === 4) {
            const num = parseFloat(v);
            return isNaN(num) ? v : num;
          }
          return v;
        });
      }
      setArrayValues(initialArray);
      setNewArrayValue('');
      setEditingIndex(null);
      
      reset({
        testId: tid,
        note: initialTest?.note || '',
        value: initialTest?.value ?? ''
      });
    }
  }, [open, initialTest, reset, allTests]);

  const onTestChanged = (e: React.ChangeEvent<HTMLSelectElement>) => {
    const val = parseInt(e.target.value);
    setValue('testId', val);
    setArrayValues([]);
    setValue('value', '');
  };

  const addArrayValue = () => {
    if (newArrayValue.toString().trim() === '') return;
    
    let finalVal: any = newArrayValue;
    if (testDetails?.typeId === 1 || testDetails?.typeId === 2) {
      const num = parseFloat(newArrayValue);
      if (!isNaN(num)) finalVal = num;
    } else if (testDetails?.typeId === 3 || testDetails?.typeId === 4) {
      const num = parseInt(newArrayValue);
      if (!isNaN(num)) finalVal = num;
    }

    const newArr = [...arrayValues];
    if (editingIndex !== null) {
      newArr[editingIndex] = finalVal;
      setEditingIndex(null);
    } else {
      newArr.push(finalVal);
    }

    setArrayValues(newArr);
    setValue('value', newArr, { shouldValidate: true });
    setNewArrayValue('');
  };

  const editArrayItem = (index: number) => {
    setEditingIndex(index);
    setNewArrayValue(arrayValues[index]);
  };

  const removeArrayValue = (index: number) => {
    if (editingIndex === index) {
      setEditingIndex(null);
      setNewArrayValue('');
    }
    const newArr = arrayValues.filter((_, i) => i !== index);
    setArrayValues(newArr);
    setValue('value', newArr, { shouldValidate: true });
  };

  const handleDragStart = (index: number) => {
    if (!isDragHandleActive) return;
    setDraggedItemIndex(index);
  };

  const handleDragEnter = (index: number) => {
    if (draggedItemIndex === null || draggedItemIndex === index) return;
    const newArr = [...arrayValues];
    const draggedItem = newArr[draggedItemIndex];
    newArr.splice(draggedItemIndex, 1);
    newArr.splice(index, 0, draggedItem);
    setDraggedItemIndex(index);
    setArrayValues(newArr);
    setValue('value', newArr);
  };

  const handleDragEnd = () => {
    setDraggedItemIndex(null);
    setIsDragHandleActive(false);
  };

  const onSubmit = (data: FormData) => {
    let finalValue = isArray ? arrayValues : data.value;
    
    if (!isArray && testDetails) {
      if (testDetails.typeId === 1 || testDetails.typeId === 2) {
        const num = parseFloat(finalValue);
        if (!isNaN(num)) finalValue = num;
      } else if (testDetails.typeId === 3 || testDetails.typeId === 4) {
        const num = parseInt(finalValue);
        if (!isNaN(num)) finalValue = num;
      }
    }

    // Final check for empty array
    if (isArray && (!arrayValues || arrayValues.length === 0)) {
      return; // Zod refine should handle this, but being safe
    }

    onSave({
      testId: data.testId,
      value: finalValue,
      note: data.note || ''
    });
  };

  const getDisplayValue = (val: any) => {
    if (!testDetails) return val?.toString() || '';
    if (testDetails.typeId === 3) return val === 1 || val === true || val.toString() === '1' ? 'Yes' : 'No';
    if (testDetails.typeId === 4 && testDetails.enums) {
      const entry = testDetails.enums.find(e => e.value.toString() === val.toString());
      return entry ? entry.name : val.toString();
    }
    return val?.toString() || '';
  };

  const renderControl = (isNewVal: boolean) => {
    if (!testDetails) return <input type="text" className="form-control" disabled />;

    if (isNewVal) {
      // For adding new items to an array - controlled by local state
      const value = newArrayValue;
      const onChange = (e: React.ChangeEvent<any>) => setNewArrayValue(e.target.value);

      switch (testDetails.typeId) {
        case 1: // Integer
          return <input type="number" step="1" value={value} onChange={onChange} className="form-control" />;
        case 2: // Real
          return <input type="number" step="any" value={value} onChange={onChange} className="form-control" />;
        case 3: // Boolean
          return (
            <select value={value} onChange={onChange} className="form-control">
              <option value="">-- Select --</option>
              <option value="1">Yes</option>
              <option value="0">No</option>
            </select>
          );
        case 4: // Enum
          return (
            <select value={value} onChange={onChange} className="form-control">
              <option value="">-- Select --</option>
              {testDetails.enums?.map(e => (
                <option key={e.value} value={e.value}>{e.name}</option>
              ))}
            </select>
          );
        default:
          return <input type="text" value={value} onChange={onChange} className="form-control" />;
      }
    } else {
      // For scalar value mode - registered with react-hook-form
      switch (testDetails.typeId) {
        case 1: // Integer
          return <input type="number" step="1" className="form-control" {...register('value')} />;
        case 2: // Real
          return <input type="number" step="any" className="form-control" {...register('value')} />;
        case 3: // Boolean
          return (
            <select className="form-control" {...register('value')}>
              <option value="">-- Select --</option>
              <option value="1">Yes</option>
              <option value="0">No</option>
            </select>
          );
        case 4: // Enum
          return (
            <select className="form-control" {...register('value')}>
              <option value="">-- Select --</option>
              {testDetails.enums?.map(e => (
                <option key={e.value} value={e.value}>{e.name}</option>
              ))}
            </select>
          );
        default:
          return <input type="text" className="form-control" {...register('value')} />;
      }
    }
  };

  return (
    <Dialog open={open} onClose={onClose}>
      <DialogHeader>
        <h2>Measurement Test Dialog</h2>
      </DialogHeader>
      <DialogContent>
        <form id="measurement-test-form" onSubmit={handleSubmit(onSubmit)}>
          <div className="form-group">
            <label>Test:</label>
            {isEditMode ? (
              <span>{testDetails?.name || 'Unknown'}</span>
            ) : (
              <select 
                className={`form-control ${errors.testId ? 'invalid' : ''}`}
                value={watchTestId}
                onChange={onTestChanged}
              >
                <option value="0">-- Select Test --</option>
                {availableTests.map(t => (
                  <option key={t.id} value={t.id}>{t.name}</option>
                ))}
              </select>
            )}
            {errors.testId && <div className="validation-message">{errors.testId.message}</div>}
          </div>

          {isArray ? (
            <div className="form-group">
              <label>Values (Array):</label>
              {arrayValues.length > 0 && (
                <ul className={`${styles.arrayItemList} item-list`}>
                  {arrayValues.map((val, index) => (
                    <li 
                      key={index}
                      className={`${styles.arrayItem} ${draggedItemIndex === index ? styles.dragging : ''}`}
                      draggable
                      onDragStart={() => handleDragStart(index)}
                      onDragEnter={() => handleDragEnter(index)}
                      onDragOver={(e) => e.preventDefault()}
                      onDragEnd={handleDragEnd}
                    >
                      <span>{getDisplayValue(val)}</span>
                      <div className={styles.arrayItemActions}>
                        <button 
                          type="button" 
                          onClick={() => editArrayItem(index)} 
                          className="action-button edit-button small-button"
                        >
                          Edit
                        </button>
                        <button 
                          type="button" 
                          onClick={() => removeArrayValue(index)} 
                          className="action-button delete-button small-button"
                        >
                          Delete
                        </button>
                        <span 
                          className="drag-handle" 
                          onMouseDown={() => setIsDragHandleActive(true)}
                          onMouseUp={() => setIsDragHandleActive(false)}
                          style={{cursor: 'grab'}}
                        >
                          ⠿
                        </span>
                      </div>
                    </li>
                  ))}
                </ul>
              )}
              <div className={styles.arrayInputContainer}>
                {renderControl(true)}
                <button type="button" onClick={addArrayValue} className="action-button primary small-button">
                  {editingIndex !== null ? 'Update' : 'Add'}
                </button>
                {editingIndex !== null && (
                  <button type="button" onClick={() => { setEditingIndex(null); setNewArrayValue(''); }} className="action-button secondary small-button">
                    Cancel
                  </button>
                )}
              </div>
            </div>
          ) : (
            <div className="form-group">
              <label>Value:</label>
              {renderControl(false)}
              {errors.value && <div className="validation-message">{String(errors.value.message)}</div>}
            </div>
          )}

          <div className="form-group">
            <label htmlFor="note">Note:</label>
            <textarea id="note" className="form-control" {...register('note')} />
          </div>
        </form>
      </DialogContent>
      <DialogFooter>
        <button type="submit" form="measurement-test-form" className="action-button primary">Save</button>
        <button type="button" onClick={onClose} className="action-button secondary">Cancel</button>
      </DialogFooter>
    </Dialog>
  );
};

export default MeasurementTestDialog;
