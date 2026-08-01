import React, { useEffect, useState } from 'react';
import { useForm, useFieldArray } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import * as z from 'zod';
import { Dialog, DialogHeader, DialogContent, DialogFooter } from '../../common/ui';
import styles from './FormParamDialog.module.css';
import type { FormConditionEvalDto, FormParamDto } from '@/types/form';
import type { TestDto } from '@/types/test';
import formsService from '@/services/formsService';
import { formParamSchema } from '@/lib/schemas/formParam';

interface FormParamDialogProps {
  open: boolean;
  formId: number;
  param?: FormParamDto | null;
  formParameters: FormParamDto[];
  isFormSubmitted: boolean;
  allTests: TestDto[];
  onSave: (data: FormParamDto) => void;
  onClose: () => void;
}

type FormParamValues = z.infer<typeof formParamSchema>;

const FormParamDialog: React.FC<FormParamDialogProps> = ({ 
  open, 
  formId,
  param, 
  formParameters, 
  isFormSubmitted, 
  allTests,
  onSave, 
  onClose 
}) => {
  const [isValidating, setIsValidating] = useState(false);
  const [isValidatingCondition, setIsValidatingCondition] = useState(false);
  const [formulaError, setFormulaError] = useState<string | null>(null);
  const [testEnums, setTestEnums] = useState<any[]>([]);

  const {
    register,
    control,
    handleSubmit,
    reset,
    watch,
    setValue,
    clearErrors,
    setError,
    formState: { errors }
  } = useForm<FormParamValues>({
    resolver: zodResolver(formParamSchema) as any,
    defaultValues: {
      testId: 0,
      isCalculated: false,
      formula: '',
      codeRelatedArrays: '',
      isRequired: false,
      defaultValue: null,
      nrOrd: 0,
      nrOrdCalc: 0,
      hasCondition: false,
      condition: '',
      conditionNote: '',
      evals: []
    }
  });

  const { fields, append, remove } = useFieldArray({
    control,
    name: 'evals'
  });

  const watchIsCalculated = watch('isCalculated');
  const watchTestId = watch('testId');
  const watchIsRequired = watch('isRequired');
  const watchHasCondition = watch('hasCondition');

  const selectedTest = allTests.find(t => t.id === Number(watchTestId));
  const filteredAvailableTests = allTests.filter(t => !formParameters.some(p => p.testId === t.id) || (param && t.id === param.testId));

  const getTestName = (testId: number) => {
    const test = allTests.find(t => t.id === testId);
    if (!test) return "Unknown Test";
    const paramSuffix = !test.isParam ? "!" : "";
    const typeName = test.isArray ? `[${test.typeName}]` : test.typeName;
    return `${test.name}${paramSuffix} (${test.code}, ${typeName})`;
  };

  useEffect(() => {
    if (open) {
      if (param) {
        reset({
          testId: param.testId,
          isCalculated: param.isCalculated,
          formula: param.formula || '',
          codeRelatedArrays: param.codeRelatedArrays || '',
          isRequired: param.isRequired,
          defaultValue: param.defaultValue,
          nrOrd: param.nrOrd,
          nrOrdCalc: param.nrOrdCalc,
          hasCondition: param.hasCondition || false,
          condition: param.condition || '',
          conditionNote: param.conditionNote || '',
          evals: param.evals?.map((e: FormConditionEvalDto) => ({
            id: e.id,
            value: e.value,
            expectedResult: e.expectedResult,
            note: e.note
          })) || []
        });
        handleTestIdChange(param.testId, false);
      } else {
        reset({
          testId: 0,
          isCalculated: false,
          formula: '',
          codeRelatedArrays: '',
          isRequired: false,
          defaultValue: null,
          nrOrd: formParameters.length + 1,
          nrOrdCalc: 0,
          hasCondition: false,
          condition: '',
          conditionNote: '',
          evals: []
        });
        setTestEnums([]);
      }
      setFormulaError(null);
    }
  }, [open, param, reset, formParameters]);

  const handleTestIdChange = (testId: number, clearDefault: boolean = true) => {
    if (clearDefault) setValue('defaultValue', null);
    const test = allTests.find(t => t.id === testId);
    if (test?.typeId === 4 && test.enums) {
      setTestEnums(test.enums);
    } else {
      setTestEnums([]);
    }
  };

  const onIsCalculatedChanged = (e: React.ChangeEvent<HTMLInputElement>) => {
    const checked = e.target.checked;
    setValue('isCalculated', checked);
    if (checked) {
      setValue('isRequired', false);
      setValue('defaultValue', null);

      const availableCodes = formParameters
        .filter(fp => fp.testId !== Number(watchTestId))
        .map(fp => {
          const test = allTests.find(t => t.id === fp.testId);
          return test ? (test.isArray ? `[[${test.code}]]` : `[${test.code}]`) : "";
        })
        .filter(s => !!s);

      if (availableCodes.length > 0 && !watch('formula')) {
        setValue('formula', "// " + availableCodes.join(", ") + "\n");
      }
      setValue('codeRelatedArrays', null);
    } else {
      setValue('formula', null);
    }
  };

  const onIsRequiredChanged = (e: React.ChangeEvent<HTMLInputElement>) => {
    const checked = e.target.checked;
    setValue('isRequired', checked);
    if (checked) {
      setValue('isCalculated', false);
      setValue('formula', null);
    }
  };

  const onHasConditionChanged = (e: React.ChangeEvent<HTMLInputElement>) => {
    const checked = e.target.checked;
    setValue('hasCondition', checked);
    if (!checked) {
      setValue('condition', '');
      setValue('conditionNote', '');
      setValue('evals', []);
      clearErrors('condition');
    } else {
      setValue('condition', '[value] > 0');
      setValue('conditionNote', '');
      let defaultVal = 0;
      if (selectedTest) {
        if (selectedTest.typeId === 3) defaultVal = 1;
        else if (selectedTest.typeId === 4 && selectedTest.enums?.length)
          defaultVal = selectedTest.enums[0].value;
      }
      setValue('evals', [{ value: defaultVal, expectedResult: 1, note: '' }]);
    }
  };

  const handleConditionBlur = async (e: React.FocusEvent<HTMLInputElement>) => {
    const condition = e.target.value;
    if (!condition) return;

    setIsValidatingCondition(true);
    try {
      await formsService.validateCondition(condition);
      clearErrors('condition');
    } catch (err: any) {
      setError('condition', { type: 'manual', message: err.message });
    } finally {
      setIsValidatingCondition(false);
    }
  };

  const validateFormula = async (formula: string | null, isCalculated: boolean, testId: number): Promise<boolean> => {
    if (!isCalculated) return true;
    if (!formula || formula.trim() === '') {
      setFormulaError("Formula is required for calculated parameters.");
      return false;
    }
    setIsValidating(true);
    setFormulaError(null);
    try {
      await formsService.validateFormula(formId, testId, isCalculated, formula);
      return true;
    } catch (err: any) {
      setFormulaError(err.message);
      return false;
    } finally {
      setIsValidating(false);
    }
  };

  const addEval = () => {
    let newVal = 0;
    if (selectedTest) {
      if (selectedTest.typeId === 3) newVal = 1;
      else if (selectedTest.typeId === 4 && selectedTest.enums?.length)
        newVal = selectedTest.enums[0].value;
    }
    append({ value: newVal, expectedResult: 1, note: '' });
  };

  const onSubmit = async (values: FormParamValues) => {
    const isFormulaValid = await validateFormula(values.formula || '', values.isCalculated, values.testId);
    let isConditionValid = true;

    if (values.hasCondition && values.condition) {
      setIsValidatingCondition(true);
      try {
        await formsService.validateCondition(values.condition);
        clearErrors('condition');
      } catch (err: any) {
        setError('condition', { type: 'manual', message: err.message });
        isConditionValid = false;
      } finally {
        setIsValidatingCondition(false);
      }
    }

    if (isFormulaValid && isConditionValid) {
      const paramToSave: FormParamDto = {
        ...param!,
        testId: values.testId,
        isCalculated: values.isCalculated,
        formula: values.formula || null,
        codeRelatedArrays: values.codeRelatedArrays || null,
        isRequired: values.isRequired,
        defaultValue: values.defaultValue || null,
        nrOrd: values.nrOrd,
        nrOrdCalc: values.nrOrdCalc,
        code: param?.code || '',
        name: param?.name || '',
        typeId: param?.typeId || 0,
        isArray: param?.isArray || false,
        dependencies: param?.dependencies || '',
        isFormSubmitted: param?.isFormSubmitted || false,
        hasCondition: values.hasCondition,
        condition: values.hasCondition ? (values.condition || null) : null,
        conditionNote: values.hasCondition ? (values.conditionNote || null) : null,
        evals: values.hasCondition ? (values.evals || []).map(e => ({
          id: e.id || 0,
          formId: formId,
          testId: values.testId,
          value: e.value,
          result: null,
          expectedResult: e.expectedResult,
          isMatch: false,
          note: e.note || null
        })) : []
      };
      onSave(paramToSave);
    }
  };

  return (
    <Dialog open={open} onClose={onClose}>
      <DialogHeader>
        {param ? "Edit" : "Add"} Form Parameter
      </DialogHeader>
      <form onSubmit={handleSubmit(onSubmit)} className={styles.formParamEditForm}>
        <DialogContent>
          <div className="form-group">
            <label>Test:</label>
            {param ? (
              <p className="form-control-static">{getTestName(watchTestId)}</p>
            ) : (
              <select 
                {...register('testId')} 
                className="form-control"
                onChange={(e) => {
                  const id = Number(e.target.value);
                  setValue('testId', id);
                  handleTestIdChange(id);
                }}
              >
                <option value="0">-- Select Test --</option>
                {filteredAvailableTests.map(t => (
                  <option key={t.id} value={t.id}>{getTestName(t.id)}</option>
                ))}
              </select>
            )}
            {errors.testId && <span className="text-danger">{errors.testId.message}</span>}
          </div>

          <div className={`form-group ${styles.checkboxGroup}`}>
            <input 
              type="checkbox" 
              id="is_calculated" 
              checked={watchIsCalculated}
              onChange={onIsCalculatedChanged} 
            />
            <label htmlFor="is_calculated">Is Calculated</label>
          </div>

          {watchIsCalculated && (
            <div className="form-group">
              <label htmlFor="formula">Formula:</label>
              <textarea 
                {...register('formula')} 
                id="formula"
                className="form-control" 
                rows={5}
                onBlur={(e) => validateFormula(e.target.value, true, Number(watchTestId))}
              />
              {formulaError && <span className="text-danger">{formulaError}</span>}
            </div>
          )}

          {!watchIsCalculated && selectedTest?.isArray && (
            <div className="form-group">
              <label htmlFor="code_array_cols">Code Array Columns:</label>
              <input {...register('codeRelatedArrays')} id="code_array_cols" className="form-control" />
              {errors.codeRelatedArrays && <span className="text-danger">{errors.codeRelatedArrays.message}</span>}
            </div>
          )}

          <div className={`form-group ${styles.checkboxGroup}`}>
            <input 
              type="checkbox" 
              id="is_required" 
              checked={watchIsRequired}
              onChange={onIsRequiredChanged} 
            />
            <label htmlFor="is_required">Is Required</label>
          </div>

          {!watchIsCalculated && (
            <div className="form-group">
              <label htmlFor="default_value">Default Value:</label>
              {selectedTest?.typeId === 1 || selectedTest?.typeId === 2 ? (
                <input type="number" step="any" {...register('defaultValue')} id="default_value" className="form-control" />
              ) : selectedTest?.typeId === 3 ? (
                <select {...register('defaultValue')} id="default_value" className="form-control">
                  <option value="">-- None --</option>
                  <option value="1">Yes</option>
                  <option value="0">No</option>
                </select>
              ) : selectedTest?.typeId === 4 ? (
                <select {...register('defaultValue')} id="default_value" className="form-control">
                  <option value="">-- Select --</option>
                  {testEnums.map(e => (
                    <option key={e.value} value={e.value}>{e.name}</option>
                  ))}
                </select>
              ) : (
                <input type="number" step="any" {...register('defaultValue')} id="default_value" className="form-control" />
              )}
              {errors.defaultValue && <span className="text-danger">{errors.defaultValue.message}</span>}
            </div>
          )}

          <div className={`form-group ${styles.checkboxGroup}`}>
            <input 
              type="checkbox" 
              id="has_condition" 
              checked={watchHasCondition}
              onChange={onHasConditionChanged} 
            />
            <label htmlFor="has_condition">Has Condition</label>
          </div>

          {watchHasCondition && (
            <>
              <div className="form-group">
                <label htmlFor="condition">Condition:</label>
                <input 
                  type="text" 
                  {...register('condition')} 
                  id="condition" 
                  className={`form-control ${errors.condition ? 'invalid' : ''}`}
                  onBlur={handleConditionBlur}
                />
                {errors.condition && <div className="text-danger">{errors.condition.message}</div>}
              </div>

              <div className="form-group">
                <label htmlFor="condition_note">Condition Note:</label>
                <textarea 
                  {...register('conditionNote')} 
                  id="condition_note" 
                  className={`form-control ${errors.conditionNote ? 'invalid' : ''}`}
                  rows={3}
                />
                {errors.conditionNote && <div className="text-danger">{errors.conditionNote.message}</div>}
              </div>

              <h4 className={styles.evaluationsTitle}>Validation Tests (Evaluations)</h4>
              <div className={styles.tableContainer}>
                <table className="data-table small-table">
                  <colgroup>
                    <col className={styles.colValue} />
                    <col className={styles.colExpected} />
                    <col className={styles.colNote} />
                    <col className={styles.colActions} />
                  </colgroup>
                  <thead>
                    <tr>
                      <th>Value</th>
                      <th>Expected Result</th>
                      <th>Note</th>
                      <th>Actions</th>
                    </tr>
                  </thead>
                  <tbody>
                    {fields.map((field, index) => (
                      <tr key={field.id}>
                        <td>
                          {selectedTest ? (
                            <>
                              {selectedTest.typeId === 1 && (
                                <input type="number" step="any" className="form-control" {...register(`evals.${index}.value` as const, { valueAsNumber: true })} />
                              )}
                              {selectedTest.typeId === 2 && (
                                <input type="number" step="any" className="form-control" {...register(`evals.${index}.value` as const, { valueAsNumber: true })} />
                              )}
                              {selectedTest.typeId === 3 && (
                                <select className="form-control" {...register(`evals.${index}.value` as const, { valueAsNumber: true })}>
                                  <option value={1}>Yes</option>
                                  <option value={0}>No</option>
                                </select>
                              )}
                              {selectedTest.typeId === 4 && selectedTest.enums && (
                                <select className="form-control" {...register(`evals.${index}.value` as const, { valueAsNumber: true })}>
                                  {selectedTest.enums.map(e => (
                                    <option key={e.value} value={e.value}>{e.name}</option>
                                  ))}
                                </select>
                              )}
                              {![1, 2, 3, 4].includes(selectedTest.typeId) && (
                                <input type="number" step="any" className="form-control" {...register(`evals.${index}.value` as const, { valueAsNumber: true })} />
                              )}
                            </>
                          ) : (
                            <input type="number" step="any" className="form-control" {...register(`evals.${index}.value` as const, { valueAsNumber: true })} />
                          )}
                        </td>
                        <td>
                          <select className="form-control" {...register(`evals.${index}.expectedResult` as const, { valueAsNumber: true })}>
                            <option value={1}>Yes</option>
                            <option value={0}>No</option>
                          </select>
                        </td>
                        <td>
                          <input type="text" className="form-control" {...register(`evals.${index}.note` as const)} />
                        </td>
                        <td>
                          <button type="button" onClick={() => remove(index)} className="action-button delete-button small-button">Remove</button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
                <button type="button" onClick={addEval} className="action-button secondary small-button add-eval-button">Add Evaluation</button>
                {errors.evals && <div className="text-danger">{errors.evals.message}</div>}
              </div>
            </>
          )}

          <div className="form-group">
            <label htmlFor="nr_ord">Order:</label>
            <input type="number" {...register('nrOrd', { valueAsNumber: true })} id="nr_ord" className="form-control" disabled />
          </div>
        </DialogContent>
        <DialogFooter>
          <button type="submit" className="action-button primary" disabled={isValidating || isValidatingCondition}>Save</button>
          <button type="button" className="action-button secondary" onClick={onClose}>Cancel</button>
        </DialogFooter>
      </form>
    </Dialog>
  );
};

export default FormParamDialog;
