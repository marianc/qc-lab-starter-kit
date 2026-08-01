import React, { useEffect, useState } from 'react';
import { useForm, useFieldArray } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import * as z from 'zod';
import { 
  Dialog, 
  DialogHeader, 
  DialogContent, 
  DialogFooter 
} from '@/components/common/ui';
import styles from './SpecTestDialog.module.css';
import type { SpecTestDto, SpecTestEvalDto } from '@/types/specification';
import type { SelectableItem } from '@/types/models';
import type { TestDto } from '@/types/test';
import testsService from '@/services/testsService';
import specificationsService from '@/services/specificationsService';
import { specTestSchema } from '@/lib/schemas/specification';

type FormData = z.infer<typeof specTestSchema>;

interface Props {
  open: boolean;
  test?: SpecTestDto | null;
  availableTests: SelectableItem[];
  certifiedTestIds: number[];
  isEditMode: boolean;
  onSave: (data: SpecTestDto) => void;
  onClose: () => void;
}

const SpecTestDialog: React.FC<Props> = ({ 
  open, 
  test, 
  availableTests, 
  certifiedTestIds, 
  isEditMode, 
  onSave, 
  onClose 
}) => {
  const [fullTestInfo, setFullTestInfo] = useState<TestDto | null>(null);
  const [isValidatingCondition, setIsValidatingCondition] = useState(false);

  const { register, control, handleSubmit, reset, watch, setValue, trigger, setError, clearErrors, formState: { errors, isValidating } } = useForm<FormData>({
    resolver: zodResolver(specTestSchema),
    defaultValues: {
      testId: 0,
      testFrequency: 1,
      condition: '[value] > 0',
      note: '',
      evals: [{ value: 0, expectedResult: 1, note: '' }]
    }
  });

  const { fields, append, remove } = useFieldArray({
    control,
    name: 'evals'
  });

  const watchedTestId = watch('testId');

  useEffect(() => {
    if (open) {
      if (test) {
        reset({
          testId: test.testId,
          testFrequency: test.testFrequency,
          condition: test.condition,
          note: test.note,
          evals: test.evals.map((e: SpecTestEvalDto) => ({
            id: e.id,
            value: e.value,
            expectedResult: e.expectedResult,
            note: e.note
          }))
        });
        testsService.getTest(test.testId).then(setFullTestInfo);
      } else {
        reset({
          testId: 0,
          testFrequency: 1,
          condition: '[value] > 0',
          note: '',
          evals: [{ value: 0, expectedResult: 1, note: '' }]
        });
        setFullTestInfo(null);
      }
    }
  }, [open, test, reset]);

  useEffect(() => {
    if (watchedTestId > 0 && (!test || watchedTestId !== test.testId)) {
      testsService.getTest(watchedTestId).then(info => {
        setFullTestInfo(info);
        if (info) {
          const defaultVal = info.typeId === 3 ? 1 : (info.typeId === 4 && info.enums?.length ? info.enums[0].value : 0);
          const currentEvals = watch('evals');
          setValue('evals', currentEvals.map(e => ({ ...e, value: defaultVal })));
        }
      });
    }
  }, [watchedTestId]);

  const handleConditionBlur = async (e: React.FocusEvent<HTMLInputElement>) => {
    const condition = e.target.value;
    if (!condition) return;

    setIsValidatingCondition(true);
    try {
      await specificationsService.validateCondition(condition);
      clearErrors('condition');
    } catch (err: any) {
      setError('condition', { type: 'manual', message: err.message });
    } finally {
      setIsValidatingCondition(false);
    }
  };

  const onSubmit = (data: FormData) => {
    const result: SpecTestDto = {
      testId: data.testId,
      testName: isEditMode ? (test?.testName || '') : (availableTests.find(t => t.id === data.testId)?.name || ''),
      unitName: isEditMode ? (test?.unitName || null) : (fullTestInfo?.unitName || null),
      nrOrd: test?.nrOrd || 0,
      testFrequency: data.testFrequency,
      condition: data.condition,
      note: data.note,
      evals: data.evals.map(e => ({
        id: e.id || 0,
        value: e.value,
        result: null,
        expectedResult: e.expectedResult,
        isMatch: false, // Will be calculated by server
        note: e.note || null
      }))
    };
    onSave(result);
  };

  const getTestNameWithDisplayType = () => {
    if (isEditMode) {
      if (fullTestInfo) {
        const typeDisplay = fullTestInfo.isArray ? `[${fullTestInfo.typeName}]` : fullTestInfo.typeName;
        return `${fullTestInfo.name} (${typeDisplay})`;
      }
      return test?.testName || '';
    }
    return '';
  };

  const addEval = () => {
    let newVal = 0;
    if (fullTestInfo) {
      if (fullTestInfo.typeId === 3) newVal = 1;
      else if (fullTestInfo.typeId === 4 && fullTestInfo.enums?.length)
        newVal = fullTestInfo.enums[0].value;
    }
    append({ value: newVal, expectedResult: 1, note: '' });
  };

  if (!open) return null;

  return (
    <Dialog open={open} onClose={onClose}>
      <DialogHeader>
        <h2>{isEditMode ? 'Edit Spec Test' : 'Add Spec Test'}</h2>
      </DialogHeader>
      <DialogContent>
        <form id="spec-test-form" onSubmit={handleSubmit(onSubmit)}>
          <div className="form-group">
            <label>Test:</label>
            {isEditMode ? (
              <p>{getTestNameWithDisplayType()}{certifiedTestIds.includes(test?.testId || 0) ? '' : ' (?)'}</p>
            ) : (
              <select 
                className={`form-control ${errors.testId ? 'invalid' : ''}`}
                {...register('testId', { valueAsNumber: true })}
              >
                <option value="0">Select a Test</option>
                {availableTests.map(t => (
                  <option key={t.id} value={t.id}>
                    {t.name}{certifiedTestIds.includes(t.id) ? '' : ' (?)'}
                  </option>
                ))}
              </select>
            )}
            {errors.testId && <div className="validation-message">{errors.testId.message}</div>}
          </div>

          <div className="form-group">
            <label>Frequency:</label>
            <input 
              type="number" 
              className={`form-control ${errors.testFrequency ? 'invalid' : ''}`}
              {...register('testFrequency', { valueAsNumber: true })} 
            />
            {errors.testFrequency && <div className="validation-message">{errors.testFrequency.message}</div>}
          </div>

          <div className="form-group">
            <label>Condition:</label>
            <input 
              type="text" 
              className={`form-control ${errors.condition ? 'invalid' : ''}`}
              {...register('condition', { onBlur: handleConditionBlur })} 
            />
            {errors.condition && <div className="validation-message">{errors.condition.message}</div>}
          </div>

          <div className="form-group">
            <label>Note:</label>
            <textarea 
              className={`form-control ${errors.note ? 'invalid' : ''}`}
              rows={3}
              {...register('note')}
            />
            {errors.note && <div className="validation-message">{errors.note.message}</div>}
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
                      {fullTestInfo ? (
                        <>
                          {fullTestInfo.typeId === 1 && (
                            <input type="number" step="any" className="form-control" {...register(`evals.${index}.value` as const, { valueAsNumber: true })} />
                          )}
                          {fullTestInfo.typeId === 2 && (
                            <input type="number" step="any" className="form-control" {...register(`evals.${index}.value` as const, { valueAsNumber: true })} />
                          )}
                          {fullTestInfo.typeId === 3 && (
                            <select className="form-control" {...register(`evals.${index}.value` as const, { valueAsNumber: true })}>
                              <option value={1}>Yes</option>
                              <option value={0}>No</option>
                            </select>
                          )}
                          {fullTestInfo.typeId === 4 && fullTestInfo.enums && (
                            <select className="form-control" {...register(`evals.${index}.value` as const, { valueAsNumber: true })}>
                              {fullTestInfo.enums.map(e => (
                                <option key={e.value} value={e.value}>{e.name}</option>
                              ))}
                            </select>
                          )}
                          {![1, 2, 3, 4].includes(fullTestInfo.typeId) && (
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
            {errors.evals && <div className="validation-message">{errors.evals.message}</div>}
          </div>
        </form>
      </DialogContent>
      <DialogFooter>
        <button 
          type="submit" 
          form="spec-test-form" 
          className="action-button primary"
          disabled={isValidating || isValidatingCondition}
        >
          Save
        </button>
        <button type="button" onClick={onClose} className="action-button secondary">Cancel</button>
      </DialogFooter>
    </Dialog>
  );
};

export default SpecTestDialog;
