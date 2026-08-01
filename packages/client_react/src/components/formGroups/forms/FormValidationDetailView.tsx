import React, { useState, useEffect, useMemo } from 'react';
import { 
  DetailView, 
  DetailViewHeader, 
  DetailViewContent 
} from '../../common/ui';
import ArrayItemDialog from '../../common/ArrayItemDialog';
import type { TestDto, TestEnumDto } from '@/types/test';
import type { FormDetailDto, FormParamDto } from '@/types/form';
import type { FormEvalDto } from '@/types/formEval';
import testsService from '@/services/testsService';
import formsService from '@/services/formsService';
import formEvalsService from '@/services/formEvalsService';

interface FormValidationDetailViewProps {
  formId: number;
  evalId?: number | null;
  onClose: () => void;
  breadcrumbs?: string[];
  allTests: TestDto[];
  form?: FormDetailDto | null;
  formParams?: FormParamDto[];
}

const FormValidationDetailView: React.FC<FormValidationDetailViewProps> = ({
  formId,
  evalId,
  onClose,
  breadcrumbs = [],
  allTests: initialAllTests,
  form: initialForm,
  formParams: initialFormParams
}) => {
  const [evalData, setEvalData] = useState<FormEvalDto | null>(null);
  const [formData, setFormData] = useState<Record<string, any>>({});
  const [expectedValues, setExpectedValues] = useState<Record<string, any>>({});
  const [allFormParams, setAllFormParams] = useState<FormParamDto[]>(initialFormParams || []);
  const [allTests, setAllTests] = useState<TestDto[]>(initialAllTests);
  const [formName, setFormName] = useState("");
  const [allFormParamEnums, setAllFormParamEnums] = useState<TestEnumDto[]>([]);

  const [showArrayItemDialog, setShowArrayItemDialog] = useState(false);
  const [groupedParamsForDialog, setGroupedParamsForDialog] = useState<FormParamDto[]>([]);
  const [editingArrayIndex, setEditingArrayIndex] = useState(-1);
  const [initialArrayItemValue, setInitialArrayItemValue] = useState<Record<string, any>>({});
  const [isEditingExpected, setIsEditingExpected] = useState(false);

  const inputParams = useMemo(() => allFormParams.filter(p => !p.isCalculated), [allFormParams]);
  const calculatedParams = useMemo(() => allFormParams.filter(p => p.isCalculated), [allFormParams]);

  const nonArrayParams = useMemo(() => inputParams.filter(p => !p.isArray), [inputParams]);
  const standaloneArrayParams = useMemo(() => inputParams.filter(p => p.isArray && !p.codeRelatedArrays), [inputParams]);
  const groupedArrayParams = useMemo(() => {
    const groups: Record<string, FormParamDto[]> = {};
    inputParams.filter(p => p.isArray && p.codeRelatedArrays).forEach(p => {
      const key = p.codeRelatedArrays!;
      if (!groups[key]) groups[key] = [];
      groups[key].push(p);
    });
    return groups;
  }, [inputParams]);

  const nonArrayCalculatedParams = useMemo(() => calculatedParams.filter(p => !p.isArray), [calculatedParams]);
  const standaloneArrayCalculatedParams = useMemo(() => calculatedParams.filter(p => p.isArray && !p.codeRelatedArrays), [calculatedParams]);
  const groupedArrayCalculatedParams = useMemo(() => {
    const groups: Record<string, FormParamDto[]> = {};
    calculatedParams.filter(p => p.isArray && p.codeRelatedArrays).forEach(p => {
      const key = p.codeRelatedArrays!;
      if (!groups[key]) groups[key] = [];
      groups[key].push(p);
    });
    return groups;
  }, [calculatedParams]);

  const loadInitialData = async () => {
    let tests = initialAllTests;
    if (!tests || tests.length === 0) {
      tests = await testsService.getAllTests();
      setAllTests(tests);
    }

    if (initialForm) {
      setFormName(initialForm.name);
    } else {
      const f = await formsService.getForm(formId);
      setFormName(f.name);
    }

    let params = initialFormParams;
    if (!params) {
      params = await formsService.getFormParams(formId);
      setAllFormParams(params);
    }

    const enums = tests
      .filter(t => t.typeId === 4 && t.enums)
      .flatMap(t => t.enums!);
    setAllFormParamEnums(enums);

    if (evalId && evalId > 0) {
      const e = await formEvalsService.getFormEval(evalId);
      setEvalData(e);
      processEvalData(e, params!);
    } else {
      setEvalData({ id: 0, formId, description: "" } as any);
      const initialFData: Record<string, any> = {};
      const initialEData: Record<string, any> = {};
      params!.forEach(p => {
        if (!p.isCalculated) {
          if (p.isArray) initialFData[p.code] = [];
          else initialFData[p.code] = null;
        } else {
          if (p.isArray) initialEData[p.code] = [];
          else initialEData[p.code] = null;
        }
      });
      setFormData(initialFData);
      setExpectedValues(initialEData);
    }
  };

  useEffect(() => {
    loadInitialData();
  }, [formId, evalId]);

  const processEvalData = (e: FormEvalDto, params: FormParamDto[]) => {
    const fData: Record<string, any> = {};
    const eData: Record<string, any> = {};

    if (e.measurementData) {
      Object.entries(e.measurementData).forEach(([key, val]) => {
        fData[key] = val;
      });
    }

    if (e.expectedResults) {
      Object.entries(e.expectedResults).forEach(([key, val]) => {
        if (val) eData[key] = val.value;
      });
    }

    params.forEach(p => {
      if (!p.isCalculated && p.isArray && !fData[p.code]) fData[p.code] = [];
      if (p.isCalculated && p.isArray && !eData[p.code]) eData[p.code] = [];
    });

    setFormData(fData);
    setExpectedValues(eData);
  };

  const getTestDisplayName = (testId: number) => {
    const test = allTests.find(t => t.id === testId);
    if (!test) return "-";
    const paramSuffix = !test.isParam ? "!" : "";
    const typeName = test.isArray ? `[${test.typeName}]` : test.typeName;
    return `${test.name}${paramSuffix} (${test.code}, ${typeName})`;
  };

  const handleFormChange = (code: string, val: any) => {
    setFormData(prev => ({ ...prev, [code]: val }));
  };

  const handleExpectedChange = (code: string, val: any) => {
    setExpectedValues(prev => ({ ...prev, [code]: val }));
  };

  const getDisplayValue = (param: FormParamDto, val: any) => {
    if (val === null || val === undefined || val === "") return "";
    if (param.typeId === 3) {
      return (val === 1 || val === "1" || String(val).toLowerCase() === "true") ? "Yes" : "No";
    }
    if (param.typeId === 4) {
      return allFormParamEnums.find(e => e.testId === param.testId && String(e.value) === String(val))?.name ?? String(val);
    }
    return String(val);
  };

  const openArrayItemDialog = (param: FormParamDto, expected = false) => {
    setIsEditingExpected(expected);
    setEditingArrayIndex(-1);
    setInitialArrayItemValue({});
    const paramsList = expected ? calculatedParams : inputParams;

    if (param.codeRelatedArrays) {
      setGroupedParamsForDialog(paramsList.filter(p => p.isArray && p.codeRelatedArrays === param.codeRelatedArrays));
    } else {
      setGroupedParamsForDialog([param]);
    }
    setShowArrayItemDialog(true);
  };

  const editArrayItem = (param: FormParamDto, idx: number, expected = false) => {
    setIsEditingExpected(expected);
    setEditingArrayIndex(idx);
    const paramsList = expected ? calculatedParams : inputParams;
    const initial: Record<string, any> = {};

    let group: FormParamDto[];
    if (param.codeRelatedArrays) {
      group = paramsList.filter(p => p.isArray && p.codeRelatedArrays === param.codeRelatedArrays);
    } else {
      group = [param];
    }

    const sourceDict = expected ? expectedValues : formData;
    group.forEach(p => {
      const list = sourceDict[p.code] || [];
      initial[p.code] = list[idx];
    });

    setGroupedParamsForDialog(group);
    setInitialArrayItemValue(initial);
    setShowArrayItemDialog(true);
  };

  const handleArrayItemSave = (itemValues: Record<string, any>) => {
    const targetSetter = isEditingExpected ? setExpectedValues : setFormData;
    
    targetSetter(prev => {
      const next = { ...prev };
      groupedParamsForDialog.forEach(p => {
        const list = [...(next[p.code] || [])];
        if (editingArrayIndex === -1) {
          list.push(itemValues[p.code]);
        } else {
          list[editingArrayIndex] = itemValues[p.code];
        }
        next[p.code] = list;
      });
      return next;
    });

    setShowArrayItemDialog(false);
  };

  const deleteArrayItem = (param: FormParamDto, idx: number, expected = false) => {
    const targetSetter = expected ? setExpectedValues : setFormData;
    const paramsList = expected ? calculatedParams : inputParams;
    
    let group: FormParamDto[];
    if (param.codeRelatedArrays) {
      group = paramsList.filter(p => p.isArray && p.codeRelatedArrays === param.codeRelatedArrays);
    } else {
      group = [param];
    }

    targetSetter(prev => {
      const next = { ...prev };
      group.forEach(p => {
        const list = [...(next[p.code] || [])];
        if (idx < list.length) list.splice(idx, 1);
        next[p.code] = list;
      });
      return next;
    });
  };

  const handleSave = async () => {
    if (!evalData) return;

    let currentEvalId = evalData.id;
    if (currentEvalId === 0) {
      const res = await formEvalsService.createFormEval({
        formId,
        description: evalData.description
      });
      currentEvalId = res.id;
    }

    const cleanNumeric = (val: any) => {
      if (val === null || val === undefined) return null;
      if (Array.isArray(val)) return val.map(v => v === null ? null : Number(v));
      return val === "" ? null : Number(val);
    };

    const measurementData: Record<string, any> = {};
    inputParams.forEach(p => {
      measurementData[p.code] = cleanNumeric(formData[p.code]);
    });

    const expectedResults: Record<string, any> = {};
    calculatedParams.forEach(p => {
      expectedResults[p.code] = cleanNumeric(expectedValues[p.code]);
    });

    await formEvalsService.updateFormEval(currentEvalId, {
      description: evalData.description,
      measurementData,
      expectedResults
    });

    onClose();
  };

  const handleDeleteEval = async () => {
    if (evalId && evalId > 0) {
      await formEvalsService.deleteFormEval(evalId);
      onClose();
    }
  };

  if (!evalData) return <div>Loading...</div>;

  return (
    <DetailView>
      <DetailViewHeader 
        title={`Validation Data (${evalId && evalId > 0 ? evalId : "New"}): ${formName}`} 
        onBack={onClose} 
        breadcrumbs={breadcrumbs} 
      />
      <DetailViewContent>
        <div className="page-container">
          <div className="form-group">
            <label htmlFor="description">Description (Test Case Name):</label>
            <input 
              id="description" 
              type="text" 
              className="form-control" 
              placeholder="e.g. Test Case 1"
              value={evalData.description || ""}
              onChange={e => setEvalData({...evalData, description: e.target.value})}
            />
          </div>

          <h2>Input Data (Non-Calculated)</h2>
          {nonArrayParams.map(param => (
            <div key={param.testId} className="form-group">
              <label htmlFor={param.code}>{getTestDisplayName(param.testId)}:</label>
              {param.typeId === 1 || param.typeId === 2 ? (
                <input 
                  type="number" 
                  id={param.code} 
                  className="form-control"
                  value={formData[param.code] ?? ""}
                  onChange={e => handleFormChange(param.code, e.target.value)}
                />
              ) : param.typeId === 3 ? (
                <select 
                  id={param.code} 
                  className="form-control"
                  value={formData[param.code] ?? ""}
                  onChange={e => handleFormChange(param.code, e.target.value)}
                >
                  <option value="">-- No Selection --</option>
                  <option value="1">Yes</option>
                  <option value="0">No</option>
                </select>
              ) : param.typeId === 4 ? (
                <select 
                  id={param.code} 
                  className="form-control"
                  value={formData[param.code] ?? ""}
                  onChange={e => handleFormChange(param.code, e.target.value)}
                >
                  <option value="">-- Select --</option>
                  {allFormParamEnums.filter(en => en.testId === param.testId).map(enumItem => (
                    <option key={enumItem.value} value={enumItem.value}>{enumItem.name}</option>
                  ))}
                </select>
              ) : null}
            </div>
          ))}

          {standaloneArrayParams.map(param => (
            <div key={param.testId} className="form-group">
              <p>Array parameter: {getTestDisplayName(param.testId)}</p>
              <button onClick={() => openArrayItemDialog(param)} className="action-button primary small-button">+</button>
              <table className="data-table">
                <tbody>
                  {(formData[param.code] || []).map((val: any, idx: number) => (
                    <tr key={idx}>
                      <td>{getDisplayValue(param, val)}</td>
                      <td>
                        <button onClick={() => editArrayItem(param, idx)} className="action-button edit-button small-button">Edit</button>
                        <button onClick={() => deleteArrayItem(param, idx)} className="action-button delete-button small-button">Delete</button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          ))}

          {Object.entries(groupedArrayParams).map(([groupKey, groupParams]) => (
            <div key={groupKey} className="form-group">
              <p>Array parameter group: {groupKey}</p>
              <button onClick={() => openArrayItemDialog(groupParams[0])} className="action-button primary small-button">+</button>
              <table className="data-table">
                <thead>
                  <tr>
                    {groupParams.map(p => <th key={p.testId}>{getTestDisplayName(p.testId)}</th>)}
                    <th>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {(formData[groupParams[0].code] || []).map((_: any, idx: number) => (
                    <tr key={idx}>
                      {groupParams.map(p => (
                        <td key={p.testId}>{getDisplayValue(p, (formData[p.code] || [])[idx])}</td>
                      ))}
                      <td>
                        <button onClick={() => editArrayItem(groupParams[0], idx)} className="action-button edit-button small-button">Edit</button>
                        <button onClick={() => deleteArrayItem(groupParams[0], idx)} className="action-button delete-button small-button">Delete</button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          ))}

          <h2>Expected Results (Calculated)</h2>
          {nonArrayCalculatedParams.map(param => (
            <div key={param.testId} className="form-group">
              <label htmlFor={`expected_${param.code}`}>{getTestDisplayName(param.testId)} (Expected Value):</label>
              {param.typeId === 1 || param.typeId === 2 ? (
                <input 
                  type="number" 
                  id={`expected_${param.code}`} 
                  className="form-control"
                  value={expectedValues[param.code] ?? ""}
                  onChange={e => handleExpectedChange(param.code, e.target.value)}
                />
              ) : param.typeId === 3 ? (
                <select 
                  id={`expected_${param.code}`} 
                  className="form-control"
                  value={expectedValues[param.code] ?? ""}
                  onChange={e => handleExpectedChange(param.code, e.target.value)}
                >
                  <option value="">-- No Selection --</option>
                  <option value="1">Yes</option>
                  <option value="0">No</option>
                </select>
              ) : param.typeId === 4 ? (
                <select 
                  id={`expected_${param.code}`} 
                  className="form-control"
                  value={expectedValues[param.code] ?? ""}
                  onChange={e => handleExpectedChange(param.code, e.target.value)}
                >
                  <option value="">-- Select --</option>
                  {allFormParamEnums.filter(en => en.testId === param.testId).map(enumItem => (
                    <option key={enumItem.value} value={enumItem.value}>{enumItem.name}</option>
                  ))}
                </select>
              ) : null}
            </div>
          ))}

          {standaloneArrayCalculatedParams.map(param => (
            <div key={param.testId} className="form-group">
              <p>Array parameter expected results: {getTestDisplayName(param.testId)}</p>
              <button onClick={() => openArrayItemDialog(param, true)} className="action-button primary small-button">+</button>
              <table className="data-table">
                <tbody>
                  {(expectedValues[param.code] || []).map((val: any, idx: number) => (
                    <tr key={idx}>
                      <td>{getDisplayValue(param, val)}</td>
                      <td>
                        <button onClick={() => editArrayItem(param, idx, true)} className="action-button edit-button small-button">Edit</button>
                        <button onClick={() => deleteArrayItem(param, idx, true)} className="action-button delete-button small-button">Delete</button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          ))}

          {Object.entries(groupedArrayCalculatedParams).map(([groupKey, groupParams]) => (
            <div key={groupKey} className="form-group">
              <p>Array parameter group expected results: {groupKey}</p>
              <button onClick={() => openArrayItemDialog(groupParams[0], true)} className="action-button primary small-button">+</button>
              <table className="data-table">
                <thead>
                  <tr>
                    {groupParams.map(p => <th key={p.testId}>{getTestDisplayName(p.testId)}</th>)}
                    <th>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {(expectedValues[groupParams[0].code] || []).map((_: any, idx: number) => (
                    <tr key={idx}>
                      {groupParams.map(p => (
                        <td key={p.testId}>{getDisplayValue(p, (expectedValues[p.code] || [])[idx])}</td>
                      ))}
                      <td>
                        <button onClick={() => editArrayItem(groupParams[0], idx, true)} className="action-button edit-button small-button">Edit</button>
                        <button onClick={() => deleteArrayItem(groupParams[0], idx, true)} className="action-button delete-button small-button">Delete</button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          ))}

          <div className="form-actions-bar">
            <button onClick={handleSave} className="action-button primary">Save and Calculate</button>
            <button onClick={onClose} className="action-button secondary">Cancel</button>
            {evalId && evalId > 0 && (
              <button onClick={handleDeleteEval} className="action-button delete-button">Delete</button>
            )}
          </div>
        </div>

        {showArrayItemDialog && (
          <ArrayItemDialog 
            open={true}
            groupedParams={groupedParamsForDialog}
            initialValues={initialArrayItemValue}
            allFormParamEnums={allFormParamEnums}
            isEditing={editingArrayIndex !== -1}
            onSave={handleArrayItemSave}
            onClose={() => setShowArrayItemDialog(false)}
          />
        )}
      </DetailViewContent>
    </DetailView>
  );
};

export default FormValidationDetailView;
