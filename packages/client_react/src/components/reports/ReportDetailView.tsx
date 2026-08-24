import React, { useState, useEffect, useCallback } from 'react';
import { 
  DetailView, 
  DetailViewHeader, 
  DetailViewContent, 
  DetailContainer, 
  DetailColumn, 
  DetailItem 
} from '../common/ui';
import { CommentDialog } from '../common';
import SignatureManifestBlock from '../common/SignatureManifestBlock';
import styles from './ReportDetailView.module.css';
import type { UserSessionDto } from '@/types/auth';
import type { ReportDetailDto } from '@/types/report';
import reportsService from '@/services/reportsService';
import { formatDate } from '@/lib/utils';

interface ReportDetailViewProps {
  reportId: number;
  onClose: (reportId?: number | null) => void;
  onChanged?: () => void;
  breadcrumbs?: string[];
  currentUser?: UserSessionDto | null;
}

const ReportDetailView: React.FC<ReportDetailViewProps> = ({
  reportId,
  onClose,
  onChanged,
  breadcrumbs = [],
  currentUser
}) => {
  const [report, setReport] = useState<ReportDetailDto | null>(null);
  const [showCommentDialog, setShowCommentDialog] = useState(false);
  const [canCancelReport, setCanCancelReport] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [signatureRefreshKey, setSignatureRefreshKey] = useState(0);

  const fetchReportDetails = useCallback(async () => {
    try {
      const data = await reportsService.getReport(reportId);
      setReport(data);
    } catch (err) {
      console.error('Failed to fetch report details', err);
    }
  }, [reportId]);

  useEffect(() => {
    fetchReportDetails();
  }, [fetchReportDetails]);

  useEffect(() => {
    if (currentUser && report) {
      const isLabPersonnel = currentUser.roles.includes('LabPers');
      setCanCancelReport(report.isSubmitted && !report.isCancelled && isLabPersonnel);
    } else {
      setCanCancelReport(false);
    }
  }, [currentUser, report]);

  const handleOpenCancelDialog = async () => {
    if (report) {
      try {
        const conflict = await reportsService.checkReportConflict(report.id);
        if (conflict) {
          setErrorMessage("This report is part of a submitted certificate and cannot be cancelled.");
          return;
        }
        setShowCommentDialog(true);
      } catch (err) {
        console.error('Failed to check conflict', err);
      }
    }
  };

  const handleCancelReport = async (comments: string) => {
    setErrorMessage(null);
    if (report && currentUser) {
      try {
        await reportsService.cancelReport(report.id, {
          userId: currentUser.id,
          commentsCancelled: comments
        });
        setShowCommentDialog(false);
        setSignatureRefreshKey(prev => prev + 1);
        await fetchReportDetails();
        if (onChanged) {
          onChanged();
        }
      } catch (err: any) {
        setErrorMessage(err.message || 'Failed to cancel report');
        setShowCommentDialog(false);
      }
    }
  };

  const renderTestsTable = () => {
    if (!report) return null;

    const tests = report.tests;

    // Re-implementing tests table logic correctly for React
    return (
      <table className="data-table">
        <thead>
          <tr>
            <th>ID</th>
            <th>Test Name</th>
            <th>Measurement Unit</th>
            <th>Value</th>
          </tr>
        </thead>
        <tbody>
          {tests.map((test, i) => {
            const isFirstOfMeasurement = i === 0 || tests[i - 1].measurementId !== test.measurementId;
            let sameMeasurementCount = 0;
            if (isFirstOfMeasurement) {
              for (let j = i; j < tests.length; j++) {
                if (tests[j].measurementId === test.measurementId) sameMeasurementCount++;
                else break;
              }
            }

            return (
              <tr key={i}>
                {isFirstOfMeasurement && (
                  <td rowSpan={sameMeasurementCount}>
                    {test.measurementId}{test.hasForm ? "*" : ""}
                  </td>
                )}
                <td>{test.testName} ({test.typeName})</td>
                <td>{test.unitName}</td>
                <td>
                  {test.formattedValues.map((val, idx) => (
                    <div key={idx}>{val}</div>
                  ))}
                </td>
              </tr>
            );
          })}
        </tbody>
      </table>
    );
  };

  return (
    <DetailView>
      <DetailViewHeader 
        title={`Report ${report ? report.id : reportId}`}
        onBack={() => onClose(reportId)}
        breadcrumbs={breadcrumbs}
      />
      <DetailViewContent>
        <div className={styles.reportDetailView}>
          {!report ? (
            <p>Loading report details...</p>
          ) : (
            <>
              <DetailContainer>
                <DetailColumn title="Info">
                  <DetailItem label="Reception Type:" value={report.receptionTypeName || '-'} />
                  <DetailItem label="Material Name:" value={report.materialName || '-'} />
                  <DetailItem label="Control Code:" value={report.controlCode || '-'} />
                  <DetailItem label="Reception ID:" value={report.receptionId.toString()} />
                </DetailColumn>

                <DetailColumn title="Status">
                  <DetailItem label="Submitted By:" value={report.userSubmittedTag || '-'} />
                  <DetailItem label="Date Submitted:" value={formatDate(report.dateSubmitted)} />
                  <DetailItem label="Submission Comments:" value={report.commentsSubmitted || '-'} />
                  {report.reportReplacedId && (
                    <DetailItem label="Replaced Report ID:" value={report.reportReplacedId.toString()} />
                  )}

                  {report.isCancelled && (
                    <div className={styles.cancellationInfo}>
                      <h4>Cancellation Information</h4>
                      <DetailItem label="Date Cancelled:" value={formatDate(report.dateCancelled)} />
                      <DetailItem label="Cancelled By:" value={report.userCancelledTag || '-'} />
                      <DetailItem label="Cancellation Comments:" value={report.commentsCancelled || '-'} />
                    </div>
                  )}
                </DetailColumn>
              </DetailContainer>

              <h3 className="section-title">Tests</h3>
              {renderTestsTable()}
              <p className="footnote">* Measurement performed using a testing form.</p>

              <SignatureManifestBlock key={signatureRefreshKey} entityName="reports" entityId={report.id} />

              {errorMessage && (
                <div className={styles.errorMessage}>{errorMessage}</div>
              )}

              <div className={styles.actions}>
                <button 
                  onClick={async () => {
                    try {
                      await reportsService.downloadPdf(report.id);
                    } catch (err: any) {
                      setErrorMessage(err.message || 'Failed to generate PDF report');
                    }
                  }} 
                  className="action-button secondary" style={{ marginRight: '10px' }}
                >
                  Print to PDF
                </button>
                {canCancelReport && (
                  <button onClick={handleOpenCancelDialog} className="action-button delete-button">Cancel Report</button>
                )}
              </div>
            </>
          )}
        </div>

        {showCommentDialog && (
          <CommentDialog 
            open={true}
            onClose={() => setShowCommentDialog(false)}
            onSubmit={handleCancelReport}
          />
        )}
      </DetailViewContent>
    </DetailView>
  );
};

export default ReportDetailView;
