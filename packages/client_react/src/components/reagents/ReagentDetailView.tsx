import React, { useState, useEffect } from 'react';
import { 
  DetailView, 
  DetailViewHeader, 
  DetailViewContent, 
  DetailContainer, 
  DetailColumn, 
  DetailItem 
} from '../common/ui';
import { 
  ConfirmationDialog, 
  CommentDialog 
} from '../common';
import ReagentDialog from './ReagentDialog';
import SupplierLotDialog from './SupplierLotDialog';
import ProductionLotDialog from './ProductionLotDialog';
import styles from './ReagentDetailView.module.css';
import type { ReagentDto, ReagentLotDto } from '@/types/reagent';
import reagentsService from '@/services/reagentsService';
import { formatDate } from '@/lib/utils';

interface ReagentDetailViewProps {
  reagentId: number;
  onClose: (savedId?: number | null) => void;
  onReagentUpdated?: (updatedReagent: ReagentDto) => void;
  breadcrumbs?: string[];
}

const ReagentDetailView: React.FC<ReagentDetailViewProps> = ({ 
  reagentId, 
  onClose, 
  onReagentUpdated,
  breadcrumbs = []
}) => {
  const [reagent, setReagent] = useState<ReagentDto | null>(null);
  const [lots, setLots] = useState<ReagentLotDto[]>([]);
  const [showEditDialog, setShowEditDialog] = useState(false);
  const [showSupplierLotDialog, setShowSupplierLotDialog] = useState(false);
  const [showProductionLotDialog, setShowProductionLotDialog] = useState(false);
  const [editingLot, setEditingLot] = useState<ReagentLotDto | null>(null);
  const [showConfirmationDialog, setShowConfirmationDialog] = useState(false);
  const [showDeactivateCommentDialog, setShowDeactivateCommentDialog] = useState(false);

  const fetchReagentData = async () => {
    try {
      const data = await reagentsService.getReagent(reagentId);
      setReagent(data);
      if (onReagentUpdated) {
        onReagentUpdated(data);
      }
      const lotsData = await reagentsService.getReagentLots(reagentId);
      setLots(lotsData);
    } catch (err) {
      console.error('Failed to fetch reagent data', err);
    }
  };

  useEffect(() => {
    fetchReagentData();
  }, [reagentId]);

  const handleEditDialogClose = (savedId?: number | null) => {
    setShowEditDialog(false);
    if (savedId) {
      fetchReagentData();
    }
  };

  const handleSupplierLotDialogClose = (saved?: boolean) => {
    setShowSupplierLotDialog(false);
    setEditingLot(null);
    if (saved) {
      fetchReagentData();
    }
  };

  const handleProductionLotDialogClose = (saved?: boolean) => {
    setShowProductionLotDialog(false);
    setEditingLot(null);
    if (saved) {
      fetchReagentData();
    }
  };

  const handleOpenEditLot = (lot: ReagentLotDto) => {
    setEditingLot(lot);
    if (lot.isProduced) {
      setShowProductionLotDialog(true);
    } else {
      setShowSupplierLotDialog(true);
    }
  };

  const handleToggleStatusClick = () => {
    if (!reagent) return;
    if (reagent.isObsolete) {
      setShowConfirmationDialog(true);
    } else {
      setShowDeactivateCommentDialog(true);
    }
  };

  const handleConfirmActivation = async () => {
    try {
      await reagentsService.toggleObsolete(reagentId, { isObsolete: false });
      setShowConfirmationDialog(false);
      fetchReagentData();
    } catch (err) {
      console.error('Failed to activate reagent', err);
    }
  };

  const handleDeactivateSubmit = async (comment: string) => {
    try {
      await reagentsService.toggleObsolete(reagentId, { isObsolete: true, comments: comment });
      setShowDeactivateCommentDialog(false);
      fetchReagentData();
    } catch (err) {
      console.error('Failed to deactivate reagent', err);
    }
  };

  if (!reagent) return null;

  return (
    <DetailView>
      <DetailViewHeader 
        title={`Reagent ${reagent.id}`} 
        onBack={() => onClose(reagentId)} 
        breadcrumbs={breadcrumbs} 
      />
      <DetailViewContent>
        <div className="page-container">
          <DetailContainer>
            <DetailColumn>
              <DetailItem label="Name" value={reagent.name} />
              <DetailItem label="Code" value={reagent.code} />
              <DetailItem label="CAS Number" value={reagent.casNumber || "-"} />
              <DetailItem label="Description" value={reagent.description || "-"} />
              <DetailItem label="Norm" value={reagent.normName || "N/A"} />
              <DetailItem label="Date Created" value={formatDate(reagent.dateCreated)} />
              <DetailItem label="Is Obsolete" value={reagent.isObsolete ? "Yes" : "No"} />
              <DetailItem label="Date Obsolete" value={formatDate(reagent.dateObsolete)} />
              {reagent.isObsolete && reagent.commentsObsolete && (
                <DetailItem label="Obsolete Comment" value={reagent.commentsObsolete} />
              )}
            </DetailColumn>
          </DetailContainer>

          <div className={styles.actionButtons}>
            <button onClick={() => setShowEditDialog(true)} className="action-button edit-button">Edit</button>
            <button 
              onClick={handleToggleStatusClick} 
              className={`action-button ${reagent.isObsolete ? 'secondary' : 'delete-button'}`}
            >
              {reagent.isObsolete ? 'Activate' : 'Deactivate'}
            </button>
          </div>

          <h3 className="section-title">Reagent Lots</h3>
          <div className={styles.lotsActions}>
            <button 
              onClick={() => { setEditingLot(null); setShowSupplierLotDialog(true); }} 
              className="action-button primary"
            >
              Add New Supplier Lot
            </button>
            <button 
              onClick={() => { setEditingLot(null); setShowProductionLotDialog(true); }} 
              className="action-button primary"
            >
              Add New Production Lot
            </button>
          </div>

          <table className="data-table">
            <thead>
              <tr>
                <th>Control Code</th>
                <th>Type</th>
                <th>Status</th>
                <th>Quantity</th>
                <th>Unit</th>
                <th>Expiration Date</th>
                <th>Supplier / Produced By</th>
                <th>Lot / Reference</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {lots.length === 0 ? (
                <tr>
                  <td colSpan={9} style={{ textAlign: 'center' }}>No lots registered for this reagent.</td>
                </tr>
              ) : (
                lots.map(lot => {
                  const isExpired = new Date(lot.expirationDate) < new Date();
                  return (
                    <tr key={lot.controlCodeId}>
                      <td><strong>{lot.controlCode}</strong></td>
                      <td>{lot.isProduced ? "Production" : "Supplier"}</td>
                      <td>
                        <span className={`status-badge ${lot.statusName.toLowerCase()}`}>
                          {lot.statusName}
                        </span>
                      </td>
                      <td>{lot.quantity}</td>
                      <td>{lot.unitName || "-"}</td>
                      <td style={{ color: isExpired ? '#dc3545' : 'inherit', fontWeight: isExpired ? 'bold' : 'normal' }}>
                        {lot.expirationDate}
                      </td>
                      <td>
                        {lot.isProduced ? (lot.producedByUserTag || "-") : (lot.supplier || "-")}
                      </td>
                      <td>
                        {lot.isProduced ? (
                          lot.ingredientControlCodes.length > 0 ? (
                            <span>Used: {lot.ingredientControlCodes.join(', ')}</span>
                          ) : "-"
                        ) : (
                          lot.manufacturerLotNumber || "-"
                        )}
                      </td>
                      <td>
                        <button 
                          onClick={() => handleOpenEditLot(lot)} 
                          className="action-button edit-button small-button"
                        >
                          Edit
                        </button>
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>
      </DetailViewContent>

      {showEditDialog && (
        <ReagentDialog 
          open={true} 
          reagentId={reagentId} 
          onClose={handleEditDialogClose} 
        />
      )}

      {showSupplierLotDialog && (
        <SupplierLotDialog 
          open={true}
          reagentId={reagentId}
          lot={editingLot}
          onClose={handleSupplierLotDialogClose}
        />
      )}

      {showProductionLotDialog && (
        <ProductionLotDialog 
          open={true}
          reagentId={reagentId}
          lot={editingLot}
          onClose={handleProductionLotDialogClose}
        />
      )}

      {showConfirmationDialog && (
        <ConfirmationDialog 
          open={true}
          title="Confirm Reagent Activation"
          message={`Are you sure you want to activate reagent ${reagent.name}?`}
          onConfirm={handleConfirmActivation}
          onCancel={() => setShowConfirmationDialog(false)}
        />
      )}

      {showDeactivateCommentDialog && (
        <CommentDialog 
          open={true}
          onSubmit={handleDeactivateSubmit}
          onClose={() => setShowDeactivateCommentDialog(false)}
        />
      )}
    </DetailView>
  );
};

export default ReagentDetailView;