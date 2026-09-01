import React, { useEffect, useState, useMemo } from 'react';
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
import SpecificationDetailView from '@/components/specifications/SpecificationDetailView';
import styles from './PreviewReportDetailView.module.css';
import type { TestDto } from '@/types/test';
import type { PreviewReportDto } from '@/types/report';
import receptionsService from '@/services/receptionsService';
import { formatDate } from '@/lib/utils';

interface Props {
  receptionId: number;
  onClose: () => void;
  breadcrumbs: string[];
  allTests: TestDto[];
}

const PreviewReportDetailView: React.FC<Props> = ({ 
  receptionId, 
  onClose, 
  breadcrumbs, 
  allTests 
}) => {
  const { user: currentUser } = useAuthStore();
  const [report, setReport] = useState<PreviewReportDto | null>(null);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [showCommentDialog, setShowCommentDialog] = useState(false);
  const [showSpec, setShowSpec] = useState(false);

  const [showExpressCommentDialog, setShowExpressCommentDialog] = useState(false);

  const isLabPersonnel = currentUser?.roles.includes('LabPers') || false;

  useEffect(() => {
    loadPreviewData();
  }, [receptionId]);

  const loadPreviewData = async () => {
    setErrorMessage(null);
    try {
      const data = await receptionsService.getPreviewReport(receptionId);
      setReport(data);
    } catch (err: any) {
      setErrorMessage(`Error loading preview: ${err.message}`);
    }
  };

  const handleCreateReport = async () => {
    setErrorMessage(null);
    try {
      const conflict = await receptionsService.checkReportConflict(receptionId);
      if (conflict) {
        setErrorMessage("The existing report for this reception is part of a submitted certificate and cannot be cancelled. Therefore, a new report cannot be submitted.");
        return;
      }
      setShowCommentDialog(true);
    } catch (err: any) {
      setErrorMessage(`Error checking conflict: ${err.message}`);
    }
  };

  const handleCommentSubmit = async (comment: string) => {
    if (!currentUser) return;
    try {
      await receptionsService.createReport(receptionId, { 
        userId: currentUser.id, 
        comments: comment 
      });
      setShowCommentDialog(false);
      onClose();
    } catch (err: any) {
      let msg = err.response?.data?.message || err.message || 'Failed to submit report.';
      if (msg.length > 200) msg = msg.substring(0, 200) + '...';
      setErrorMessage(msg);
      setShowCommentDialog(false);
    }
  };

  const handleExpressCertificateClick = () => {
    setErrorMessage(null);
    setShowExpressCommentDialog(true);
  };

  const handleExpressCommentSubmit = async (comment: string) => {
    if (!currentUser) return;
    try {
      const result = await receptionsService.submitExpressCertificate(receptionId, {
        userId: currentUser.id,
        comments: comment
      });

      setShowExpressCommentDialog(false);

      if (!result.success) {
        setErrorMessage(result.errorMessage || 'Express certification failed.');
      } else {
        onClose();
      }
    } catch (err: any) {
      let msg = err.response?.data?.message || err.message || 'Failed to submit express certificate.';
      if (msg.length > 200) msg = msg.substring(0, 200) + '...';
      setErrorMessage(msg);
      setShowExpressCommentDialog(false);
    }
  };

  const groupedRows = useMemo(() => {
    if (!report?.tests) return [];
    
    const groups: { measurementId: number, hasForm: boolean, rows: any[] }[] = [];
    const map: Record<string, number> = {};

    report.tests.forEach(row => {
      const key = `${row.measurementId}-${row.hasForm}`;
      if (map[key] === undefined) {
        map[key] = groups.length;
        groups.push({ measurementId: row.measurementId, hasForm: row.hasForm, rows: [] });
      }
      groups[map[key]].rows.push(row);
    });

    return groups.sort((a, b) => a.measurementId - b.measurementId);
  }, [report]);

  if (!report && !errorMessage) return <div>Loading preview details...</div>;

  return (
    <DetailView>
      <DetailViewHeader 
        title={`Preview Testing Report for Reception ${receptionId}`} 
        onBack={onClose} 
        breadcrumbs={breadcrumbs} 
      />
      <DetailViewContent>
        <div className="report-detail-view preview-report">
          {report && (
            <>
              <DetailContainer>
                <DetailColumn title="Info">
                  <DetailItem label="Reception Type:" value={report.receptionTypeName} />
                  <DetailItem label="Material Name:" value={report.materialName} />
                  <DetailItem label="Control Code:" value={report.controlCodeName} />
                  <DetailItem label="Reception ID:" value={report.receptionId.toString()} />
                </DetailColumn>

                <DetailColumn title="Status">
                  <DetailItem label="Submitted By:" value={report.userSubmittedTag} />
                  <DetailItem label="Date Submitted:" value={formatDate(report.dateSubmitted || '')} />
                  <DetailItem label="Submission Comments:" value={report.commentsSubmitted} />
                </DetailColumn>
              </DetailContainer>

              <h3 className="section-title">Tests Preview</h3>
              {report.tests && report.tests.length > 0 ? (
                <>
                  <table className="data-table">
                    <thead>
                      <tr>
                        <th>ID</th>
                        <th>Test Name</th>
                        <th>Measurement Unit</th>
                        <th>Value</th>
                        {report.isCertification && (
                          <th>Uncertainty</th>
                        )}
                        {report.isCertification && (
                          <>
                            <th>Spec Note</th>
                            <th>Conforming</th>
                          </>
                        )}
                      </tr>
                    </thead>
                    <tbody>
                      {groupedRows.map(group => (
                        <React.Fragment key={`${group.measurementId}-${group.hasForm}`}>
                          {group.rows.map((row, idx) => (
                            <tr key={idx}>
                              {idx === 0 && (
                                <td rowSpan={group.rows.length}>
                                  {row.measurementId}{row.hasForm ? '*' : ''}
                                </td>
                              )}
                              <td>{row.testName} ({row.typeName})</td>
                              <td>{row.unitName}</td>
                              <td>
                                {row.formattedValues.map((val: string, vidx: number) => (
                                  <div key={vidx}>{val}</div>
                                ))}
                              </td>
                              {report.isCertification && (
                                <td>
                                  {row.uncertaintyValues.map((unc: string, uidx: number) => (
                                    <div key={uidx}>{unc || '-'}</div>
                                  ))}
                                </td>
                              )}
                              {report.isCertification && (
                                <>
                                  <td>{row.specNote}</td>
                                  <td>
                                    {row.conformingResults.map((res: boolean | null, ridx: number) => {
                                      if (res === null) return <div key={ridx}>-</div>;
                                      const uncRes = row.conformingUncertaintyResults && row.conformingUncertaintyResults[ridx] !== undefined
                                        ? row.conformingUncertaintyResults[ridx]
                                        : true;
                                      const status = !res ? 'Fail' : (uncRes ? 'Pass' : 'Inconclusive');
                                      const statusClass = status === 'Pass' 
                                        ? styles.textSuccess 
                                        : (status === 'Inconclusive' ? styles.textWarning : styles.textDanger);
                                      return (
                                        <div key={ridx} className={statusClass}>
                                          {status}
                                        </div>
                                      );
                                    })}
                                  </td>
                                </>
                              )}
                            </tr>
                          ))}
                        </React.Fragment>
                      ))}
                    </tbody>
                  </table>
                  <p className={styles.footnote}>* Measurement performed using a testing form.</p>
                </>
              ) : (
                <p className={styles.emptyMessage}>There are no reported test measurements</p>
              )}

              {errorMessage && <div className={styles.errorMessage}>{errorMessage}</div>}

              <div className={styles.actionsBar}>
                {isLabPersonnel && (
                  <button 
                    onClick={handleCreateReport} 
                    className="action-button primary" 
                    disabled={!report.tests || report.tests.length === 0}
                  >
                    Submit Testing Report
                  </button>
                )}
                {isLabPersonnel && report.isCertification && (
                  <button 
                    onClick={handleExpressCertificateClick} 
                    className="action-button primary" 
                    disabled={!report.tests || report.tests.length === 0}
                  >
                    Submit Express Certificate
                  </button>
                )}
                {report.isCertification && report.activeSpecId && (
                  <button onClick={() => setShowSpec(true)} className="action-button secondary">View Specification</button>
                )}
              </div>
            </>
          )}
        </div>

        {showSpec && report?.activeSpecId && (
          <SpecificationDetailView 
            specificationId={report.activeSpecId} 
            onClose={() => setShowSpec(false)} 
            allTests={allTests}
            breadcrumbs={[...breadcrumbs, `Report Preview ${receptionId}`]} 
            currentUser={currentUser}
          />
        )}

        {showCommentDialog && (
          <CommentDialog 
            open={true} 
            title="Testing Report Submission Comments"
            onClose={() => setShowCommentDialog(false)} 
            onSubmit={handleCommentSubmit} 
          />
        )}

        {showExpressCommentDialog && (
          <CommentDialog 
            open={true} 
            title="Express Certificate Submission Comments"
            onClose={() => setShowExpressCommentDialog(false)} 
            onSubmit={handleExpressCommentSubmit} 
          />
        )}
      </DetailViewContent>
    </DetailView>
  );
};

export default PreviewReportDetailView;
