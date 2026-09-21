import React, { useState, useEffect } from 'react';
import { 
  DetailView, 
  DetailViewHeader, 
  DetailViewContent, 
  DetailContainer, 
  DetailColumn, 
  DetailItem,
  DragHandle
} from '../../common/ui';
import { 
  ConfirmationDialog, 
  CommentDialog,
  NotificationDialog 
} from '../../common';
import FormDialog from './FormDialog';
import FormParamDialog from './FormParamDialog';
import FormulaDialog from './FormulaDialog';
import TestDialog from '../../tests/TestDialog';
import FormValidationDetailView from './FormValidationDetailView';
import SignatureManifestBlock from '@/components/common/SignatureManifestBlock';
import styles from './FormDetailView.module.css';
import type { TestDto, TestEnumDto } from '@/types/test';
import type { FormDetailDto, FormParamDto, ReorderFormParamDto } from '@/types/form';
import type { FormEvalDto } from '@/types/formEval';
import formsService from '@/services/formsService';
import testsService from '@/services/testsService';
import formEvalsService from '@/services/formEvalsService';
import authService from '@/services/authService';
import { formatDate } from '@/lib/utils';

interface FormDetailViewProps {
  formId: number;
  onClose: (savedId?: number | null) => void;
  breadcrumbs?: string[];
  allTests: TestDto[];
}

const FormDetailView: React.FC<FormDetailViewProps> = ({ 
  formId, 
  onClose, 
  breadcrumbs = [],
  allTests: initialAllTests
}) => {
  const [form, setForm] = useState<FormDetailDto | null>(null);
  const [formParams, setFormParams] = useState<FormParamDto[]>([]);
  const [allTests, setAllTests] = useState<TestDto[]>(initialAllTests);
  const [formEvals, setFormEvals] = useState<FormEvalDto[]>([]);
  const [allFormParamEnums, setAllFormParamEnums] = useState<TestEnumDto[]>([]);

  const [showFormDialog, setShowFormDialog] = useState(false);
  const [showParamDialog, setShowParamDialog] = useState(false);
  const [showNewTestDialog, setShowNewTestDialog] = useState(false);
  const [showCommentDialog, setShowCommentDialog] = useState(false);
  const [showFormulaDialog, setShowFormulaDialog] = useState(false);
  const [selectedFormula, setSelectedFormula] = useState<string | null>(null);
  const [editingParam, setEditingParam] = useState<FormParamDto | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [commentType, setCommentType] = useState<"validate" | "cancel" | null>(null);
  const [draggedItemIndex, setDraggedItemIndex] = useState<number | null>(null);
  const [isDragHandleActive, setIsDragHandleActive] = useState(false);

  const [showConfirmDeleteParam, setShowConfirmDeleteParam] = useState(false);
  const [paramIdToDelete, setParamIdToDelete] = useState<number | null>(null);
  const [showConfirmDeleteEval, setShowConfirmDeleteEval] = useState(false);
  const [evalIdToDelete, setEvalIdToDelete] = useState<number | null>(null);
  const [showConfirmReactivate, setShowConfirmReactivate] = useState(false);

  const [detailViewConfig, setDetailViewConfig] = useState<{ type: string; evalId?: number | null } | null>(null);
  const [signatureRefreshKey, setSignatureRefreshKey] = useState(0);

  const canReorder = form && !(form.isValidated || form.isCancelled);

  const loadData = async () => {
    try {
      const fetchedForm = await formsService.getForm(formId);
      setForm(fetchedForm);
      
      const params = await formsService.getFormParams(formId);
      setFormParams([...params].sort((a, b) => a.nrOrd - b.nrOrd));
      
      let currentTests = initialAllTests;
      if (!currentTests || currentTests.length === 0) {
        currentTests = await testsService.getAllTests();
        setAllTests(currentTests);
      }

      if (fetchedForm.isSubmitted) {
        const evals = await formEvalsService.getFormEvals(formId);
        setFormEvals(evals);
      }

      const enums = currentTests
        .filter(t => t.typeId === 4 && t.enums)
        .flatMap(t => t.enums!);
      setAllFormParamEnums(enums);
    } catch (err) {
      console.error('Failed to load form details', err);
    }
  };

  useEffect(() => {
    loadData();
  }, [formId]);

  const getStatus = (f: FormDetailDto) => {
    if (f.isCancelled) return "Cancelled";
    if (f.isValidated) return "Validated";
    if (f.isSubmitted) return "Submitted";
    return "Draft";
  };

  const getTestName = (testId: number) => {
    const test = allTests.find(t => t.id === testId);
    if (!test) return "-";
    const paramSuffix = !test.isParam ? "!" : "";
    const typeName = test.isArray ? `[${test.typeName}]` : test.typeName;
    return `${test.name}${paramSuffix} (${test.code}, ${typeName})`;
  };

  const formatValue = (val: number, typeId: number, testId: number) => {
    if (typeId === 1) return val.toFixed(0);
    if (typeId === 3) return val === 1 ? "Yes" : "No";
    if (typeId === 4) {
      const enumItem = allFormParamEnums.find(e => e.testId === testId && Math.abs(e.value - val) < 0.001);
      return enumItem?.name ?? val.toString();
    }
    return val.toString();
  };

  const getDefaultValueDisplay = (param: FormParamDto) => {
    if (param.defaultValue === null || param.defaultValue === undefined) return "-";
    return formatValue(param.defaultValue, param.typeId, param.testId);
  };

  const formatBoolean = (val: number | null | undefined) => {
    if (val === null || val === undefined) return '-';
    return val === 1 ? 'Yes' : 'No';
  };

  const handleDragStart = (index: number) => {
    if (!isDragHandleActive) return;
    setDraggedItemIndex(index);
  };

  const handleDragEnter = (index: number) => {
    if (draggedItemIndex === null || draggedItemIndex === index) return;
    const newParams = [...formParams];
    const draggedItem = newParams[draggedItemIndex];
    newParams.splice(draggedItemIndex, 1);
    newParams.splice(index, 0, draggedItem);
    setFormParams(newParams);
    setDraggedItemIndex(index);
  };

  const handleDragEnd = async () => {
    setDraggedItemIndex(null);
    setIsDragHandleActive(false);
    
    const reordered = formParams.map((p, idx) => ({ ...p, nrOrd: idx + 1 }));
    setFormParams(reordered);

    try {
      const reorderData: ReorderFormParamDto[] = reordered.map(p => ({ testId: p.testId, nrOrd: p.nrOrd }));
      await formsService.reorderFormParams(formId, reorderData);
    } catch (err) {
      console.error('Failed to save parameter order', err);
      loadData();
    }
  };

  const handleEditFormSave = async (updatedForm: FormDetailDto) => {
    setError(null);
    try {
      const user = await authService.me();
      if (!user) return;
      await formsService.updateForm(updatedForm.id, {
        formGroupId: updatedForm.formGroupId > 0 ? updatedForm.formGroupId : form!.formGroupId,
        version: updatedForm.version || '',
        customNav: updatedForm.customNav,
        isCustomized: updatedForm.isCustomized,
        userId: user.id
      });
      setShowFormDialog(false);
      loadData();
    } catch (err: any) {
      setError(err.message);
    }
  };

  const handleSaveParam = async (param: FormParamDto) => {
    setError(null);
    try {
      if (editingParam) {
        await formsService.updateFormParam(formId, param.testId, param);
      } else {
        await formsService.addFormParam(formId, param);
      }
      setShowParamDialog(false);
      loadData();
    } catch (err: any) {
      setError(err.message);
    }
  };

  const handleRequestDeleteParam = (testId: number) => {
    setError(null);
    const testToDelete = allTests.find(t => t.id === testId);
    if (testToDelete) {
      const codeSearch = `[${testToDelete.code}]`;
      const arrayCodeSearch = `[[${testToDelete.code}]]`;
      
      const dependentParams = formParams.filter(p => p.isCalculated && p.dependencies && 
        (p.dependencies.includes(codeSearch) || p.dependencies.includes(arrayCodeSearch)));
        
      if (dependentParams.length > 0) {
        const dependentNames = dependentParams.map(p => p.name).join(", ");
        setError(`Cannot delete '${testToDelete.name}' because it is used as a dependency in: ${dependentNames}.`);
        return;
      }
    }
    setParamIdToDelete(testId);
    setShowConfirmDeleteParam(true);
  };

  const handleDeleteParam = async () => {
    if (paramIdToDelete !== null) {
      try {
        await formsService.deleteFormParam(formId, paramIdToDelete);
        setParamIdToDelete(null);
        setShowConfirmDeleteParam(false);
        loadData();
      } catch (err: any) {
        setError(err.message);
        setShowConfirmDeleteParam(false);
      }
    }
  };

  const handleSaveNewTest = async (newTest: TestDto) => {
    try {
      const res = await testsService.createTest({
        name: newTest.name,
        code: newTest.code,
        description: newTest.description,
        typeId: newTest.typeId,
        isArray: newTest.isArray,
        isParam: newTest.isParam,
        forEnvironmentalControl: newTest.forEnvironmentalControl,
        forCertification: newTest.forCertification,
        unitId: newTest.unitId,
        normId: newTest.normId,
        normRef: newTest.normRef,
        sopId: newTest.sopId,
        nrOrd: newTest.nrOrd,
        isObsolete: false,
        enums: newTest.enums?.map(e => ({ name: e.name, value: e.value, nrOrd: e.nrOrd }))
      });
      
      const fetched = await testsService.getTest(res.id);
      if (fetched) {
        setAllTests(prev => [...prev, fetched]);
        
        // Update allFormParamEnums to include new enums if any
        if (fetched.typeId === 4 && fetched.enums) {
          setAllFormParamEnums(prev => {
            const newEnums = fetched.enums!.filter(en => !prev.some(e => e.testId === fetched.id && e.value === en.value));
            return [...prev, ...newEnums];
          });
        }

        await formsService.addFormParam(formId, { testId: fetched.id, nrOrd: formParams.length + 1 } as any);
        loadData();
      }
      setShowNewTestDialog(false);
    } catch (err: any) {
      setError(err.message);
    }
  };

  const handleSubmitForm = async () => {
    try {
      const user = await authService.me();
      if (!user) return;
      await formsService.submitForm(formId, { userId: user.id });
      loadData();
    } catch (err: any) {
      setError(err.message);
    }
  };

  const handleCommentSubmit = async (comments: string) => {
    try {
      const user = await authService.me();
      if (!user) return;
      if (commentType === "validate") {
        await formsService.validateForm(formId, { userId: user.id, commentsValidated: comments });
      } else {
        await formsService.cancelForm(formId, { userId: user.id, commentsCancelled: comments });
      }
      setShowCommentDialog(false);
      setSignatureRefreshKey(prev => prev + 1);
      loadData();
    } catch (err: any) {
      setError(err.message);
      setShowCommentDialog(false);
    }
  };

  const handleDuplicateForm = async () => {
    try {
      const user = await authService.me();
      if (!user) return;
      await formsService.duplicateForm(formId, { userId: user.id });
      onClose(formId);
    } catch (err: any) {
      setError(err.message);
    }
  };

  const handleReactivateForm = async () => {
    try {
      await formsService.reactivateForm(formId);
      setShowConfirmReactivate(false);
      loadData();
    } catch (err: any) {
      setError(err.message);
      setShowConfirmReactivate(false);
    }
  };

  const handleRequestDeleteEval = (id: number) => {
    setEvalIdToDelete(id);
    setShowConfirmDeleteEval(true);
  };

  const handleDeleteEval = async () => {
    if (evalIdToDelete !== null) {
      try {
        await formEvalsService.deleteFormEval(evalIdToDelete);
        setEvalIdToDelete(null);
        setShowConfirmDeleteEval(false);
        loadData();
      } catch (err: any) {
        setError(err.message);
        setShowConfirmDeleteEval(false);
      }
    }
  };

  const handleAddTestData = () => {
    setDetailViewConfig({ type: "validationForm" });
  };

  const handleEditEval = (id: number) => {
    setDetailViewConfig({ type: "validationForm", evalId: id });
  };

  const handleValidationFormClose = async () => {
    setDetailViewConfig(null);
    await loadData();
  };

  const getEvalCellClass = (evalItem: FormEvalDto, param: FormParamDto) => {
    if (!param.isCalculated) return "";
    const res = evalItem.expectedResults?.[param.code];
    if (!res || res.isMatch === null) return "";
    
    let isMatch = true;
    if (typeof res.isMatch === 'boolean') {
      isMatch = res.isMatch;
    } else if (Array.isArray(res.isMatch)) {
      isMatch = res.isMatch.every(x => x === true);
    }
    
    return isMatch ? styles.cellMatch : styles.cellMismatch;
  };

  const renderEvalValue = (evalItem: FormEvalDto, param: FormParamDto) => {
    let val: any = null;
    let expected: any = null;
    let isMatchObj: any = null;
    
    if (param.isCalculated) {
      val = evalItem.calculatedResults?.[param.code];
      const res = evalItem.expectedResults?.[param.code];
      if (res) {
        expected = res.value;
        isMatchObj = res.isMatch;
      }
    } else {
      val = evalItem.measurementData?.[param.code];
    }

    if (val === null || val === undefined) return "-";

    const formatSingle = (v: any) => {
      if (typeof v === 'number') return formatValue(v, param.typeId, param.testId);
      return String(v);
    };

    if (param.isArray && Array.isArray(val)) {
      const eList = Array.isArray(expected) ? expected : [];
      const mList = Array.isArray(isMatchObj) ? isMatchObj : [];
      
      return val.map((v, i) => {
        const eItem = eList[i];
        // const isMatch = mList[i] !== undefined ? mList[i] : true;
        // const color = isMatch ? 'green' : 'red';

        return (
          <div key={i}>
            {formatSingle(v)}
            {param.isCalculated && eItem !== undefined && eItem !== null && (
              <span style={{ marginLeft: '4px', color: "green" }}>({formatSingle(eItem)})</span>
            )}
          </div>
        );
      });
    }

    const isMatch = typeof isMatchObj === 'boolean' ? isMatchObj : true;
    // const color = isMatch ? 'green' : 'red'; // Removed to use cell color

    return (
      <>
        {formatSingle(val)}
        {param.isCalculated && expected !== null && expected !== undefined && (
          <span style={{ marginLeft: '4px', color: "green" }}>({formatSingle(expected)})</span>
        )}
      </>
    );
  };

  if (!form) return null;

  return (
    <DetailView>
      <DetailViewHeader title={`Form ${form.id}`} onBack={() => onClose(formId)} breadcrumbs={breadcrumbs} />
      <DetailViewContent>
        <div className="page-container">
          <DetailContainer>
            <DetailColumn title="Info">
              <DetailItem label="Version" value={form.version} />
              <DetailItem label="Is Customized" value={form.isCustomized ? "Yes" : "No"} />
              <DetailItem label="Custom Nav" value={form.customNav || "-"} />
            </DetailColumn>
            <DetailColumn title="Status">
              <DetailItem label="Is Submitted" value={form.isSubmitted ? 'Yes' : 'No'} />
              {!form.isSubmitted ? (
                <>
                  <DetailItem label="Created By" value={form.userSubmittedTag || '-'} />
                  <DetailItem label="Created Date" value={formatDate(form.dateSubmitted)} />
                </>
              ) : (
                <>
                  <DetailItem label="Submitted By" value={form.userSubmittedTag || '-'} />
                  <DetailItem label="Submitted Date" value={formatDate(form.dateSubmitted)} />
                  {form.commentsSubmitted && <DetailItem label="Comments Submitted" value={form.commentsSubmitted} />}
                  
                  <DetailItem label="Is Validated" value={form.isValidated ? 'Yes' : 'No'} />
                  {form.isValidated && (
                    <>
                      <DetailItem label="Validated By" value={form.userValidatedTag || '-'} />
                      <DetailItem label="Validated Date" value={formatDate(form.dateValidated)} />
                      {form.commentsValidated && <DetailItem label="Comments Validated" value={form.commentsValidated} />}
                      
                      <DetailItem label="Is Cancelled" value={form.isCancelled ? 'Yes' : 'No'} />
                      {form.isCancelled && (
                        <>
                          <DetailItem label="Cancelled By" value={form.userCancelledTag || '-'} />
                          <DetailItem label="Cancelled Date" value={formatDate(form.dateCancelled)} />
                          {form.commentsCancelled && <DetailItem label="Comments Cancelled" value={form.commentsCancelled} />}
                        </>
                      )}
                    </>
                  )}
                </>
              )}
            </DetailColumn>
          </DetailContainer>

          {!form.isValidated && !form.isCancelled && (
            <div className={styles.actionButtons}>
              <button onClick={() => setShowFormDialog(true)} className="action-button edit-button">Edit</button>
            </div>
          )}

          <div className="form-group">
            <h3 className="section-title">Form Parameters</h3>
            {!form.isValidated && !form.isCancelled && (
              <div className={styles.actionButtonsList}>
                <button onClick={() => { setEditingParam(null); setShowParamDialog(true); }} className="action-button primary">Add Form Parameter</button>
                <button onClick={() => setShowNewTestDialog(true)} className="action-button primary">Add New Test or Parameter</button>
              </div>
            )}
            <table className="data-table">
              <thead>
                <tr>
                  <th>Test</th>
                  <th>Calculated</th>
                  <th>Dependencies</th>
                  <th>Code Array Columns</th>
                  <th>Required</th>
                  <th>Default Value</th>
                  <th>Condition</th>
                  <th>Order</th>
                  {!form.isValidated && !form.isCancelled && (
                    <>
                      <th>Actions</th>
                      <th className={styles.dragHandleCol}></th>
                    </>
                  )}
                </tr>
              </thead>
              <tbody>
                {formParams.map((param, index) => (
                  <tr key={param.testId}
                      className={draggedItemIndex === index ? "dragging" : ""}
                      draggable={!!canReorder}
                      onDragStart={() => handleDragStart(index)}
                      onDragOver={(e) => e.preventDefault()}
                      onDragEnter={() => handleDragEnter(index)}
                      onDragEnd={handleDragEnd}>
                    <td>{getTestName(param.testId)}</td>
                    <td>{param.isCalculated ? "Yes" : "No"}</td>
                    <td onClick={() => { if(param.formula) { setSelectedFormula(param.formula); setShowFormulaDialog(true); } }} className={param.formula ? styles.clickable : ""}>
                      {param.dependencies}
                    </td>
                    <td>{param.codeRelatedArrays}</td>
                    <td>{param.isRequired ? "Yes" : "No"}</td>
                    <td>{getDefaultValueDisplay(param)}</td>
                    <td>{param.hasCondition ? param.conditionNote : "-"}</td>
                    <td>{param.nrOrd}</td>
                    {!form.isValidated && !form.isCancelled && (
                      <>
                        <td>
                          <button onClick={() => { setEditingParam(param); setShowParamDialog(true); }} className="action-button edit-button small-button">Edit</button>
                          <button onClick={() => handleRequestDeleteParam(param.testId)} className="action-button delete-button small-button">Delete</button>
                        </td>
                        <td><DragHandle onMouseDown={() => setIsDragHandleActive(true)} onMouseUp={() => setIsDragHandleActive(false)} /></td>
                      </>
                    )}
                  </tr>
                ))}
              </tbody>
            </table>
            {error && <div className={styles.errorMessage}>{error}</div>}
          </div>

          {formParams.some(p => p.hasCondition) && (
            <div className={`form-group ${styles.evalDataSection}`}>
              <h3 className="section-title">Condition Evaluation Results</h3>
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
                  {formParams.filter(p => p.hasCondition).map(param => (
                    <React.Fragment key={param.testId}>
                      {param.evals?.map((evalItem, i) => (
                        <tr key={`${param.testId}-${i}`}>
                          {i === 0 && <td rowSpan={param.evals.length}>{param.name}</td>}
                          <td>{evalItem.value}</td>
                          <td>{formatBoolean(evalItem.result)}</td>
                          <td>{formatBoolean(evalItem.expectedResult)}</td>
                          <td>
                            <span className={`status-badge ${evalItem.isMatch ? "success" : "error"}`}>
                              {evalItem.isMatch ? "PASS" : "FAIL"}
                            </span>
                          </td>
                          <td>{evalItem.note || '-'}</td>
                        </tr>
                      ))}
                    </React.Fragment>
                  ))}
                </tbody>
              </table>
            </div>
          )}

          {(form.isSubmitted || form.isValidated) && (
            <div className={`form-group ${styles.evalDataSection}`}>
              <h3 className="section-title">Test Data for Formula Validation</h3>
              {form.isSubmitted && !form.isValidated && !form.isCancelled && (
                <div className={styles.actionButtonsList}>
                  <button onClick={handleAddTestData} className="action-button primary">Add Test Data</button>
                </div>
              )}
              {formEvals.length > 0 ? (
                <div className={styles.evalTableContainer}>
                  <table className="data-table">
                    <thead>
                      <tr>
                        <th>Test / Eval ID</th>
                        {formEvals.map(evalItem => (
                          <th key={evalItem.id}>{evalItem.id} <br /><small>{evalItem.description}</small></th>
                        ))}
                      </tr>
                    </thead>
                    <tbody>
                      {formParams.map(param => (
                        <tr key={param.testId}>
                          <td>
                            <strong>{getTestName(param.testId)}</strong>
                            {param.isCalculated ? " *" : ""}
                          </td>
                          
                          {formEvals.map(evalItem => (
                            <td key={evalItem.id} className={getEvalCellClass(evalItem, param)}>
                              {renderEvalValue(evalItem, param)}
                            </td>
                          ))}
                        </tr>
                      ))}
                      {form.isSubmitted && !form.isValidated && !form.isCancelled && (
                        <tr>
                          <td><strong>Actions</strong></td>
                          {formEvals.map(evalItem => (
                            <td key={evalItem.id}>
                              <div className={styles.evalActionsContainer}>
                                <button onClick={() => handleEditEval(evalItem.id)} className="action-button edit-button small-button">Edit</button>
                                <button onClick={() => handleRequestDeleteEval(evalItem.id)} className="action-button delete-button small-button">Delete</button>
                              </div>
                            </td>
                          ))}
                        </tr>
                      )}
                    </tbody>
                  </table>
                </div>
              ) : (
                <p>No testing data present.</p>
              )}
            </div>
          )}

          <SignatureManifestBlock key={signatureRefreshKey} entityName="forms" entityId={form.id} />

          <div className={styles.formActionsBar}>
            {!form.isCancelled ? (
              <>
                {!form.isSubmitted && !form.isValidated && <button onClick={handleSubmitForm} className="action-button primary">Submit</button>}
                {form.isSubmitted && !form.isValidated && <button onClick={() => { setCommentType("validate"); setShowCommentDialog(true); }} className="action-button primary">Validate</button>}
                {form.isValidated && (
                  <>
                    <button onClick={handleDuplicateForm} className="action-button primary">Duplicate Form</button>
                    <button onClick={() => { setCommentType("cancel"); setShowCommentDialog(true); }} className="action-button delete-button">Cancel</button>
                  </>
                )}
              </>
            ) : (
              <>
                <button onClick={handleDuplicateForm} className="action-button primary">Duplicate Form</button>
                <button onClick={() => setShowConfirmReactivate(true)} className={`action-button ${styles.reactivateButton}`}>Reactivate</button>
              </>
            )}
          </div>

          <div className={styles.testNamingLegend}>
            <p className={styles.testNamingLegendTitle}><strong>Test Naming Legend:</strong></p>
            <ul className={styles.testNamingLegendList}>
              <li><strong>!</strong> - means this is a test; if missing, it is a parameter.</li>
              <li><strong>*</strong> - means this is a calculated field.</li>
              <li><strong>[type]</strong> - means it is an array; otherwise, it is a scalar.</li>
            </ul>
          </div>
        </div>

        {showFormDialog && <FormDialog open={true} formData={form} onSave={handleEditFormSave} onClose={() => setShowFormDialog(false)} />}
        {showParamDialog && <FormParamDialog open={true} formId={formId} param={editingParam} formParameters={formParams} isFormSubmitted={form.isSubmitted} onSave={handleSaveParam} onClose={() => setShowParamDialog(false)} allTests={allTests} />}
        {showNewTestDialog && <TestDialog open={true} onSave={handleSaveNewTest} onClose={() => setShowNewTestDialog(false)} />}
        {showCommentDialog && <CommentDialog open={true} onSubmit={handleCommentSubmit} onClose={() => setShowCommentDialog(false)} />}
        {showFormulaDialog && <FormulaDialog formula={selectedFormula} onClose={() => setShowFormulaDialog(false)} />}
        
        {detailViewConfig?.type === "validationForm" && (
          <FormValidationDetailView 
            formId={formId}
            evalId={detailViewConfig.evalId}
            onClose={handleValidationFormClose}
            breadcrumbs={[...breadcrumbs, `Form ${form.id}`]}
            allTests={allTests}
            form={form}
            formParams={formParams}
          />
        )}

        <ConfirmationDialog open={showConfirmDeleteParam} title="Delete Parameter" message="Are you sure you want to delete this form parameter?" onConfirm={handleDeleteParam} onCancel={() => setShowConfirmDeleteParam(false)} />
        <ConfirmationDialog open={showConfirmDeleteEval} title="Delete Test Data" message="Are you sure you want to delete this test case?" onConfirm={handleDeleteEval} onCancel={() => setShowConfirmDeleteEval(false)} />
        <ConfirmationDialog open={showConfirmReactivate} title="Reactivate Form" message="Are you sure you want to reactivate this form?" onConfirm={handleReactivateForm} onCancel={() => setShowConfirmReactivate(false)} />
        
        <NotificationDialog 
          open={!!error} 
          title="Error" 
          message={error || ""} 
          onClose={() => setError(null)} 
        />
      </DetailViewContent>
    </DetailView>
  );
};

export default FormDetailView;
