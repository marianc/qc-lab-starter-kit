import React, { useState, useEffect } from 'react';
import { Dialog, DialogHeader, DialogContent, DialogFooter } from './ui';
import styles from './SelectDialog.module.css';
import type { SelectableItem } from '@/types/models';

interface Props {
  open: boolean;
  title?: string;
  items: SelectableItem[];
  selectedIds: number[];
  onSave: (selectedIds: number[]) => void;
  onClose: () => void;
  idPrefix?: string;
}

const SelectDialog: React.FC<Props> = ({ 
  open, 
  title = "Select Items", 
  items, 
  selectedIds: initialSelectedIds, 
  onSave, 
  onClose, 
  idPrefix = "select-item" 
}) => {
  const [selectedIds, setSelectedIds] = useState<number[]>(initialSelectedIds);

  useEffect(() => {
    if (open) {
      setSelectedIds([...initialSelectedIds]);
    }
  }, [open, initialSelectedIds]);

  const handleCheckboxChange = (itemId: number, isChecked: boolean) => {
    if (isChecked) {
      if (!selectedIds.includes(itemId)) {
        setSelectedIds([...selectedIds, itemId]);
      }
    } else {
      setSelectedIds(selectedIds.filter(id => id !== itemId));
    }
  };

  const handleSave = () => {
    onSave(selectedIds);
  };

  return (
    <Dialog open={open} onClose={onClose}>
      <DialogHeader>
        <h3>{title}</h3>
      </DialogHeader>
      <DialogContent>
        <div className={styles.formGroupList}>
          {items.map((item) => (
            <div key={item.id} className={styles.checkboxItem}>
              <input 
                type="checkbox"
                id={`${idPrefix}-${item.id}`}
                checked={selectedIds.includes(item.id)}
                onChange={(e) => handleCheckboxChange(item.id, e.target.checked)}
              />
              <label htmlFor={`${idPrefix}-${item.id}`}>{item.name}</label>
            </div>
          ))}
        </div>
      </DialogContent>
      <DialogFooter>
        <button onClick={handleSave} className="action-button primary">Save</button>
        <button onClick={onClose} className="action-button secondary">Cancel</button>
      </DialogFooter>
    </Dialog>
  );
};

export default SelectDialog;
