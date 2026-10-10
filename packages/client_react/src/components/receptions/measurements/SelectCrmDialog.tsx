import React from 'react';
import { Dialog, DialogHeader, DialogContent, DialogFooter } from '@/components/common/ui';
import styles from './SelectCrmDialog.module.css';
import type { FormParamDto } from '@/types/form';
import type { CrmValueItemDto, CrmSelectionDto } from '@/types/measurement';

interface SelectCrmDialogProps {
  open: boolean;
  activeCrmParam: FormParamDto | null;
  crmLoading: boolean;
  crmValues: CrmValueItemDto[];
  crmSelections: Record<string, CrmSelectionDto>;
  onSelect: (item: CrmValueItemDto) => void;
  onClose: () => void;
  getDisplayValue: (param: FormParamDto, val: any) => string;
}

const SelectCrmDialog: React.FC<SelectCrmDialogProps> = ({
  open,
  activeCrmParam,
  crmLoading,
  crmValues,
  crmSelections,
  onSelect,
  onClose,
  getDisplayValue
}) => {
  if (!open || !activeCrmParam) return null;

  return (
    <Dialog open={open} onClose={onClose} className={styles.dialogCrm}>
      <DialogHeader>
        <h2>Select Certified Reference Value for {activeCrmParam.name}</h2>
      </DialogHeader>
      <DialogContent>
        {crmLoading ? (
          <p>Loading certified reference values...</p>
        ) : crmValues.length === 0 ? (
          <p>No certified reference values found for this test.</p>
        ) : (
          <div className={styles.tableContainer}>
            <table className="data-table">
              <thead>
                <tr>
                  <th>Material Name</th>
                  <th>Lot</th>
                  <th>Source</th>
                  <th>Value</th>
                  <th>Action</th>
                </tr>
              </thead>
              <tbody>
                {crmValues.map((item, idx) => {
                  const currentSelection = crmSelections[activeCrmParam.code];
                  const isSelected = currentSelection && (
                    (item.source === 'Cert' && item.certificateId === currentSelection.certifiedReferenceCertificateId) ||
                    (item.source === 'Supplier' && item.controlCodeId === currentSelection.certifiedReferenceControlCodeId)
                  );
                  return (
                    <tr 
                      key={idx} 
                      className={isSelected ? 'highlighted-row' : ''}
                    >
                      <td>{item.materialName}</td>
                      <td>{item.lotCode}</td>
                      <td>{item.source}</td>
                      <td>{getDisplayValue(activeCrmParam, item.value)}</td>
                      <td>
                        <button 
                          type="button" 
                          onClick={() => onSelect(item)}
                          className="action-button primary small-button"
                        >
                          Select
                        </button>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}
      </DialogContent>
      <DialogFooter>
        <button 
          type="button" 
          onClick={onClose} 
          className="action-button secondary"
        >
          Cancel
        </button>
      </DialogFooter>
    </Dialog>
  );
};

export default SelectCrmDialog;
