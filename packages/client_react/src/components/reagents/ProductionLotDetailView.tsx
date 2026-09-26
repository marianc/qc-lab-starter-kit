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
import ProductionLotDialog from './ProductionLotDialog';
import styles from './ReagentDetailView.module.css';

interface ProductionLotDetailViewProps {
  controlCodeId: number;
  reagentId: number;
  onClose: () => void;
  onLotUpdated?: (controlCodeId: number) => void;
  breadcrumbs?: string[];
}

const ProductionLotDetailView: React.FC<ProductionLotDetailViewProps> = ({
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
      console.error('Failed to fetch production lot details', err);
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
        title={`Production Lot ${lot.controlCodeId}`}
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
              <DetailItem label="Produced By" value={lot.producedByUserTag || '-'} />
              <DetailItem label="Ingredients">
                {lot.ingredientControlCodes && lot.ingredientControlCodes.length > 0 ? (
                  <div>
                    {lot.ingredientControlCodes.map((code, idx) => {
                      const matName = lot.ingredientMaterialCodes?.[idx] || '';
                      return { code, matName };
                    }).sort((a, b) => a.matName.localeCompare(b.matName)).map(({ code, matName }) => (
                      <div key={code}>
                        {matName} ({code})
                      </div>
                    ))}
                  </div>
                ) : (
                  '-'
                )}
              </DetailItem>
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
        <ProductionLotDialog 
          open={true}
          reagentId={reagentId}
          lot={lot}
          onClose={handleEditDialogClose}
        />
      )}
    </DetailView>
  );
};

export default ProductionLotDetailView;
