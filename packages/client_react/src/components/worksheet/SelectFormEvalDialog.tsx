import React, { useState, useEffect } from 'react';
import { Dialog, DialogHeader, DialogContent, DialogFooter } from '@/components/common/ui';
import styles from './SelectFormEvalDialog.module.css';

interface FormEvalOption {
  id: number;
  label: string;
}

interface Props {
  open: boolean;
  title?: string;
  options: FormEvalOption[];
  selectedId?: number | null;
  onSelect: (id: number) => void;
  onClose: () => void;
}

const SelectFormEvalDialog: React.FC<Props> = ({
  open,
  title = "Select Form Eval to Import",
  options,
  selectedId: initialSelectedId,
  onSelect,
  onClose
}) => {
  const [selectedId, setSelectedId] = useState<number | null>(null);

  useEffect(() => {
    if (open) {
      if (initialSelectedId !== null && initialSelectedId !== undefined && options.some(o => o.id === initialSelectedId)) {
        setSelectedId(initialSelectedId);
      } else if (options.length > 0) {
        setSelectedId(options[0].id);
      } else {
        setSelectedId(null);
      }
    }
  }, [open, options, initialSelectedId]);

  const handleSelect = () => {
    if (selectedId !== null) {
      onSelect(selectedId);
    }
  };

  return (
    <Dialog open={open} onClose={onClose} className={styles.wideDialog}>
      <DialogHeader>
        <h3>{title}</h3>
      </DialogHeader>
      <DialogContent>
        <div className={styles.evalList}>
          {options.length === 0 ? (
            <p>No validated and not cancelled form evaluations available.</p>
          ) : (
            options.map((opt) => (
              <div key={opt.id} className={styles.radioItem}>
                <input
                  type="radio"
                  id={`eval-opt-${opt.id}`}
                  name="formEvalSelection"
                  checked={selectedId === opt.id}
                  onChange={() => setSelectedId(opt.id)}
                />
                <label htmlFor={`eval-opt-${opt.id}`}>{opt.label}</label>
              </div>
            ))
          )}
        </div>
      </DialogContent>
      <DialogFooter>
        <button 
          onClick={handleSelect} 
          className="action-button primary" 
          disabled={selectedId === null || options.length === 0}
        >
          Import
        </button>
        <button onClick={onClose} className="action-button secondary">Cancel</button>
      </DialogFooter>
    </Dialog>
  );
};

export default SelectFormEvalDialog;
