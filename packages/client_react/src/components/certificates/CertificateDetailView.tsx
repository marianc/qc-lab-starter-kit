import React, { useEffect, useState, useCallback } from 'react';
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
import SpecificationDetailView from '@/components/specifications/SpecificationDetailView';
import ReportDetailView from '@/components/reports/ReportDetailView';
import CertificateSubmitDialog from './CertificateSubmitDialog';
import SignatureManifestBlock from '@/components/common/SignatureManifestBlock';
import styles from './CertificateDetailView.module.css';
import type { TestDto } from '@/types/test';
import type { UserSessionDto } from '@/types/auth';
import type { CertificateDetailDto } from '@/types/certificate';
import certificatesService from '@/services/certificatesService';
import materialsService from '@/services/materialsService';
import authService from '@/services/authService';
import testsService from '@/services/testsService';
import { formatDate } from '@/lib/utils';

interface Props {
  certificateId: number;
  onClose: (viewedId?: number) => void;
  breadcrumbs: string[];
  allTests?: TestDto[];
  currentUser?: UserSessionDto | null;
}

const CertificateDetailView: React.FC<Props> = ({ 
  certificateId, 
  onClose, 
  breadcrumbs, 
  allTests: initialAllTests, 
  currentUser: initialUser 
}) => {
  const [certificate, setCertificate] = useState<CertificateDetailDto | null>(null);
  const [materialName, setMaterialName] = useState('');
  const [analysisResultMessage, setAnalysisResultMessage] = useState<string | null>(null);
  const [allTests, setAllTests] = useState<TestDto[]>(initialAllTests || []);
  const [currentUser, setCurrentUser] = useState<UserSessionDto | null>(initialUser || null);
  const [isQCPersonnel, setIsQCPersonnel] = useState(false);

  const [showSpecificationOverlay, setShowSpecificationOverlay] = useState(false);
  const [selectedSpecificationId, setSelectedSpecificationId] = useState<number | null>(null);
  const [selectedReportId, setSelectedReportId] = useState<number | null>(null);
  const [showSubmitDialog, setShowSubmitDialog] = useState(false);
  const [showCancelDialog, setShowCancelDialog] = useState(false);
  const [showDeleteDialog, setShowDeleteDialog] = useState(false);
  const [showConfirmReplace, setShowConfirmReplace] = useState(false);
  const [pendingCombinedComment, setPendingCombinedComment] = useState<string | null>(null);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [signatureRefreshKey, setSignatureRefreshKey] = useState(0);

  const fetchCertificate = useCallback(async () => {
    try {
      const data = await certificatesService.getCertificate(certificateId);
      setCertificate(data);
      if (data) {
        const mat = await materialsService.getMaterial(data.materialId);
        setMaterialName(mat?.name || '');
      }
    } catch (err) {
      console.error('Error fetching certificate:', err);
    }
  }, [certificateId]);

  useEffect(() => {
    const init = async () => {
      let user = currentUser;
      if (!user) {
        user = await authService.me();
        setCurrentUser(user);
      }
      setIsQCPersonnel(user?.roles.includes('QcPers') || false);

      if (allTests.length === 0) {
        const tests = await testsService.getAllTests();
        setAllTests(tests);
      }

      await fetchCertificate();
    };

    init();
  }, [certificateId, fetchCertificate]);

  const handleRefreshTests = async () => {
    if (!certificate) return;
    setAnalysisResultMessage(null);
    try {
      await certificatesService.refreshTests(certificate.id);
      await fetchCertificate();
    } catch (err) {
      console.error('Error refreshing tests:', err);
    }
  };

  const handleAnalyzeResults = async () => {
    if (!certificate) return;
    try {
      const res = await certificatesService.analyzeResults(certificate.id);
      if (certificate.isConformingSpec !== res.isConformingSpec) {
        await certificatesService.updateCertificate(certificate.id, { isConformingSpec: res.isConformingSpec });
      }
      await fetchCertificate();
      setAnalysisResultMessage(res.analysisResult);
    } catch (err) {
      console.error('Error analyzing results:', err);
    }
  };

  const handleSubmitClick = async () => {
    if (!certificate) return;
    await handleRefreshTests();
    await handleAnalyzeResults();

    try {
      const hasExisting = await certificatesService.hasExistingValidCertificates(certificate.id);
      if (hasExisting) {
        setShowConfirmReplace(true);
        return;
      }
    } catch (err) {
      console.error('Error checking existing certificates:', err);
    }

    setShowSubmitDialog(true);
  };

  const handleSubmitConfirmation = async (combinedComment: string) => {
    await executeSubmission(combinedComment);
  };

  const executeSubmission = async (combinedComment: string) => {
    if (!certificate || !currentUser) return;
    try {
      await certificatesService.submitCertificate(certificate.id, {
        userId: currentUser.id,
        commentsSubmitted: combinedComment,
        commentsCancelled: null
      });
      setShowSubmitDialog(false);
      setShowConfirmReplace(false);
      setPendingCombinedComment(null);
      setAnalysisResultMessage(null);
      setSignatureRefreshKey(prev => prev + 1);
      await fetchCertificate();
    } catch (err) {
      console.error('Error submitting certificate:', err);
    }
  };

  const handleCancelConfirmation = async (reason: string) => {
    if (!certificate || !currentUser) return;
    try {
      await certificatesService.cancelCertificate(certificate.id, {
        userId: currentUser.id,
        commentsCancelled: reason,
        commentsSubmitted: null
      });
      setShowCancelDialog(false);
      setSignatureRefreshKey(prev => prev + 1);
      await fetchCertificate();
    } catch (err) {
      console.error('Error cancelling certificate:', err);
    }
  };

  const renderTests = () => {
    if (!certificate) return null;
    const tests = certificate.tests;
    const rows: React.ReactNode[] = [];

    for (let i = 0; i < tests.length; i++) {
      const test = tests[i];
      let sameMeasurementCount = 0;
      for (let j = i; j < tests.length; j++) {
        if (tests[j].measurementId === test.measurementId) {
          sameMeasurementCount++;
        } else {
          break;
        }
      }

      rows.push(
        <tr key={`${test.measurementId}-${test.testId}-${i}`}>
          {(i === 0 || tests[i - 1].measurementId !== test.measurementId) && (
            <td rowSpan={sameMeasurementCount}>{test.measurementId}{test.hasForm ? '*' : ''}</td>
          )}
          <td>{test.testName} ({test.typeName})</td>
          <td>{test.unitName}</td>
          <td>
            {test.formattedValues.map((val: string, idx: number) => (
              <div key={idx}>{val}</div>
            ))}
          </td>
          <td>{test.testCount}/{test.testFrequency}</td>
          <td>{test.noteSpec}</td>
          <td>
            {test.conformingResults.map((res: boolean, idx: number) => (
              <div 
                key={idx} 
                className={res ? styles.textSuccess : styles.textDanger}
              >
                {res ? 'Yes' : 'No'}
              </div>
            ))}
          </td>
          <td>
            <button 
              onClick={() => setSelectedReportId(test.reportId)} 
              className="action-button secondary small-button"
            >
              Report #{test.reportId} {test.reportIsCancelled ? '!' : ''}
            </button>
          </td>
        </tr>
      );
    }
    return rows;
  };

  return (
    <DetailView>
      <DetailViewHeader 
        title={certificate ? `Certificate #${certificate.id} (${certificate.status})` : 'Certificate Details'}
        onBack={() => onClose(certificateId)}
        breadcrumbs={breadcrumbs}
      />
      <DetailViewContent>
        <div className={styles.certificateDetailView}>
          {!certificate ? (
            <p>Loading certificate details...</p>
          ) : (
            <>
              <DetailContainer>
                <DetailColumn title="Info">
                  <DetailItem label="Material" value={materialName} />
                  <DetailItem label="Control Code" value={certificate.controlCode} />
                  <DetailItem label="Is Conforming Spec" value={certificate.isConformingSpec ? 'Yes' : 'No'} />
                  <DetailItem 
                    label="Specification" 
                    value={
                      <button 
                        onClick={() => { setSelectedSpecificationId(certificate.specId); setShowSpecificationOverlay(true); }} 
                        className="action-button secondary small-button"
                      >
                        Spec #{certificate.specId}
                      </button>
                    } 
                  />
                </DetailColumn>
                <DetailColumn title="Status">
                  <DetailItem label="Status" value={certificate.status} />
                  <DetailItem 
                    label={certificate.isSubmitted ? "Submitted By:" : "Created By:"} 
                    value={certificate.userSubmittedTag} 
                  />
                  <DetailItem 
                    label={certificate.isSubmitted ? "Submission Date:" : "Created Date:"} 
                    value={formatDate(certificate.dateSubmitted)} 
                  />
                  
                  {certificate.isSubmitted && (
                    <>
                      {certificate.commentsSubmitted && (
                        <DetailItem label="Submission Comments:" value={certificate.commentsSubmitted} />
                      )}
                      <DetailItem label="Is Cancelled" value={certificate.isCancelled ? 'Yes' : 'No'} />
                      {certificate.isCancelled && (
                        <>
                          <DetailItem label="Cancelled By:" value={certificate.userCancelledTag} />
                          <DetailItem label="Cancellation Date:" value={formatDate(certificate.dateCancelled)} />
                          {certificate.commentsCancelled && (
                            <DetailItem label="Cancellation Comments:" value={certificate.commentsCancelled} />
                          )}
                        </>
                      )}
                    </>
                  )}
                </DetailColumn>
              </DetailContainer>

              <h2>Certificate Tests</h2>
              <table className="data-table">
                <thead>
                  <tr>
                    <th>ID</th>
                    <th>Test Name</th>
                    <th>Unit</th>
                    <th>Value</th>
                    <th>Test Count</th>
                    <th>Spec Note</th>
                    <th>Conforming</th>
                    <th>Source Report</th>
                  </tr>
                </thead>
                <tbody>
                  {renderTests()}
                </tbody>
              </table>
              <p className={styles.footnote}>* Measurement performed using a testing form.</p>

              <SignatureManifestBlock key={signatureRefreshKey} entityName="certificates" entityId={certificate.id} />

              {analysisResultMessage && (
                <div className={`${styles.analysisResultMessage} ${certificate.isConformingSpec ? styles.conforming : styles.nonConforming}`}>
                  {analysisResultMessage}
                </div>
              )}

              <div className={styles.certificateActions}>
                <div className={styles.actionSection}>
                  <button 
                    onClick={async () => {
                      try {
                        await certificatesService.downloadPdf(certificate.id);
                      } catch (err: any) {
                        setErrorMessage(err.message || 'Failed to generate PDF report');
                      }
                    }} 
                    className="action-button secondary"
                  >
                    Print to PDF
                  </button>
                </div>
                {isQCPersonnel && (
                  <>
                    {!certificate.isSubmitted ? (
                      <>
                        <div className={styles.actionSection}>
                          <button onClick={handleRefreshTests} className="action-button primary">Refresh Tests</button>
                          <button onClick={handleAnalyzeResults} className="action-button primary" style={{ marginLeft: '10px' }}>Analyze Results</button>
                        </div>
                        <div className={styles.actionSection}>
                          <button onClick={handleSubmitClick} className="action-button primary">Submit Certificate</button>
                          <button 
                            onClick={() => setShowDeleteDialog(true)} 
                            className="action-button delete-button" 
                            style={{ marginLeft: '10px' }}
                          >
                            Delete
                          </button>
                        </div>
                      </>
                    ) : (
                      !certificate.isCancelled && (
                        <div className={styles.actionSection}>
                          <button onClick={() => setShowCancelDialog(true)} className="action-button delete-button">Cancel Certificate</button>
                        </div>
                      )
                    )}
                  </>
                )}
              </div>
            </>
          )}
        </div>

        {showSubmitDialog && certificate && (
          <CertificateSubmitDialog 
            open={true}
            analysisMessage={analysisResultMessage || ''}
            isConformingSpec={certificate.isConformingSpec}
            onClose={() => setShowSubmitDialog(false)}
            onConfirm={handleSubmitConfirmation}
          />
        )}

        {showConfirmReplace && (
          <ConfirmationDialog
            open={true}
            title="Replace Existing Certificates"
            message="Existing valid quality certificates are already present for this control code. Do you want to replace them with the current one?"
            onConfirm={() => {
              setShowConfirmReplace(false);
              setShowSubmitDialog(true);
            }}
            onCancel={() => {
              setShowConfirmReplace(false);
              setPendingCombinedComment(null);
            }}
          />
        )}

        {showCancelDialog && (
          <CommentDialog 
            open={true}
            title="Cancellation Reason"
            onClose={() => setShowCancelDialog(false)}
            onSubmit={handleCancelConfirmation}
          />
        )}

        {showDeleteDialog && (
          <ConfirmationDialog
            open={true}
            title="Delete Certificate"
            message="Are you sure you want to delete this draft quality certificate? This action cannot be undone."
            onConfirm={async () => {
              if (!certificate) return;
              try {
                await certificatesService.deleteCertificate(certificate.id);
                setShowDeleteDialog(false);
                onClose();
              } catch (err: any) {
                setErrorMessage(err.message || 'Failed to delete certificate');
                setShowDeleteDialog(false);
              }
            }}
            onCancel={() => setShowDeleteDialog(false)}
          />
        )}

        {showSpecificationOverlay && selectedSpecificationId && (
          <SpecificationDetailView 
            specificationId={selectedSpecificationId}
            onClose={() => { setShowSpecificationOverlay(false); setSelectedSpecificationId(null); }}
            currentUser={currentUser}
            allTests={allTests}
            breadcrumbs={[...breadcrumbs, `Certificate ${certificate?.id}`]}
          />
        )}

        {selectedReportId && (
          <ReportDetailView 
            reportId={selectedReportId}
            onClose={() => setSelectedReportId(null)}
            currentUser={currentUser}
            breadcrumbs={[...breadcrumbs, `Certificate ${certificate?.id}`]}
          />
        )}
      </DetailViewContent>
    </DetailView>
  );
};

export default CertificateDetailView;