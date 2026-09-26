import React, { useState, useEffect } from 'react';
import { 
  DetailView, 
  DetailViewHeader, 
  DetailViewContent, 
  DetailContainer, 
  DetailColumn, 
  DetailItem 
} from '../common/ui';
import type { ReagentLotDto } from '@/types/reagent';
import reagentsService from '@/services/reagentsService';
import { formatDate } from '@/lib/utils';
import SupplierLotDialog from './SupplierLotDialog';
import styles from './ReagentDetailView.module.css';

interface SupplierLotDetailViewProps {
  controlCodeId: number;
  reagentId: number;
  onClose: () => void;
  onLotUpdated?: (controlCodeId: number) => void;
  breadcrumbs?: string[];
}

const SupplierLotDetailView: React.FC<SupplierLotDetailViewProps> = ({
  controlCodeId,
  reagentId,
  onClose,
  onLotUpdated,
  breadcrumbs = []
}) => {
  const [lot, setLot] = useState<ReagentLotDto | null>(null);
  const [showEditDialog, setShowEditDialog] = useState(false);

  const fetchLot = async () => {
    try {
      const data = await reagentsService.getReagentLot(controlCodeId);
      setLot(data);
    } catch (err) {
      console.error('Failed to fetch supplier lot details', err);
    }
  };

  useEffect(() => {
    fetchLot();
  }, [controlCodeId]);

  const handleEditDialogClose = (savedId?: number | null) => {
    setShowEditDialog(false);
    if (savedId) {
      fetchLot();
      if (onLotUpdated) {
        onLotUpdated(savedId);
      }
    }
  };

  if (!lot) return null;

  return (
    <DetailView>
      <DetailViewHeader 
        title={`Supplier Lot ${lot.controlCodeId}`}
        onBack={onClose}
        breadcrumbs={breadcrumbs}
      />
      <DetailViewContent>
        <div className="page-container">
          <DetailContainer>
            <DetailColumn>
              <DetailItem label="Control Code" value={lot.controlCode} />
              <DetailItem label="Material" value={lot.materialName} />
              <DetailItem label="Status" value={lot.statusName} />
              <DetailItem label="Quantity" value={lot.quantity.toString()} />
              <DetailItem label="Unit" value={lot.unitName || '-'} />
              <DetailItem label="Expiration Date" value={formatDate(lot.expirationDate)} />
              <DetailItem label="Date Created" value={formatDate(lot.dateCreated)} />
            </DetailColumn>
            <DetailColumn>
              <DetailItem label="Supplier" value={lot.supplierName || '-'} />
              <DetailItem label="Catalog Number" value={lot.catalogNumber || '-'} />
              <DetailItem label="Manufacturer Lot Number" value={lot.manufacturerLotNumber || '-'} />
              <DetailItem label="Certificate of Analysis Ref" value={lot.certificateOfAnalysisRef || '-'} />
              <DetailItem label="Comments" value={lot.comments || '-'} />
            </DetailColumn>
          </DetailContainer>

          <div className={styles.actionButtons}>
            <button onClick={() => setShowEditDialog(true)} className="action-button primary">
              Edit
            </button>
          </div>
        </div>
      </DetailViewContent>

      {showEditDialog && (
        <SupplierLotDialog 
          open={true}
          reagentId={reagentId}
          lot={lot}
          onClose={handleEditDialogClose}
        />
      )}
    </DetailView>
  );
};

export default SupplierLotDetailView;
