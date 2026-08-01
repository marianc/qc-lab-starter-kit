import React, { useState, useEffect } from 'react';
import { Dialog, DialogHeader, DialogContent, DialogFooter } from '../common/ui';

interface Props {
  open: boolean;
  onClose: () => void;
  onSubmit: (password: string) => void;
  userId: number;
  userName: string;
}

const ResetPasswordDialog: React.FC<Props> = ({ 
  open, 
  onClose, 
  onSubmit, 
  userId, 
  userName 
}) => {
  const [newPassword, setNewPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (open) {
      setNewPassword("");
      setConfirmPassword("");
      setError(null);
    }
  }, [open]);

  const handleSave = () => {
    if (!newPassword) {
      setError("Password is required");
      return;
    }
    if (newPassword !== confirmPassword) {
      setError("Passwords do not match");
      return;
    }
    
    onSubmit(newPassword);
  };

  return (
    <Dialog open={open} onClose={onClose}>
      <DialogHeader>Reset Password for {userName}</DialogHeader>
      <DialogContent>
        <div className="form-group">
          <label>New Password</label>
          <input 
            type="password" 
            value={newPassword} 
            onChange={(e) => setNewPassword(e.target.value)} 
            className="form-control" 
          />
        </div>
        <div className="form-group">
          <label>Confirm Password</label>
          <input 
            type="password" 
            value={confirmPassword} 
            onChange={(e) => setConfirmPassword(e.target.value)} 
            className="form-control" 
          />
        </div>
        {error && <div style={{ color: 'red', marginTop: '0.5rem' }}>{error}</div>}
      </DialogContent>
      <DialogFooter>
        <button onClick={handleSave} className="action-button primary">Save</button>
        <button onClick={onClose} className="action-button secondary">Cancel</button>
      </DialogFooter>
    </Dialog>
  );
};

export default ResetPasswordDialog;
