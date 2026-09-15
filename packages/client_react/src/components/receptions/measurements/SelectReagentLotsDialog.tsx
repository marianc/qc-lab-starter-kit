import React, { useState, useEffect } from 'react';
import { Dialog, DialogHeader, DialogContent, DialogFooter } from '@/components/common/ui';
import type { MeasurementApplicableReagentLotDto } from '@/types/measurement';
import styles from './SelectReagentLotsDialog.module.css';

interface Props {
  open: boolean;
  title?: string;
  items: MeasurementApplicableReagentLotDto[];
  onSave: (selectedControlCodeIds: number[]) => void;
  onClose: () => void;
  idPrefix?: string;
}

const SelectReagentLotsDialog: React.FC<Props> = ({
  open,
  title = "Manage Reagent Lots",
  items,
  onSave,
  onClose,
  idPrefix = "select-reagent-lot"
}) => {
  const [selectedIds, setSelectedIds] = useState<number[]>([]);

  useEffect(() => {
    if (open) {
      const initial: number[] = [];
      items.forEach(reagent => {
        reagent.lots.forEach(lot => {
          if (lot.isSelected) {
            initial.push(lot.controlCodeId);
          }
        });
      });
      setSelectedIds(initial);
    }
  }, [open, items]);

  const handleCheckboxChange = (controlCodeId: number, checked: boolean) => {
    if (checked) {
      setSelectedIds(prev => [...prev, controlCodeId]);
    } else {
      setSelectedIds(prev => prev.filter(id => id !== controlCodeId));
    }
  };

  const handleSave = () => {
    onSave(selectedIds);
  };

  const formatDate = (dateStr: string) => {
    if (!dateStr) return '';
    const parts = dateStr.split('-');
    if (parts.length === 3) {
      return `${parts[2]}.${parts[1]}.${parts[0]}`;
    }
    return dateStr;
  };

  const todayStr = new Date().toISOString().split('T')[0];

  return (
    <Dialog open={open} onClose={onClose}>
      <DialogHeader>
        <h3>{title}</h3>
      </DialogHeader>
      <DialogContent>
        <div className={styles.formGroupList}>
          {items.map(reagent => {
            const isEmptyLots = reagent.lots.length === 0;
            return (
              <div key={reagent.materialId} className={styles.reagentSection}>
                <h4 className={styles.reagentTitle}>
                  {reagent.materialName}
                </h4>
                {isEmptyLots ? (
                  <p className={styles.alertMessage}>
                    The reagent used is not properly configured
                  </p>
                ) : (
                  reagent.lots.map(lot => {
                    const isChecked = selectedIds.includes(lot.controlCodeId);
                    const isActive = lot.statusId === 2;
                    const isExpired = isActive && lot.expirationDate < todayStr;
                    const isNoLongerActive = !isActive;

                    let labelSuffix = '';
                    if (isExpired) {
                      labelSuffix = ` (Exp: ${formatDate(lot.expirationDate)})`;
                    } else if (isNoLongerActive) {
                      labelSuffix = ' (no longer active)';
                    }

                    return (
                      <div key={lot.controlCodeId} className={styles.checkboxItem}>
                        <input 
                          type="checkbox"
                          id={`${idPrefix}-${lot.controlCodeId}`}
                          checked={isChecked}
                          disabled={isNoLongerActive}
                          onChange={(e) => handleCheckboxChange(lot.controlCodeId, e.target.checked)}
                        />
                        <label 
                          htmlFor={`${idPrefix}-${lot.controlCodeId}`} 
                          className={isNoLongerActive ? styles.inactiveLabel : undefined}
                        >
                          {lot.controlCode}{labelSuffix}
                        </label>
                      </div>
                    );
                  })
                )}
              </div>
            );
          })}
          {items.length === 0 && <p className={styles.emptyMessage}>No unique reagents found for current tests.</p>}
        </div>
      </DialogContent>
      <DialogFooter>
        <button onClick={handleSave} className="action-button primary">Save</button>
        <button onClick={onClose} className="action-button secondary">Cancel</button>
      </DialogFooter>
    </Dialog>
  );
};

export default SelectReagentLotsDialog;
