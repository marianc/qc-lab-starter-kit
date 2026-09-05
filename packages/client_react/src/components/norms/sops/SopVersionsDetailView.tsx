import React, { useState, useEffect, useCallback } from 'react';
import type { SopDto, SopVersionDto, UpdateSopVersionDto } from '@/types/sop';
import sopsService from '@/services/sopsService';
import { 
  DetailView, 
  DetailViewHeader, 
  DetailViewContent, 
  DetailContainer, 
  DetailColumn, 
  DetailItem 
} from '@/components/common/ui';
import ConfirmationDialog from '@/components/common/ConfirmationDialog';
import SopVersionEditDialog from './SopVersionEditDialog';
import { formatDate } from '@/lib/utils';
import styles from './SopVersionsDetailView.module.css';

interface Props {
  sopId: number;
  onClose: () => void;
  breadcrumbs: string[];
}

const SopVersionsDetailView: React.FC<Props> = ({ sopId, onClose, breadcrumbs }) => {
  const [sop, setSop] = useState<SopDto | null>(null);
  const [editingVersion, setEditingVersion] = useState<SopVersionDto | null>(null);
  const [isCreatingVersion, setIsCreatingVersion] = useState(false);
  const [versionToActivate, setVersionToActivate] = useState<SopVersionDto | null>(null);

  const fetchSop = useCallback(async () => {
    try {
      const data = await sopsService.getSop(sopId);
      setSop(data);
    } catch (err) {
      console.error('Error fetching SOP details:', err);
    }
  }, [sopId]);

  useEffect(() => {
    fetchSop();
  }, [fetchSop]);

  const handleConfirmActivate = async () => {
    if (!versionToActivate) return;
    try {
      await sopsService.activateSopVersion(versionToActivate.id);
      setVersionToActivate(null);
      await fetchSop();
    } catch (err) {
      console.error('Error activating SOP version:', err);
    }
  };

  const handleSaveEdit = async (updated: UpdateSopVersionDto) => {
    if (!editingVersion) return;
    try {
      await sopsService.updateSopVersion(editingVersion.id, updated);
      setEditingVersion(null);
      await fetchSop();
    } catch (err: any) {
      console.error('Error updating SOP version:', err);
      throw err;
    }
  };

  const handleSaveCreate = async (updated: UpdateSopVersionDto) => {
    try {
      await sopsService.createSopVersion(sopId, updated);
      setIsCreatingVersion(false);
      await fetchSop();
    } catch (err: any) {
      console.error('Error creating SOP version:', err);
      throw err;
    }
  };

  return (
    <DetailView>
      <DetailViewHeader 
        title={`SOP: ${sop?.docCode || ''} - ${sop?.title || ''}`} 
        onBack={onClose} 
        breadcrumbs={breadcrumbs} 
      />
      <DetailViewContent>
        <div className="page-container">
          {!sop ? (
            <p>Loading SOP versions...</p>
          ) : (
            <>
              <DetailContainer>
                <DetailColumn>
                  <DetailItem label="Document Code" value={sop.docCode} />
                  <DetailItem label="Title" value={sop.title} />
                  <DetailItem label="Date Created" value={formatDate(sop.dateCreated)} />
                </DetailColumn>
              </DetailContainer>

              <div className={styles.versionsSection}>
                <h3>SOP Versions</h3>
                <div className={styles.actionRow}>
                  <button onClick={() => setIsCreatingVersion(true)} className="action-button primary">
                    Add new SOP Version
                  </button>
                </div>
                <div className="table-wrapper">
                  <table className="data-table">
                    <thead>
                      <tr>
                        <th>Version Number</th>
                        <th>External EDMS ID</th>
                        <th>Status</th>
                        <th>Date Activated</th>
                        <th>Comments</th>
                        <th>Actions</th>
                      </tr>
                    </thead>
                    <tbody>
                      {sop.versions.length === 0 ? (
                        <tr>
                          <td colSpan={6} className={styles.emptyCell}>No versions found.</td>
                        </tr>
                      ) : (
                        sop.versions.map((ver) => (
                          <tr key={ver.id}>
                            <td>{ver.versionNumber}</td>
                            <td>{ver.externalEdmsId || '-'}</td>
                            <td>
                              <span className={`${styles.badge} ${ver.isActive ? styles.activeBadge : styles.inactiveBadge}`}>
                                {ver.isActive ? 'Active' : 'Inactive'}
                              </span>
                            </td>
                            <td>{formatDate(ver.dateActivated)}</td>
                            <td className={styles.commentCell}>{ver.comments || '-'}</td>
                            <td>
                              <div className={styles.actionButtons}>
                                <button 
                                  onClick={() => setEditingVersion(ver)} 
                                  className="action-button edit-button small-button"
                                >
                                  Edit
                                </button>
                                {!ver.isActive && (
                                  <button 
                                    onClick={() => setVersionToActivate(ver)} 
                                    className="action-button delete-button small-button"
                                  >
                                    Activate
                                  </button>
                                )}
                              </div>
                            </td>
                          </tr>
                        ))
                      )}
                    </tbody>
                  </table>
                </div>
              </div>
            </>
          )}
        </div>

        {editingVersion && (
          <SopVersionEditDialog 
            open={true}
            sopId={sopId}
            versionData={editingVersion}
            onClose={() => setEditingVersion(null)}
            onSave={handleSaveEdit}
          />
        )}

        {isCreatingVersion && (
          <SopVersionEditDialog 
            open={true}
            sopId={sopId}
            versionData={null}
            onClose={() => setIsCreatingVersion(false)}
            onSave={handleSaveCreate}
          />
        )}

        {versionToActivate && (
          <ConfirmationDialog 
            open={true}
            title="Confirm SOP Version Activation"
            message={`Are you sure you want to activate version ${versionToActivate.versionNumber} for SOP ${sop?.docCode}? This will deactivate any currently active version.`}
            onConfirm={handleConfirmActivate}
            onCancel={() => setVersionToActivate(null)}
          />
        )}
      </DetailViewContent>
    </DetailView>
  );
};

export default SopVersionsDetailView;
