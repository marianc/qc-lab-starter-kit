import React, { useState, useEffect } from 'react';
import { 
  DetailView, 
  DetailViewHeader, 
  DetailViewContent, 
  DetailContainer, 
  DetailColumn, 
  DetailItem,
  Dialog,
  DialogHeader,
  DialogContent,
  DialogFooter
} from '@/components/common/ui';
import { ConfirmationDialog, CommentDialog } from '@/components/common';
import SpecTestDialog from './SpecTestDialog';
import styles from './SpecificationDetailView.module.css';
import type { UserSessionDto } from '@/types/auth';
import type { TestDto } from '@/types/test';
import type { SpecDto, SpecTestDto, SpecTestEvalDto } from '@/types/specification';
import type { SelectableItem } from '@/types/models';
import specificationsService from '@/services/specificationsService';
import testsService from '@/services/testsService';
import { formatDate } from '@/lib/utils';

interface Props {
  specificationId: number;
  onClose: (savedId?: number | null) => void;
  breadcrumbs?: string[];
  currentUser: UserSessionDto | null;
  allTests?: TestDto[];
  certifiedTestIds?: number[];
}

const SpecificationDetailView: React.FC<Props> = ({
  specificationId,
  onClose,
  breadcrumbs = [],
  currentUser,
  allTests: initialAllTests,
  certifiedTestIds: initialCertifiedTestIds
}) => {
  const [spec, setSpec] = useState<SpecDto | null>(null);
  const [allTests, setAllTests] = useState<TestDto[]>(initialAllTests || []);
  const [availableTests, setAvailableTests] = useState<SelectableItem[]>([]);
  const [certifiedTestIds, setCertifiedTestIds] = useState<number[]>(initialCertifiedTestIds || []);
  const [isQCPersonnel, setIsQCPersonnel] = useState(false);
  
  const [showSpecTestDialog, setShowSpecTestDialog] = useState(false);
  const [showCancelDialog, setShowCancelDialog] = useState(false);
  const [showSubmitDialog, setShowSubmitDialog] = useState(false);
  const [showConfirmDeleteSpec, setShowConfirmDeleteSpec] = useState(false);
  const [showConfirmDeleteSpecTest, setShowConfirmDeleteSpecTest] = useState(false);
  
  const [testIdToDelete, setTestIdToDelete] = useState<number | null>(null);
  const [editableTest, setEditableTest] = useState<SpecTestDto | null>(null);
  const [editableTestOriginalId, setEditableTestOriginalId] = useState<number | null>(null);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  useEffect(() => {
    setIsQCPersonnel(currentUser?.roles.includes('QcPers') || false);
    loadData();
  }, [specificationId, currentUser]);

  const loadData = async () => {
    try {
      const data = await specificationsService.getSpec(specificationId);
      if (data) {
        setSpec(data);
        
        const currentCertifiedIds = initialCertifiedTestIds || data.certifiedTests || [];
        setCertifiedTestIds(currentCertifiedIds);

        let currentAllTests = initialAllTests;
        if (!currentAllTests) {
          currentAllTests = await testsService.getAllTests();
        }
        if (currentAllTests) {
          setAllTests(currentAllTests);
        }

        if (data.tests) {
          const updatedTests = data.tests.map(test => {
            const fullTest = currentAllTests?.find(t => t.id === test.testId);
            if (fullTest) {
              const typeDisplay = fullTest.isArray ? `[${fullTest.typeName}]` : fullTest.typeName;
              return { ...test, testName: `${fullTest.name} (${typeDisplay})` };
            }
            return test;
          }).sort((a, b) => a.nrOrd - b.nrOrd);
          data.tests = updatedTests;
        }
        loadAvailableTests(data, currentAllTests || []);
      }
    } catch (err) {
      console.error('Failed to load specification data', err);
    }
  };

  const loadAvailableTests = (specData: SpecDto, allTestsData: TestDto[]) => {
    const applicableTestIds = specData.applicableTests || [];
    const currentTestIds = specData.tests?.map((t: SpecTestDto) => t.testId) || [];
    
    const available = allTestsData
      .filter(t => !t.isParam && applicableTestIds.includes(t.id) && !currentTestIds.includes(t.id))
      .map(t => ({ 
        id: t.id, 
        name: `${t.name} (${t.isArray ? `[${t.typeName}]` : t.typeName})`
      }));
    setAvailableTests(available);
  };

  const getFormattedValue = (testId: number, value: number) => {
    const test = allTests.find(t => t.id === testId);
    if (!test) return value.toString();

    if (test.typeId === 3) return value === 1 ? "Yes" : "No";
    if (test.typeId === 4 && test.enums) {
      return test.enums.find(e => e.value === Math.floor(value))?.name || value.toString();
    }
    if (test.typeId === 1) return value.toFixed(0);
    return value.toString();
  };

  const formatYesNo = (value?: number | null) => {
    if (value === undefined || value === null) return "Error";
    return value === 1 ? "Yes" : "No";
  };

  const handleSaveSpecTest = async (testData: SpecTestDto) => {
    if (!spec) return;
    try {
      if (editableTestOriginalId !== null) {
        await specificationsService.updateSpecTest(spec.id, editableTestOriginalId, {
          testFrequency: testData.testFrequency,
          condition: testData.condition,
          note: testData.note,
          evals: testData.evals
        });
      } else {
        await specificationsService.addSpecTest(spec.id, {
          testId: testData.testId,
          testFrequency: testData.testFrequency,
          condition: testData.condition,
          note: testData.note,
          evals: testData.evals
        });
      }
      setShowSpecTestDialog(false);
      setEditableTest(null);
      setEditableTestOriginalId(null);
      await loadData();
    } catch (err: any) {
      setErrorMessage(err.message);
    }
  };

  const handleConfirmDeleteSpecTest = async () => {
    if (spec && testIdToDelete !== null) {
      await specificationsService.deleteSpecTest(spec.id, testIdToDelete);
      setTestIdToDelete(null);
      setShowConfirmDeleteSpecTest(false);
      await loadData();
    }
  };

  const handleOpenSubmitDialog = () => {
    setErrorMessage(null);
    if (!spec?.tests || spec.tests.length === 0) {
      setErrorMessage("Cannot submit specification without tests. Please add at least one test.");
      return;
    }
    if (spec.tests.some((t: SpecTestDto) => !t.evals || t.evals.length === 0)) {
      const testsWithoutEvals = spec.tests
        .filter((t: SpecTestDto) => !t.evals || t.evals.length === 0)
        .map((t: SpecTestDto) => t.testName);
      setErrorMessage(`Cannot submit specification. The following tests do not have any validation tests defined: ${testsWithoutEvals.join(", ")}. Please edit each test and add at least one evaluation.`);
      return;
    }
    setShowSubmitDialog(true);
  };

  const handleSubmit = async (comment: string) => {
    if (!spec || !currentUser) return;
    try {
      await specificationsService.submitSpec(spec.id, { 
        userId: currentUser.id, 
        commentsSubmitted: comment,
        commentsCancelled: null
      });
      setShowSubmitDialog(false);
      onClose(spec.id);
    } catch (err: any) {
      setErrorMessage(err.message);
      setShowSubmitDialog(false);
    }
  };

  const handleCancelSpec = async (reason: string) => {
    if (!spec || !currentUser) return;
    await specificationsService.cancelSpec(spec.id, { 
      userId: currentUser.id, 
      commentsCancelled: reason,
      commentsSubmitted: null
    });
    setShowCancelDialog(false);
    await loadData();
  };

  const handleDuplicateSpec = async () => {
    if (!spec || !currentUser) return;
    const res = await specificationsService.duplicateSpec(spec.id, { 
      userId: currentUser.id,
      commentsSubmitted: null,
      commentsCancelled: null
    });
    onClose(res.id);
  };

  const confirmDeleteSpec = async () => {
    if (spec) {
      await specificationsService.deleteSpec(spec.id);
      setShowConfirmDeleteSpec(false);
      onClose(null);
    }
  };

  if (!spec) return null;

  return (
    <DetailView>
      <DetailViewHeader 
        title={`Specification ${spec.id}`} 
        onBack={() => onClose(specificationId)} 
        breadcrumbs={breadcrumbs} 
      />
      <DetailViewContent>
        <div className="page-container">
          <DetailContainer>
            <DetailColumn title="Info">
              <DetailItem label="Material" value={spec.materialName || "-"} />
              <DetailItem label="Norm" value={spec.normName || "-"} />
            </DetailColumn>
            <DetailColumn title="Status">
              <DetailItem label="Status" value={spec.status} />
              <DetailItem label={spec.isSubmitted ? "Submitted By" : "Created By"} value={spec.userSubmittedTag || "-"} />
              <DetailItem label={spec.isSubmitted ? "Submitted Date" : "Created Date"} value={formatDate(spec.dateSubmitted)} />
              {spec.commentsSubmitted && (
                <DetailItem label={spec.isSubmitted ? "Submission Comments" : "Creation Comments"} value={spec.commentsSubmitted} />
              )}

              {spec.dateCancelled && (
                <div className={styles.cancellationInfo}>
                  <h4>Cancellation Information</h4>
                  <DetailItem label="Date Cancelled:" value={formatDate(spec.dateCancelled)} />
                  <DetailItem label="Cancelled By:" value={spec.userCancelledTag || "-"} />
                  <DetailItem label="Cancellation Comments:" value={spec.commentsCancelled || "-"} />
                </div>
              )}
            </DetailColumn>
          </DetailContainer>

          <h3 className="section-title">Specification Tests</h3>

          {isQCPersonnel && !spec.isSubmitted && !spec.dateCancelled && (
            <button 
              onClick={() => { setEditableTest(null); setEditableTestOriginalId(null); setShowSpecTestDialog(true); }} 
              className="action-button primary add-test-button"
            >
              Add Test
            </button>
          )}

          <table className="data-table">
            <thead>
              <tr>
                <th>Test</th>
                <th>Measurement Unit</th>
                <th>Frequency</th>
                <th>Condition</th>
                <th>Note</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {spec.tests?.map((test: SpecTestDto) => (
                <tr key={test.testId}>
                  <td>{test.testName}{certifiedTestIds.includes(test.testId) ? "" : " (?)"}</td>
                  <td>{test.unitName || "-"}</td>
                  <td>{test.testFrequency}</td>
                  <td>{test.condition}</td>
                  <td>{test.note}</td>
                  <td>
                    {isQCPersonnel && !spec.isSubmitted && !spec.dateCancelled && (
                      <>
                        <button 
                          onClick={() => { setEditableTest(test); setEditableTestOriginalId(test.testId); setShowSpecTestDialog(true); }} 
                          className="action-button edit-button small-button"
                        >
                          Edit
                        </button>
                        <button 
                          onClick={() => { setTestIdToDelete(test.testId); setShowConfirmDeleteSpecTest(true); }} 
                          className="action-button delete-button small-button"
                        >
                          Remove
                        </button>
                      </>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>

          {errorMessage && <div className={styles.specErrorMessage}>{errorMessage}</div>}

          <p className="table-note"><i>Note: Tests marked with '(?)' are not configured for certification.</i></p>

          {isQCPersonnel && (
            <>
              <h3 className={`section-title ${styles.validationResultsTitle}`}>Validation Results</h3>
              <table className="data-table">
                <thead>
                  <tr>
                    <th>Test</th>
                    <th>Value</th>
                    <th>Condition Result</th>
                    <th>Expected Result</th>
                    <th>Assessment</th>
                    <th>Note</th>
                  </tr>
                </thead>
                <tbody>
                  {spec.tests?.map((test: SpecTestDto) => (
                    <React.Fragment key={test.testId}>
                      {test.evals?.map((evalItem: SpecTestEvalDto, i: number) => (
                        <tr key={`${test.testId}-${i}`}>
                          {i === 0 && <td rowSpan={test.evals.length}>{test.testName}</td>}
                          <td>{getFormattedValue(test.testId, evalItem.value)}</td>
                          <td>{formatYesNo(evalItem.result)}</td>
                          <td>{formatYesNo(evalItem.expectedResult)}</td>
                          <td>
                            <span className={`status-badge ${evalItem.isMatch ? "success" : "error"}`}>
                              {evalItem.isMatch ? "PASS" : "FAIL"}
                            </span>
                          </td>
                          <td>{evalItem.note}</td>
                        </tr>
                      ))}
                    </React.Fragment>
                  ))}
                </tbody>
              </table>
            </>
          )}

          <div className={styles.formActionsBar}>
            {isQCPersonnel && !spec.isSubmitted && !spec.dateCancelled && (
              <>
                <button onClick={handleOpenSubmitDialog} className="action-button primary">Submit</button>
                <button onClick={() => setShowConfirmDeleteSpec(true)} className="action-button delete-button">Delete</button>
              </>
            )}
            {isQCPersonnel && spec.isSubmitted && !spec.dateCancelled && (
              <>
                <button 
                  onClick={async () => {
                    try {
                      await specificationsService.downloadPdf(spec.id);
                    } catch (err: any) {
                      setErrorMessage(err.message || 'Failed to generate specification PDF report');
                    }
                  }} 
                  className="action-button secondary"
                >
                  Print to PDF
                </button>
                <button onClick={handleDuplicateSpec} className="action-button primary">Duplicate Spec</button>
                <button onClick={() => setShowCancelDialog(true)} className="action-button delete-button">Cancel Spec</button>
              </>
            )}
          </div>
        </div>

        {showSpecTestDialog && (
          <SpecTestDialog 
            open={true}
            test={editableTest}
            availableTests={availableTests}
            certifiedTestIds={certifiedTestIds}
            isEditMode={editableTestOriginalId !== null}
            onSave={handleSaveSpecTest}
            onClose={() => setShowSpecTestDialog(false)}
          />
        )}

        {showCancelDialog && (
          <CommentDialog 
            open={true}
            title="Enter Cancellation Reason"
            onClose={() => setShowCancelDialog(false)}
            onSubmit={handleCancelSpec}
          />
        )}

        {showSubmitDialog && (
          <CommentDialog 
            open={true}
            onClose={() => setShowSubmitDialog(false)}
            onSubmit={handleSubmit}
          />
        )}

        <ConfirmationDialog 
          open={showConfirmDeleteSpec}
          title="Delete Specification"
          message="Are you sure you want to delete this specification?"
          onConfirm={confirmDeleteSpec}
          onCancel={() => setShowConfirmDeleteSpec(false)}
        />

        <ConfirmationDialog 
          open={showConfirmDeleteSpecTest}
          title="Remove Test"
          message="Are you sure you want to remove this test from the specification?"
          onConfirm={handleConfirmDeleteSpecTest}
          onCancel={() => setShowConfirmDeleteSpecTest(false)}
        />
      </DetailViewContent>
    </DetailView>
  );
};

export default SpecificationDetailView;
