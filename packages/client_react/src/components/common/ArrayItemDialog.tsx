import React, { useState, useEffect } from 'react';
import { Dialog, DialogHeader, DialogContent, DialogFooter } from './ui';
import type { FormParamDto } from '@/types/form';
import type { TestEnumDto } from '@/types/test';

interface ArrayItemDialogProps {
  open: boolean;
  groupedParams: FormParamDto[];
  initialValues: Record<string, any>;
  allFormParamEnums: TestEnumDto[];
  isEditing: boolean;
  onSave: (values: Record<string, any>) => void;
  onClose: () => void;
}

const ArrayItemDialog: React.FC<ArrayItemDialogProps> = ({
  open,
  groupedParams,
  initialValues,
  allFormParamEnums,
  isEditing,
  onSave,
  onClose
}) => {
  const [itemValues, setItemValues] = useState<Record<string, any>>({});

  useEffect(() => {
    if (open) {
      const vals = { ...initialValues };
      groupedParams.forEach(p => {
        if (vals[p.code] === undefined) vals[p.code] = null;
      });
      setItemValues(vals);
    }
  }, [open, initialValues, groupedParams]);

  const handleChange = (code: string, val: any) => {
    setItemValues(prev => ({
      ...prev,
      [code]: val === "" ? null : val
    }));
  };

  const getEnumsForParam = (testId: number) => {
    return allFormParamEnums.filter(e => e.testId === testId);
  };

  const handleSubmit = () => {
    const finalValues = { ...itemValues };
    groupedParams.forEach(p => {
      const val = finalValues[p.code];
      if (val !== null && val !== undefined && val !== '') {
        if (p.typeId === 1 || p.typeId === 2) {
          const num = parseFloat(String(val));
          if (!isNaN(num)) finalValues[p.code] = num;
        } else if (p.typeId === 3 || p.typeId === 4) {
          const num = parseInt(String(val));
          if (!isNaN(num)) finalValues[p.code] = num;
        }
      }
    });
    onSave(finalValues);
  };

  return (
    <Dialog open={open} onClose={onClose}>
      <DialogHeader>
        <h2>{isEditing ? "Edit" : "Add"} Array Item</h2>
      </DialogHeader>
      <DialogContent>
        {groupedParams.map(param => (
          <div key={param.testId} className="form-group">
            <label htmlFor={param.code}>{param.name}:</label>
            {param.typeId === 1 || param.typeId === 2 ? (
              <input 
                type="number" 
                id={param.code} 
                className="form-control" 
                step={param.typeId === 2 ? "any" : "1"}
                value={itemValues[param.code] ?? ""}
                onChange={e => handleChange(param.code, e.target.value)}
              />
            ) : param.typeId === 3 ? (
              <select 
                id={param.code} 
                className="form-control"
                value={itemValues[param.code] ?? ""}
                onChange={e => handleChange(param.code, e.target.value)}
              >
                <option value="">-- No Selection --</option>
                <option value="1">Yes</option>
                <option value="0">No</option>
              </select>
            ) : param.typeId === 4 ? (
              <select 
                id={param.code} 
                className="form-control"
                value={itemValues[param.code] ?? ""}
                onChange={e => handleChange(param.code, e.target.value)}
              >
                <option value="">-- Select --</option>
                {getEnumsForParam(param.testId).map(enumItem => (
                  <option key={enumItem.value} value={enumItem.value}>{enumItem.name}</option>
                ))}
              </select>
            ) : (
              <input 
                type="text" 
                id={param.code} 
                className="form-control"
                value={itemValues[param.code] ?? ""}
                onChange={e => handleChange(param.code, e.target.value)}
              />
            )}
          </div>
        ))}
      </DialogContent>
      <DialogFooter>
        <button onClick={handleSubmit} className="action-button primary">Save</button>
        <button onClick={onClose} className="action-button secondary">Cancel</button>
      </DialogFooter>
    </Dialog>
  );
};

export default ArrayItemDialog;