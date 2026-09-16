import React from 'react';
import { Dialog, DialogHeader, DialogContent, DialogFooter } from './ui';

interface Props {
  open: boolean;
  title?: string;
  message?: React.ReactNode;
  onConfirm: () => void;
  onCancel: () => void;
}

const ConfirmationDialog: React.FC<Props> = ({ 
  open, 
  title = "Confirm", 
  message = "Are you sure?", 
  onConfirm, 
  onCancel 
}) => {
  return (
    <Dialog open={open} onClose={onCancel}>
      <DialogHeader>
        <h3>{title}</h3>
      </DialogHeader>
      <DialogContent>
        <p>{message}</p>
      </DialogContent>
      <DialogFooter>
        <button onClick={onConfirm} className="action-button primary">Confirm</button>
        <button onClick={onCancel} className="action-button secondary">Cancel</button>
      </DialogFooter>
    </Dialog>
  );
};

export default ConfirmationDialog;
