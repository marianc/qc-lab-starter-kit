import React, { useState, useEffect } from 'react';
import { Dialog, DialogHeader, DialogContent, DialogFooter } from '@/components/common/ui';

interface Props {
  open: boolean;
  title?: string;
  initialComment?: string;
  initialUseDefaultEquipment?: boolean;
  onClose: () => void;
  onSubmit: (comment: string, useDefaultEquipment: boolean) => void;
}

const MeasurementEditDialog: React.FC<Props> = ({ 
  open, 
  title = "Edit Measurement",
  initialComment = "", 
  initialUseDefaultEquipment = true,
  onClose, 
  onSubmit 
}) => {
  const [comment, setComment] = useState(initialComment);
  const [useDefaultEquipment, setUseDefaultEquipment] = useState(initialUseDefaultEquipment);

  useEffect(() => {
    if (open) {
      setComment(initialComment);
      setUseDefaultEquipment(initialUseDefaultEquipment);
    }
  }, [open, initialComment, initialUseDefaultEquipment]);

  const handleSubmit = () => {
    onSubmit(comment, useDefaultEquipment);
  };

  return (
    <Dialog open={open} onClose={onClose}>
      <DialogHeader>
        <h2>{title}</h2>
      </DialogHeader>
      <DialogContent>
        <div className="form-group" style={{ marginBottom: '1rem' }}>
          <label className="form-label">Comments</label>
          <textarea 
            value={comment}
            onChange={(e) => setComment(e.target.value)}
            placeholder="Enter comments here..."
            rows={5}
            className="form-control"
          />
        </div>
        <div className="form-group checkbox-group" style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
          <input 
            type="checkbox"
            id="useDefaultEquipmentCheckbox"
            checked={useDefaultEquipment}
            onChange={(e) => setUseDefaultEquipment(e.target.checked)}
          />
          <label htmlFor="useDefaultEquipmentCheckbox" className="form-label" style={{ marginBottom: 0, cursor: 'pointer' }}>
            Use Default Equipment
          </label>
        </div>
      </DialogContent>
      <DialogFooter>
        <button onClick={handleSubmit} className="action-button primary">Submit</button>
        <button onClick={onClose} className="action-button secondary">Cancel</button>
      </DialogFooter>
    </Dialog>
  );
};

export default MeasurementEditDialog;
