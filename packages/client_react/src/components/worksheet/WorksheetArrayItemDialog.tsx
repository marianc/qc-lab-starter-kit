import React, { useState } from 'react';
import {
  Dialog,
  DialogHeader,
  DialogContent,
  DialogFooter
} from '@/components/common/ui';
import type { WorksheetTestItem } from '@/types/worksheet';

export interface WorksheetArrayItemDialogProps {
  open: boolean;
  groupedItems: WorksheetTestItem[];
  initialValues: Record<string, any>;
  isEditing: boolean;
  onSave: (values: Record<string, any>) => void;
  onClose: () => void;
}

export const WorksheetArrayItemDialog: React.FC<WorksheetArrayItemDialogProps> = ({
  open,
  groupedItems,
  initialValues,
  isEditing,
  onSave,
  onClose
}) => {
  const [itemValues, setItemValues] = useState<Record<string, any>>({});

  React.useEffect(() => {
    if (open) {
      const vals = { ...initialValues };
      groupedItems.forEach(item => {
        if (vals[item.id] === undefined) vals[item.id] = null;
      });
      setItemValues(vals);
    }
  }, [open, initialValues, groupedItems]);

  const handleChange = (id: string, val: any) => {
    setItemValues(prev => ({
      ...prev,
      [id]: val === '' ? null : val
    }));
  };

  const handleSubmit = () => {
    const finalValues = { ...itemValues };
    groupedItems.forEach(item => {
      const val = finalValues[item.id];
      if (val !== null && val !== undefined && val !== '') {
        if (item.value_type === 'integer' || item.value_type === 'real') {
          const num = Number(val);
          if (!isNaN(num)) finalValues[item.id] = num;
        } else if (item.value_type === 'enum' && item.enums) {
          const index = item.enums.indexOf(val);
          finalValues[item.id] = index >= 0 ? index + 1 : Number(val);
        } else if (item.value_type === 'boolean') {
          finalValues[item.id] = (val === 'true' || val === true || val === 1 || val === '1' || val === 1.0) ? 1 : 0;
        }
      } else {
        finalValues[item.id] = null;
      }
    });
    onSave(finalValues);
  };

  return (
    <Dialog open={open} onClose={onClose}>
      <DialogHeader>
        <h2>{isEditing ? 'Edit' : 'Add'} Array Item</h2>
      </DialogHeader>
      <DialogContent>
        {groupedItems.map(item => {
          const val = itemValues[item.id];
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
                  onChange={(e) => handleChange(item.id, e.target.value)}
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
                  onChange={(e) => handleChange(item.id, e.target.value === '' ? null : e.target.value)}
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
                  onChange={(e) => handleChange(item.id, e.target.value)}
                />
              )}
            </div>
          );
        })}
      </DialogContent>
      <DialogFooter>
        <button onClick={handleSubmit} className="action-button primary">
          Save
        </button>
        <button onClick={onClose} className="action-button secondary">
          Cancel
        </button>
      </DialogFooter>
    </Dialog>
  );
};

export default WorksheetArrayItemDialog;
