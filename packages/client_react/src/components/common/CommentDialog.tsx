import React, { useState, useEffect } from 'react';
import { Dialog, DialogHeader, DialogContent, DialogFooter } from './ui';

interface Props {
  open: boolean;
  title?: string;
  initialValue?: string;
  onClose: () => void;
  onSubmit: (comment: string) => void;
}

const CommentDialog: React.FC<Props> = ({ 
  open, 
  title = "Enter Comment",
  initialValue = "", 
  onClose, 
  onSubmit 
}) => {
  const [comment, setComment] = useState(initialValue);

  useEffect(() => {
    if (open) {
      setComment(initialValue);
    }
  }, [open, initialValue]);

  const handleSubmit = () => {
    onSubmit(comment);
    setComment("");
  };

  return (
    <Dialog open={open} onClose={onClose}>
      <DialogHeader>
        <h2>{title}</h2>
      </DialogHeader>
      <DialogContent>
        <textarea 
          value={comment}
          onChange={(e) => setComment(e.target.value)}
          placeholder="Enter your comment here..."
          rows={5}
          className="form-control"
        />
      </DialogContent>
      <DialogFooter>
        <button onClick={handleSubmit} className="action-button primary">Submit</button>
        <button onClick={onClose} className="action-button secondary">Cancel</button>
      </DialogFooter>
    </Dialog>
  );
};

export default CommentDialog;
