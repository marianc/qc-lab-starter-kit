import React, { useEffect, useState, useMemo } from 'react';
import { useAuthStore } from '@/store/authStore';
import Accordion from '@/components/common/ui/Accordion';
import AccordionItem from '@/components/common/ui/AccordionItem';
import NotificationDialog from '@/components/common/NotificationDialog';
import MeasurementTestDialog from './measurements/MeasurementTestDialog';
import TestResultsDetailView from './measurements/TestResultsDetailView';
import TestFormDetailView from './measurements/TestFormDetailView';
// Custom forms would be imported here
import TestingFormA from './measurements/TestingFormA'; 

import styles from './ReceptionMeasurements.module.css';
import type { ApplicableFormDto, ReceptionDetailDto } from '@/types/reception';
import type { TestDto } from '@/types/test';
import type { FormDto } from '@/types/form';
import type { MeasurementFormParamSchemaDto, MeasurementParamDetailDto, MeasurementTestDetailDto, MeasurementTestDto } from '@/types/measurement';
import receptionsService from '@/services/receptionsService';
import measurementsService from '@/services/measurementsService';

interface Props {
  reception: ReceptionDetailDto;
  breadcrumbs: string[];
  allTests: TestDto[];
  allForms: FormDto[];
}

interface DetailViewConfig {
  type: 'results' | 'formGeneric' | 'customForm';
  measurementId: number;
  formId?: number;
  customComponentName?: string;
}

const ReceptionMeasurements: React.FC<Props> = ({ 
  reception, 
  breadcrumbs, 
  allTests, 
  allForms 
}) => {
  const { user: currentUser } = useAuthStore();
  const [measurementTests, setMeasurementTests] = useState<MeasurementTestDetailDto[]>([]);
  const [measurementParams, setMeasurementParams] = useState<MeasurementParamDetailDto[]>([]);
  const [applicableForms, setApplicableForms] = useState<ApplicableFormDto[]>([]);
  const [applicableTests, setApplicableTests] = useState<{id: number, name: string}[]>([]);
  const [selectedFormId, setSelectedFormId] = useState<number>(0);
  const [showAddTestDialog, setShowAddTestDialog] = useState(false);
  const [detailViewConfig, setDetailViewConfig] = useState<DetailViewConfig | null>(null);
  const [viewMode, setViewMode] = useState<'card' | 'table'>('card');
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  useEffect(() => {
    if (reception.id > 0) {
      fetchMeasurements();
      fetchApplicableForms();
      fetchApplicableTests();
    }
  }, [reception]);

  const fetchMeasurements = async () => {
    try {
      const tests = await receptionsService.getMeasurementTests(reception.id);
      const params = await receptionsService.getMeasurementParams(reception.id);

      const enrichedParams = params.map(m => {
        const form = allForms.find(f => f.id === m.formId); // Fixed Id to id
        if (form) {
          m.formParamsSchema = form.formParams.map(fp => { // Fixed FormParams to formParams
            const test = allTests.find(t => t.id === fp.testId);
            return {
              testId: fp.testId,
              code: test?.code || 'Unknown',
              name: test?.name || 'Unknown',
              typeId: test?.typeId || 0,
              isParam: test?.isParam || false,
              isArray: test?.isArray || false,
              isCalculated: fp.isCalculated,
              defaultValue: fp.defaultValue,
              nrOrd: fp.nrOrd,
              codeRelatedArrays: fp.codeRelatedArrays,
              conditionNote: fp.conditionNote
            } as MeasurementFormParamSchemaDto;
          });
        }
        return m;
      });

      setMeasurementTests(tests);
      setMeasurementParams(enrichedParams);
    } catch (err) {
      console.error('Failed to fetch measurements:', err);
    }
  };

  const fetchApplicableForms = () => {
    const forms = allForms
      .filter(f => reception.applicableForms.includes(f.id) && f.isValidated && !f.isCancelled)
      .map(f => ({
        id: f.id,
        name: f.name,
        isCustomized: f.isCustomized,
        customNav: f.customNav || null,
        isCancelled: f.isCancelled,
        isSubmitted: f.isSubmitted,
        isValidated: f.isValidated
      }));
    setApplicableForms(forms);
  };

  const fetchApplicableTests = () => {
    const tests = allTests
      .filter(t => reception.applicableTests.includes(t.id))
      .map(t => ({ 
        id: t.id, 
        name: `${t.name} (${t.isArray ? `[${t.typeName}]` : t.typeName})`
      }));
    setApplicableTests(tests);
  };

  const toggleReportedStatus = async (mid: number) => {
    if (!currentUser) return;
    setErrorMessage(null);
    try {
      await measurementsService.toggleReported(mid);
      await fetchMeasurements();
    } catch (err: any) {
      setErrorMessage(err.message);
    }
  };

  const getTestName = (testId: number) => {
    const test = allTests.find(t => t.id === testId);
    if (!test) return 'Unknown';
    return `${test.name} (${test.isArray ? `[${test.typeName}]` : test.typeName})`;
  };

  const getTestUnit = (testId: number) => {
    const test = allTests.find(t => t.id === testId);
    return test?.unitName || '';
  };

  const getFormattedValues = (test: MeasurementTestDto) => {
    const details = allTests.find(t => t.id === test.testId);
    let values: any[] = Array.isArray(test.value) ? test.value : [test.value];

    if (!details) return values.map(v => v?.toString() || '-');

    return values.map(v => {
      if (v === null || v === undefined || v === '') return '-';
      if (details.typeId === 3) return v === 1 || v === true || v.toString().toLowerCase() === 'true' ? 'Yes' : 'No';
      if (details.typeId === 4 && details.enums) {
        const entry = details.enums.find(e => e.value.toString() === v.toString());
        return entry ? entry.name : v.toString();
      }
      return v.toString();
    });
  };

  const getDisplayValues = (m: MeasurementParamDetailDto, p: MeasurementFormParamSchemaDto) => {
    const val = m.measurementData[p.code] ?? m.calculatedResults[p.code];
    const pass = m.conditionPass[p.code];

    if (val === null || val === undefined) return [{ value: '-', conditionPass: null }];

    let values: any[] = Array.isArray(val) ? val : [val];
    let passes: any[] = Array.isArray(pass) ? pass : [pass];

    return values.map((v, i) => {
      let displayValue = '-';
      if (v !== null && v !== undefined && v !== '') {
        if (p.typeId === 3) displayValue = v === 1 || v === true || v.toString().toLowerCase() === 'true' ? 'Yes' : 'No';
        else if (p.typeId === 4) {
          const test = allTests.find(t => t.id === p.testId);
          const entry = test?.enums?.find(e => e.value.toString() === v.toString());
          displayValue = entry ? entry.name : v.toString();
        } else {
          displayValue = v.toString();
        }
      }
      
      return {
        value: displayValue,
        conditionPass: passes.length > i ? passes[i] : null
      };
    });
  };

  const groupedForms = useMemo(() => {
    const groups: Record<number, MeasurementParamDetailDto[]> = {};
    measurementParams.forEach(m => {
      if (!groups[m.formId]) groups[m.formId] = [];
      groups[m.formId].push(m);
    });
    return groups;
  }, [measurementParams]);

  const getFormDescription = (formId: number) => {
    const app = applicableForms.find(f => f.id === formId);
    if (app) return app.name;
    const hist = allForms.find(f => f.id === formId);
    return hist ? hist.name + '?' : 'Unknown Form';
  };

  const addTestingForm = () => {
    setErrorMessage(null);
    if (selectedFormId > 0) {
      const form = applicableForms.find(f => f.id === selectedFormId);
      if (form?.isCustomized && form.customNav) {
        setDetailViewConfig({ type: 'customForm', measurementId: 0, formId: selectedFormId, customComponentName: form.customNav });
      } else {
        setDetailViewConfig({ type: 'formGeneric', measurementId: 0, formId: selectedFormId });
      }
    }
  };

  const handleSaveNewTest = async (t: MeasurementTestDto) => {
    if (!currentUser) return;
    setErrorMessage(null);
    try {
      const res = await measurementsService.createMeasurement({
        receptionId: reception.id,
        isReported: false,
        comments: null,
        formId: null
      });
      await measurementsService.addMeasurementTest(res.id, {
        testId: t.testId,
        value: t.value,
        note: t.note
      });
      setShowAddTestDialog(false);
      fetchMeasurements();
    } catch (err: any) {
      setErrorMessage(err.message);
    }
  };

  const renderDetailView = () => {
    if (!detailViewConfig) return null;

    const commonProps = {
      measurementId: detailViewConfig.measurementId,
      receptionId: reception.id,
      onClose: () => { setErrorMessage(null); setDetailViewConfig(null); fetchMeasurements(); },
      breadcrumbs: [...breadcrumbs, `Reception ${reception.id}`],
      allTests,
      allForms,
      reception
    };

    if (detailViewConfig.type === 'results') {
      return <TestResultsDetailView {...commonProps} />;
    }

    if (detailViewConfig.type === 'formGeneric') {
      return <TestFormDetailView {...commonProps} formId={detailViewConfig.formId!} />;
    }

    if (detailViewConfig.type === 'customForm') {
      // Manual mapping of custom components
      if (detailViewConfig.customComponentName === 'TestingFormA') {
        return <TestingFormA {...commonProps} formId={detailViewConfig.formId!} />;
      }
      // Fallback
      return <TestFormDetailView {...commonProps} formId={detailViewConfig.formId!} />;
    }

    return null;
  };

  if (!reception.isReceived) return null;

  return (
    <div className={styles.receptionMeasurements}>
      <div className={styles.formGroup}>
        <button onClick={() => { setErrorMessage(null); setShowAddTestDialog(true); }} className="action-button primary">Add Test Results</button>
        <h3>Test Results</h3>
        {measurementTests.length > 0 ? (
          <table className="data-table">
            <thead>
              <tr>
                <th>Id</th>
                <th>Test</th>
                <th>Unit</th>
                <th>Value</th>
                <th>Note</th>
                <th>Comments</th>
                <th>Reported</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {[...measurementTests].sort((a, b) => a.id - b.id).map(m => (
                <React.Fragment key={m.id}>
                  {(m.tests || []).map((t, idx) => (
                    <tr key={`${m.id}-${idx}`}>
                      {idx === 0 && <td rowSpan={m.tests?.length}>{m.id}</td>}
                      <td>{getTestName(t.testId)}</td>
                      <td>{getTestUnit(t.testId)}</td>
                      <td>
                        {getFormattedValues(t).map((val, vidx) => (
                          <div key={vidx}>{val}</div>
                        ))}
                      </td>
                      <td>{t.note}</td>
                      {idx === 0 && (
                        <>
                          <td rowSpan={m.tests?.length} title={m.comments || ''}>
                            {m.comments && m.comments.length > 15 ? m.comments.substring(0, 15) + '...' : m.comments}
                          </td>
                          <td rowSpan={m.tests?.length}>
                            <button 
                              onClick={() => toggleReportedStatus(m.id)}
                              className={`action-button ${m.isReported ? styles.buttonGreen : styles.buttonGray}`}
                            >
                              {m.isReported ? 'Yes' : 'No'}
                            </button>
                          </td>
                          <td rowSpan={m.tests?.length}>
                            <button 
                              onClick={() => setDetailViewConfig({ type: 'results', measurementId: m.id })}
                              className={`action-button ${m.isReadonly ? 'secondary' : 'edit-button'} small-button`}
                            >
                              {m.isReadonly ? 'View' : 'Edit'}
                            </button>
                          </td>
                        </>
                      )}
                    </tr>
                  ))}
                </React.Fragment>
              ))}
            </tbody>
          </table>
        ) : (
          <p>No test results found.</p>
        )}
      </div>

      <div className={styles.formGroup}>
        <h3>Testing Form</h3>
        <div className={styles.formSelectionRow}>
          <select 
            value={selectedFormId} 
            onChange={e => setSelectedFormId(parseInt(e.target.value))} 
            className={`form-control ${styles.formSelectFixed}`}
          >
            <option value="0">-- Select Form --</option>
            {applicableForms.map(f => (
              <option key={f.id} value={f.id}>{f.name}{f.isSubmitted && !f.isValidated ? ' - beta' : ''}</option>
            ))}
          </select>
          <button 
            onClick={addTestingForm} 
            disabled={selectedFormId === 0} 
            className="action-button primary"
          >
            Add Testing Form
          </button>
          <button 
            onClick={() => setViewMode(prev => prev === 'card' ? 'table' : 'card')} 
            className="action-button secondary"
          >
            Switch to {viewMode === 'card' ? 'Table' : 'Card'} View
          </button>
        </div>

        <Accordion title="Forms List">
          {Object.entries(groupedForms).sort((a, b) => parseInt(a[0]) - parseInt(b[0])).map(([formId, originalItems]) => {
            const items = [...originalItems].sort((a, b) => a.id - b.id);
            return (
              <AccordionItem key={formId} title={getFormDescription(parseInt(formId))}>
                {viewMode === 'card' ? (
                  <div className={styles.cardContainer}>
                    {items.map(m => (
                      <div className={styles.card} key={m.id}>
                        <div className={styles.measurementId}>{m.id}</div>
                        <div className={styles.cardContent}>
                          {m.formParamsSchema?.map(p => (
                            <div className={styles.cardItem} key={p.testId}>
                              <span className={styles.cardItemLabel}>
                                {p.name}{p.isCalculated ? '*' : ''}{!p.isParam ? '!' : ''}:
                              </span>
                              <div className={styles.cardItemValue}>
                                {getDisplayValues(m, p).map((v, vidx) => (
                                  <div key={vidx}>
                                    {v.value}
                                    {v.conditionPass === false && p.conditionNote && (
                                      <span className={styles.conditionNote}> {p.conditionNote}</span>
                                    )}
                                  </div>
                                ))}
                              </div>
                            </div>
                          ))}
                          <div className={styles.cardComments}>
                            <strong className={styles.cardCommentsLabel}>Comments:</strong>
                            <div className={styles.cardCommentsValue}>{m.comments}</div>
                          </div>
                        </div>
                        <div className={styles.cardActions}>
                          <button 
                            onClick={() => toggleReportedStatus(m.id)}
                            className={`action-button ${m.isReported ? styles.buttonGreen : styles.buttonGray}`}
                          >
                            {m.isReported ? 'Yes' : 'No'}
                          </button>
                          <button 
                            onClick={() => {
                              const form = applicableForms.find(f => f.id === m.formId);
                              if (form?.isCustomized && form.customNav) {
                                setDetailViewConfig({ type: 'customForm', measurementId: m.id, formId: m.formId, customComponentName: form.customNav });
                              } else {
                                setDetailViewConfig({ type: 'formGeneric', measurementId: m.id, formId: m.formId });
                              }
                            }}
                            className={`action-button ${m.isReadonly ? 'secondary' : 'edit-button'} small-button`}
                          >
                            {m.isReadonly ? 'View' : 'Edit'}
                          </button>
                        </div>
                      </div>
                    ))}
                  </div>
                ) : (
                  <div className={styles.tableScrollContainer}>
                    <table className="data-table">
                      <thead>
                        <tr>
                          <th className={styles.tableTestHeaderCol}>Test / Measurement ID</th>
                          {items.map(m => <th key={m.id} className={styles.tableMeasurementCol}>{m.id}</th>)}
                        </tr>
                      </thead>
                      <tbody>
                        {items[0]?.formParamsSchema?.map(p => (
                          <tr key={p.code}>
                            <td className={styles.tableTestHeaderCol}>
                              <strong>{p.name}</strong>
                              {p.isCalculated ? '*' : ''}
                              {!p.isParam ? '!' : ''}
                            </td>
                            {items.map(m => (
                              <td key={m.id} className={styles.tableMeasurementCol}>
                                {getDisplayValues(m, p).map((v, vidx) => (
                                  <div key={vidx}>
                                    {v.value}
                                    {v.conditionPass === false && p.conditionNote && (
                                      <span className={styles.conditionNote}> {p.conditionNote}</span>
                                    )}
                                  </div>
                                ))}
                              </td>
                            ))}
                          </tr>
                        ))}
                        <tr>
                          <td><strong>Comments</strong></td>
                          {items.map(m => (
                            <td key={m.id} className={styles.tableMeasurementCol}>
                              <div className={styles.tableCommentsValue}>{m.comments}</div>
                            </td>
                          ))}
                        </tr>
                        <tr>
                          <td><strong>Actions</strong></td>
                          {items.map(m => (
                            <td key={m.id} className={styles.tableMeasurementCol}>
                              <div className={styles.actionsCellContainer}>
                                <button 
                                  onClick={() => toggleReportedStatus(m.id)}
                                  className={`action-button ${m.isReported ? styles.buttonGreen : styles.buttonGray} small-button`}
                                >
                                  {m.isReported ? 'Yes' : 'No'}
                                </button>
                                <button 
                                  onClick={() => {
                                    const form = applicableForms.find(f => f.id === m.formId);
                                    if (form?.isCustomized && form.customNav) {
                                      setDetailViewConfig({ type: 'customForm', measurementId: m.id, formId: m.formId, customComponentName: form.customNav });
                                    } else {
                                      setDetailViewConfig({ type: 'formGeneric', measurementId: m.id, formId: m.formId });
                                    }
                                  }}
                                  className={`action-button ${m.isReadonly ? 'secondary' : 'edit-button'} small-button`}
                                >
                                  {m.isReadonly ? 'View' : 'Edit'}
                                </button>
                              </div>
                            </td>
                          ))}
                        </tr>
                      </tbody>
                    </table>
                  </div>
                )}
              </AccordionItem>
            );
          })}
        </Accordion>
      </div>

      {showAddTestDialog && (
        <MeasurementTestDialog 
          open={true}
          availableTests={applicableTests}
          allTests={allTests}
          onSave={handleSaveNewTest}
          onClose={() => setShowAddTestDialog(false)}
        />
      )}

      {renderDetailView()}

      <NotificationDialog 
        open={!!errorMessage}
        title="Error"
        message={errorMessage || ''}
        onClose={() => setErrorMessage(null)}
      />
    </div>
  );
};

export default ReceptionMeasurements;
