import React, { useEffect, useState, useCallback } from 'react';
import { 
  DetailView, 
  DetailViewHeader, 
  DetailViewContent, 
  DetailContainer, 
  DetailColumn, 
  DetailItem 
} from '../common/ui';
import CommentDialog from '../common/CommentDialog';
import ConfirmationDialog from '../common/ConfirmationDialog';
import NormDialog from './NormDialog';
import SopsList from './sops/SopsList';
import SopAddDialog from './sops/SopAddDialog';
import SopVersionsDetailView from './sops/SopVersionsDetailView';
import styles from './NormDetailView.module.css';
import type { NormDto } from '@/types/norm';
import type { SopDto, CreateSopWithVersionDto } from '@/types/sop';
import normsService from '@/services/normsService';
import sopsService from '@/services/sopsService';
import { formatDate } from '@/lib/utils';

interface Props {
  normId: number;
  onClose: (savedId?: number) => void;
  breadcrumbs: string[];
}

const NormDetailView: React.FC<Props> = ({ normId, onClose, breadcrumbs }) => {
  const [norm, setNorm] = useState<NormDto | null>(null);
  const [sops, setSops] = useState<SopDto[]>([]);
  const [showEditDialog, setShowEditDialog] = useState(false);
  const [showConfirmationDialog, setShowConfirmationDialog] = useState(false);
  const [showDeactivateCommentDialog, setShowDeactivateCommentDialog] = useState(false);
  const [showAddSopDialog, setShowAddSopDialog] = useState(false);
  const [selectedSopForDetails, setSelectedSopForDetails] = useState<SopDto | null>(null);

  const fetchNormAndSops = useCallback(async () => {
    try {
      const [normData, sopsData] = await Promise.all([
        normsService.getNorm(normId),
        sopsService.getSopsByNorm(normId)
      ]);
      setNorm(normData);
      setSops(sopsData);
    } catch (err) {
      console.error('Error fetching norm and SOPs:', err);
    }
  }, [normId]);

  useEffect(() => {
    fetchNormAndSops();
  }, [fetchNormAndSops]);

  const handleEditSave = async (updatedNorm: NormDto) => {
    try {
      await normsService.updateNorm(updatedNorm.id, {
        name: updatedNorm.name,
        description: updatedNorm.description
      });
      setShowEditDialog(false);
      await fetchNormAndSops();
    } catch (err) {
      console.error('Error updating norm:', err);
      throw err;
    }
  };

  const handleToggleStatusClick = () => {
    if (!norm) return;
    if (norm.isObsolete) {
      setShowConfirmationDialog(true);
    } else {
      setShowDeactivateCommentDialog(true);
    }
  };

  const handleConfirmActivation = async () => {
    if (!norm) return;
    try {
      await normsService.toggleObsolete(norm.id, { isObsolete: false });
      setShowConfirmationDialog(false);
      await fetchNormAndSops();
    } catch (err) {
      console.error('Error activating norm:', err);
    }
  };

  const handleDeactivateSubmit = async (comment: string) => {
    if (!norm) return;
    if (!comment.trim()) return;
    try {
      await normsService.toggleObsolete(norm.id, { isObsolete: true, comments: comment });
      setShowDeactivateCommentDialog(false);
      await fetchNormAndSops();
    } catch (err) {
      console.error('Error deactivating norm:', err);
    }
  };

  const handleSaveNewSop = async (dto: CreateSopWithVersionDto) => {
    try {
      await sopsService.createSop(dto);
      setShowAddSopDialog(false);
      await fetchNormAndSops();
    } catch (err) {
      console.error('Error creating SOP:', err);
      throw err;
    }
  };

  if (selectedSopForDetails) {
    return (
      <SopVersionsDetailView 
        sopId={selectedSopForDetails.id}
        onClose={() => {
          setSelectedSopForDetails(null);
          fetchNormAndSops();
        }}
        breadcrumbs={[...breadcrumbs, `Norm ${norm?.name || normId}`, `SOP ${selectedSopForDetails.docCode}`]}
      />
    );
  }

  return (
    <DetailView>
      <DetailViewHeader 
        title={`Norm ${norm?.id || ''}`} 
        onBack={() => onClose(normId)} 
        breadcrumbs={breadcrumbs} 
      />
      <DetailViewContent>
        <div className="page-container">
          {!norm ? (
            <p>Loading norm details...</p>
          ) : (
            <>
              <DetailContainer>
                <DetailColumn>
                  <DetailItem label="Name" value={norm.name} />
                  <DetailItem label="Description" value={norm.description || '-'} />
                  <DetailItem label="Date Created" value={formatDate(norm.dateCreated)} />
                  <DetailItem label="Is Obsolete" value={norm.isObsolete ? "Yes" : "No"} />
                  <DetailItem label="Date Obsolete" value={formatDate(norm.dateObsolete)} />
                  {norm.isObsolete && norm.commentsObsolete && (
                    <DetailItem label="Obsolete Comment" value={norm.commentsObsolete} />
                  )}
                </DetailColumn>
              </DetailContainer>

              <div className={styles.actionButtons}>
                <button onClick={() => setShowEditDialog(true)} className="action-button edit-button">Edit</button>
                <button 
                  onClick={handleToggleStatusClick} 
                  className={`action-button ${norm.isObsolete ? 'secondary' : 'delete-button'}`}
                >
                  {norm.isObsolete ? "Activate" : "Deactivate"}
                </button>
              </div>

              <SopsList 
                sops={sops}
                onAddSop={() => setShowAddSopDialog(true)}
                onViewDetails={(sop) => setSelectedSopForDetails(sop)}
              />
            </>
          )}
        </div>

        {showEditDialog && norm && (
          <NormDialog 
            open={true}
            normData={norm}
            onClose={() => setShowEditDialog(false)}
            onSave={handleEditSave}
          />
        )}

        {showConfirmationDialog && norm && (
          <ConfirmationDialog 
            open={true}
            title="Confirm Norm Activation"
            message={`Are you sure you want to activate norm ${norm.name}?`}
            onConfirm={handleConfirmActivation}
            onCancel={() => setShowConfirmationDialog(false)}
          />
        )}

        {showDeactivateCommentDialog && (
          <CommentDialog 
            open={true}
            title="Deactivation Reason"
            onClose={() => setShowDeactivateCommentDialog(false)}
            onSubmit={handleDeactivateSubmit}
          />
        )}

        {showAddSopDialog && norm && (
          <SopAddDialog 
            open={true}
            normId={norm.id}
            onClose={() => setShowAddSopDialog(false)}
            onSave={handleSaveNewSop}
          />
        )}
      </DetailViewContent>
    </DetailView>
  );
};

export default NormDetailView;
