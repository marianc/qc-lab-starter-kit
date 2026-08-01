import React from 'react';
import { Dialog, DialogHeader, DialogContent, DialogFooter } from './ui';

interface Props {
  open: boolean;
  title?: string;
  message?: string;
  onClose: () => void;
}

const NotificationDialog: React.FC<Props> = ({ 
  open, 
  title = "Notification", 
  message = "", 
  onClose 
}) => {
  return (
    <Dialog open={open} onClose={onClose}>
      <DialogHeader>
        <h3>{title}</h3>
      </DialogHeader>
      <DialogContent>
        <p>{message}</p>
      </DialogContent>
      <DialogFooter>
        <button onClick={onClose} className="action-button primary">OK</button>
      </DialogFooter>
    </Dialog>
  );
};

export default NotificationDialog;
