import React, { useState } from 'react';
import { 
  Dialog, 
  DialogHeader, 
  DialogContent, 
  DialogFooter 
} from '../common/ui';
import styles from './CertificateSubmitDialog.module.css';

interface Props {
  open: boolean;
  analysisMessage: string;
  isConformingSpec: boolean;
  onClose: () => void;
  onConfirm: (comment: string) => void;
}

const CertificateSubmitDialog: React.FC<Props> = ({ 
  open, 
  analysisMessage, 
  isConformingSpec, 
  onClose, 
  onConfirm 
}) => {
  const [userComment, setUserComment] = useState('');

  const handleConfirm = () => {
    const finalComment = `${analysisMessage}\n------------\n${userComment}`;
    onConfirm(finalComment);
  };

  return (
    <Dialog open={open} onClose={onClose}>
      <DialogHeader>
        <h2>Submit Certificate</h2>
      </DialogHeader>
      <DialogContent>
        <div className={`${styles.analysisSummary} ${isConformingSpec ? styles.conforming : styles.nonConforming}`}>
          <h4>Analysis Results:</h4>
          <div className={styles.analysisText}>{analysisMessage}</div>
        </div>
        <div className={styles.userComments}>
          <label>Additional Comments:</label>
          <textarea 
            value={userComment}
            onChange={(e) => setUserComment(e.target.value)}
            placeholder="Enter your additional comments here..."
            rows={4}
            className="form-control"
          ></textarea>
        </div>
      </DialogContent>
      <DialogFooter>
        <button type="button" onClick={handleConfirm} className="action-button primary">Confirm Submission</button>
        <button type="button" onClick={onClose} className="action-button secondary">Cancel</button>
      </DialogFooter>
    </Dialog>
  );
};

export default CertificateSubmitDialog;
