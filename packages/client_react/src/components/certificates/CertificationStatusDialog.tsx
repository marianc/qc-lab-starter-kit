import React from 'react';
import { 
  Dialog, 
  DialogHeader, 
  DialogContent, 
  DialogFooter 
} from '../common/ui';
import type { CertificationStatusDto } from '@/types/certificationStatus';

interface Props {
  open: boolean;
  items: CertificationStatusDto[];
  onClose: () => void;
  onAddCertificate: (item: CertificationStatusDto) => void;
}

const CertificationStatusDialog: React.FC<Props> = ({ open, items, onClose, onAddCertificate }) => {
  return (
    <Dialog open={open} onClose={onClose}>
      <DialogHeader>
        <h2>Certification Status</h2>
      </DialogHeader>
      <DialogContent>
        <table className="data-table">
          <thead>
            <tr>
              <th>Material</th>
              <th>Control Code</th>
              <th>Status</th>
              <th>Action</th>
            </tr>
          </thead>
          <tbody>
            {items.map((item, index) => (
              <tr key={`${item.materialId}-${item.controlCodeId}-${index}`}>
                <td>{item.materialName}</td>
                <td>{item.controlCode}</td>
                <td>{item.status}</td>
                <td>
                  <button 
                    onClick={() => onAddCertificate(item)} 
                    className="action-button primary small-button"
                  >
                    Add Certificate
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </DialogContent>
      <DialogFooter>
        <button type="button" onClick={onClose} className="action-button secondary">Close</button>
      </DialogFooter>
    </Dialog>
  );
};

export default CertificationStatusDialog;
