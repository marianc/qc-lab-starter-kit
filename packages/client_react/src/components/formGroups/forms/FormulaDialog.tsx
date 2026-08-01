import React from 'react';
import { Dialog, DialogHeader, DialogContent, DialogFooter } from '../../common/ui';
import styles from './FormulaDialog.module.css';

interface FormulaDialogProps {
  formula: string | null;
  onClose: () => void;
}

const FormulaDialog: React.FC<FormulaDialogProps> = ({ formula, onClose }) => {
  return (
    <Dialog open={!!formula} onClose={onClose}>
      <DialogHeader>
        Formula View
      </DialogHeader>
      <DialogContent>
        <div className={styles.formulaContainer}>
          {formula}
        </div>
      </DialogContent>
      <DialogFooter>
        <button type="button" className="action-button secondary" onClick={onClose}>Close</button>
      </DialogFooter>
    </Dialog>
  );
};

export default FormulaDialog;
