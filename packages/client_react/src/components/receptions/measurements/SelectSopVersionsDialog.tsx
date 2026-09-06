import React, { useState, useEffect } from 'react';
import { Dialog, DialogHeader, DialogContent, DialogFooter } from '@/components/common/ui';
import styles from '@/components/common/SelectDialog.module.css';

export interface SopVersionSelectItem {
  id: number;
  sopId: number;
  name: string;
}

interface Props {
  open: boolean;
  title?: string;
  items: SopVersionSelectItem[]; // all versions applicable to current tests
  selectedIds: number[];
  onSave: (selectedIds: number[]) => void;
  onClose: () => void;
  idPrefix?: string;
}

const SelectSopVersionsDialog: React.FC<Props> = ({
  open,
  title = "Select SOP Versions",
  items,
  selectedIds: initialSelectedIds,
  onSave,
  onClose,
  idPrefix = "select-sop-version"
}) => {
  const [selectedIds, setSelectedIds] = useState<number[]>(initialSelectedIds);

  useEffect(() => {
    if (open) {
      setSelectedIds([...initialSelectedIds]);
    }
  }, [open, initialSelectedIds]);

  // Group items by sopId so we can enforce radio-like behavior (only one version per sopId)
  const groupedBySop = items.reduce((acc, item) => {
    if (!acc[item.sopId]) {
      acc[item.sopId] = [];
    }
    acc[item.sopId].push(item);
    return acc;
  }, {} as Record<number, SopVersionSelectItem[]>);

  const handleVersionChange = (sopId: number, versionId: number) => {
    // Remove any existing selected version for this sopId, then add the new one
    const otherSelected = selectedIds.filter(id => {
      const item = items.find(i => i.id === id);
      return item && item.sopId !== sopId;
    });
    setSelectedIds([...otherSelected, versionId]);
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
          {Object.entries(groupedBySop).map(([sopIdStr, versions]) => {
            const sopId = Number(sopIdStr);
            return (
              <div key={sopId} style={{ marginBottom: '1rem', borderBottom: '1px solid #eee', paddingBottom: '0.5rem' }}>
                <h4 style={{ margin: '0 0 0.5rem 0', fontSize: '0.95rem', color: '#333' }}>
                  SOP #{sopId}
                </h4>
                {versions.map((version) => {
                  const isChecked = selectedIds.includes(version.id);
                  return (
                    <div key={version.id} className={styles.checkboxItem} style={{ marginLeft: '1rem' }}>
                      <input 
                        type="radio"
                        name={`sop-group-${sopId}`}
                        id={`${idPrefix}-${version.id}`}
                        checked={isChecked}
                        onChange={() => handleVersionChange(sopId, version.id)}
                      />
                      <label htmlFor={`${idPrefix}-${version.id}`}>{version.name}</label>
                    </div>
                  );
                })}
              </div>
            );
          })}
          {items.length === 0 && <p>No applicable SOP versions found.</p>}
        </div>
      </DialogContent>
      <DialogFooter>
        <button onClick={handleSave} className="action-button primary">Save</button>
        <button onClick={onClose} className="action-button secondary">Cancel</button>
      </DialogFooter>
    </Dialog>
  );
};

export default SelectSopVersionsDialog;
