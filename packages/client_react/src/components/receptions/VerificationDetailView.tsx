import React, { useEffect, useState } from 'react';
import { useAuthStore } from '@/store/authStore';
import {
  DetailView,
  DetailViewHeader,
  DetailViewContent,
  DetailContainer,
  DetailColumn,
  DetailItem
} from '@/components/common/ui';
import CommentDialog from '@/components/common/CommentDialog';
import ConfirmationDialog from '@/components/common/ConfirmationDialog';
import VerificationDialog from './VerificationDialog';
import ReceptionMeasurements from './ReceptionMeasurements';
import SubmittedReports from './SubmittedReports';
import PreviewReportDetailView from './PreviewReportDetailView';
import styles from './VerificationDetailView.module.css';
import type { TestDto } from '@/types/test';
import type { FormDto } from '@/types/form';
import type { ReceptionDetailDto, ReceptionTestDto } from '@/types/reception';
import receptionsService from '@/services/receptionsService';
import { formatDate } from '@/lib/utils';

interface Props {
  receptionId: number;
  onClose: () => void;
  breadcrumbs: string[];
  allTests: TestDto[];
  allForms: FormDto[];
}

const VerificationDetailView: React.FC<Props> = ({ 
  receptionId, 
  onClose, 
  breadcrumbs, 
  allTests, 
  allForms 
}) => {
  const { user: currentUser } = useAuthStore();
  const [reception, setReception] = useState<ReceptionDetailDto | null>(null);
  const [receptionTests, setReceptionTests] = useState<ReceptionTestDto[]>([]);
  const [showCommentDialog, setShowCommentDialog] = useState(false);
  const [commentType, setCommentType] = useState<'received' | 'rejected' | null>(null);
  const [showEditDialog, setShowEditDialog] = useState(false);
  const [showPreview, setShowPreview] = useState(false);
  const [showCancelConfirmation, setShowCancelConfirmation] = useState(false);

  const isLabPersonnel = currentUser?.roles.includes('LabPers') || false;

  useEffect(() => {
    loadData();
  }, [receptionId]);

  const loadData = async () => {
    try {
      const data = await receptionsService.getReception(receptionId);
      setReception(data);
      
      const tests = allTests
        .filter(t => data.receptionTests?.includes(t.id))
        .map(t => ({ id: t.id, name: t.name }));
      setReceptionTests(tests);
    } catch (err) {
      console.error('Failed to load reception data:', err);
    }
  };

  const openCommentDialog = (type: 'received' | 'rejected') => {
    setCommentType(type);
    setShowCommentDialog(true);
  };

  const handleCommentSubmit = async (comment: string) => {
    if (!currentUser || !reception) return;
    try {
      if (commentType === 'received') {
        await receptionsService.receiveReception(reception.id, { userId: currentUser.id, comments: comment });
      } else if (commentType === 'rejected') {
        await receptionsService.rejectReception(reception.id, { userId: currentUser.id, reason: comment });
      }
      setShowCommentDialog(false);
      loadData();
    } catch (err) {
      console.error('Failed to submit comment:', err);
    }
  };

  const handleCancelSubmission = async () => {
    if (!reception) return;
    try {
      await receptionsService.cancelSubmission(reception.id);
      setShowCancelConfirmation(false);
      loadData();
    } catch (err) {
      console.error('Failed to cancel submission:', err);
    }
  };

  if (!reception) return <div>Loading...</div>;

  return (
    <DetailView>
      <DetailViewHeader 
        title={`Verification Reception ${reception.id} (${reception.status})`} 
        onBack={onClose} 
        breadcrumbs={breadcrumbs} 
      />
      <DetailViewContent>
        <div className="reception-form">
          <DetailContainer>
            <DetailColumn title="Info">
              <DetailItem label="Material" value={reception.materialName} />
              <DetailItem label="Control Code" value={reception.controlCodeName} />
              <DetailItem label="Associated Tests" value={receptionTests.map(t => t.name).join('\n')} />
            </DetailColumn>
            <DetailColumn title="Status">
              <DetailItem label="Submission Comments" value={reception.commentsSubmitted} />
              <DetailItem 
                label={reception.isSubmitted ? "Submitted By" : "Last Edited By"} 
                value={reception.userSubmittedTag} 
              />
              <DetailItem 
                label={reception.isSubmitted ? "Submitted Date" : "Last Edited Date"} 
                value={formatDate(reception.dateSubmitted || '')} 
              />
              {reception.isReceived && (
                <>
                  <DetailItem label="Received Comments" value={reception.commentsReceived} />
                  <DetailItem label="Received By" value={reception.userReceivedTag} />
                  <DetailItem label="Received Date" value={formatDate(reception.dateReceived || '')} />
                </>
              )}
              {reception.isRejected && (
                <>
                  <DetailItem label="Rejected Comments" value={reception.commentsRejected} />
                  <DetailItem label="Rejected By" value={reception.userRejectedTag} />
                  <DetailItem label="Rejected Date" value={formatDate(reception.dateRejected || '')} />
                </>
              )}
            </DetailColumn>
          </DetailContainer>

          <div className={styles.buttonGroup}>
            {!reception.isSubmitted && (
              <button onClick={() => setShowEditDialog(true)} className="action-button edit-button">Edit</button>
            )}
            {reception.isSubmitted && !reception.isReceived && !reception.isRejected && reception.userSubmittedId === currentUser?.id && (
              <button onClick={() => setShowCancelConfirmation(true)} className="action-button secondary">Cancel Submission</button>
            )}

            {reception.isSubmitted && !reception.isReceived && !reception.isRejected && isLabPersonnel && (
              <>
                <button onClick={() => openCommentDialog('received')} className="action-button primary">Received</button>
                <button onClick={() => openCommentDialog('rejected')} className="action-button delete-button">Rejected</button>
              </>
            )}
          </div>

          {isLabPersonnel && (
            <ReceptionMeasurements 
              reception={reception} 
              breadcrumbs={breadcrumbs} 
              allTests={allTests} 
              allForms={allForms} 
            />
          )}

          {reception.isReceived && !reception.isRejected && (
            <div className={styles.previewReportContainer}>
              <button onClick={() => setShowPreview(true)} className="action-button primary">Preview Testing Report</button>
            </div>
          )}
          
          <SubmittedReports 
            receptionId={reception.id} 
            refreshTrigger={reception} 
            breadcrumbs={[...breadcrumbs, `Reception ${reception.id}`]} 
          />
        </div>

        {showPreview && (
          <PreviewReportDetailView 
            receptionId={reception.id} 
            onClose={() => { setShowPreview(false); loadData(); }} 
            allTests={allTests}
            breadcrumbs={[...breadcrumbs, `Reception ${reception.id}`]} 
          />
        )}

        {showCommentDialog && (
          <CommentDialog 
            open={true} 
            title={commentType === 'received' ? 'Received Comments' : 'Rejected Reason'}
            onClose={() => setShowCommentDialog(false)} 
            onSubmit={handleCommentSubmit} 
          />
        )}

        {showEditDialog && (
          <VerificationDialog 
            open={true} 
            reception={reception} 
            onSave={() => { loadData(); setShowEditDialog(false); }} 
            onClose={() => setShowEditDialog(false)} 
          />
        )}

        <ConfirmationDialog 
          open={showCancelConfirmation} 
          title="Cancel Submission" 
          message="Are you sure you want to cancel this submission and return it to draft?" 
          onConfirm={handleCancelSubmission} 
          onCancel={() => setShowCancelConfirmation(false)} 
        />
      </DetailViewContent>
    </DetailView>
  );
};

export default VerificationDetailView;
