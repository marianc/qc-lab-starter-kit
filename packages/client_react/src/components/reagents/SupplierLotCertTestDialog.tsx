import React, { useState, useEffect } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { Dialog, DialogHeader, DialogContent, DialogFooter } from '@/components/common/ui';
import type { TestDto } from '@/types/test';
import type { ReagentSupplierLotCertTestDto, UpsertReagentSupplierLotCertTestDto } from '@/types/reagent';
import type { MaterialTestDto } from '@/types/material';
import testsService from '@/services/testsService';
import materialsService from '@/services/materialsService';
import reagentsService from '@/services/reagentsService';
import { supplierLotCertTestSchema } from '@/lib/schemas/reagent';
import styles from './SupplierLotCertTestDialog.module.css';

interface SupplierLotCertTestDialogProps {
  controlCodeId: number;
  materialId: number;
  existingTest: ReagentSupplierLotCertTestDto | null;
  onClose: (saved: boolean) => void;
}

type CertTestFormValues = {
  testId: number;
  value: any;
  uncertaintyValue?: any;
  coverageFactorK?: any;
  traceabilityStatement?: string | null;
};

const SupplierLotCertTestDialog: React.FC<SupplierLotCertTestDialogProps> = ({
  controlCodeId,
  materialId,
  existingTest,
  onClose
}) => {
  const [certReferenceTests, setCertReferenceTests] = useState<TestDto[]>([]);
  const [materialTests, setMaterialTests] = useState<MaterialTestDto[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);

  const {
    register,
    handleSubmit,
    reset,
    watch,
    setValue,
    formState: { errors }
  } = useForm<CertTestFormValues>({
    resolver: zodResolver(supplierLotCertTestSchema) as any,
    defaultValues: {
      testId: 0,
      value: '',
      uncertaintyValue: '',
      coverageFactorK: '',
      traceabilityStatement: ''
    }
  });

  const watchTestId = watch('testId');
  const testDetails = certReferenceTests.find(t => t.id === Number(watchTestId));

  useEffect(() => {
    const fetchTests = async () => {
      try {
        const [tests, matTests] = await Promise.all([
          testsService.getCertifiedReferenceTests(),
          materialsService.getMaterialTests(materialId)
        ]);
        setCertReferenceTests(tests);
        setMaterialTests(matTests);

        if (existingTest) {
          reset({
            testId: existingTest.testId,
            value: existingTest.value,
            uncertaintyValue: existingTest.uncertaintyValue ?? '',
            coverageFactorK: existingTest.coverageFactorK ?? '',
            traceabilityStatement: existingTest.traceabilityStatement || ''
          });
        } else {
          reset({
            testId: 0,
            value: '',
            uncertaintyValue: '',
            coverageFactorK: '',
            traceabilityStatement: ''
          });
        }
      } catch (err) {
        console.error('Failed to fetch certified reference tests or material tests', err);
        setError('Failed to load tests.');
      }
    };
    fetchTests();
  }, [existingTest, materialId, reset]);

  const materialTestIds = materialTests.map(t => t.id);
  const availableTests = certReferenceTests.filter(t => {
    if (existingTest && t.id === existingTest.testId) return true;
    return materialTestIds.includes(t.id);
  });

  const onTestChanged = (e: React.ChangeEvent<HTMLSelectElement>) => {
    const val = parseInt(e.target.value);
    setValue('testId', val);
    setValue('value', '');
  };

  const renderControl = () => {
    if (!testDetails) return <input type="text" className="form-control" disabled />;

    switch (testDetails.typeId) {
      case 1: // Integer
        return <input type="number" step="1" className={`form-control ${errors.value ? 'invalid' : ''}`} {...register('value')} />;
      case 2: // Real
        return <input type="number" step="any" className={`form-control ${errors.value ? 'invalid' : ''}`} {...register('value')} />;
      case 3: // Boolean
        return (
          <select className={`form-control ${errors.value ? 'invalid' : ''}`} {...register('value')}>
            <option value="">-- Select --</option>
            <option value="1">Yes</option>
            <option value="0">No</option>
          </select>
        );
      case 4: // Enum
        return (
          <select className={`form-control ${errors.value ? 'invalid' : ''}`} {...register('value')}>
            <option value="">-- Select --</option>
            {testDetails.enums?.map(e => (
              <option key={e.value} value={e.value}>{e.name}</option>
            ))}
          </select>
        );
      default:
        return <input type="text" className={`form-control ${errors.value ? 'invalid' : ''}`} {...register('value')} />;
    }
  };

  const onSubmit = async (values: CertTestFormValues) => {
    let finalValue = values.value;
    if (testDetails) {
      if (testDetails.typeId === 1 || testDetails.typeId === 2) {
        const num = parseFloat(finalValue);
        if (!isNaN(num)) finalValue = num;
      } else if (testDetails.typeId === 3 || testDetails.typeId === 4) {
        const num = parseInt(finalValue);
        if (!isNaN(num)) finalValue = num;
      }
    }

    const dto: UpsertReagentSupplierLotCertTestDto = {
      testId: Number(values.testId),
      value: Number(finalValue),
      uncertaintyValue: values.uncertaintyValue !== '' && values.uncertaintyValue != null && !isNaN(Number(values.uncertaintyValue)) ? Number(values.uncertaintyValue) : null,
      coverageFactorK: values.coverageFactorK !== '' && values.coverageFactorK != null && !isNaN(Number(values.coverageFactorK)) ? Number(values.coverageFactorK) : null,
      traceabilityStatement: values.traceabilityStatement?.trim() || null
    };

    setSubmitting(true);
    setError(null);
    try {
      await reagentsService.upsertSupplierLotCertTest(controlCodeId, dto);
      onClose(true);
    } catch (err: any) {
      console.error('Failed to save certification test', err);
      setError(err.response?.data?.msg || 'Failed to save certification test value.');
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <Dialog open={true} onClose={() => onClose(false)}>
      <DialogHeader>
        {existingTest ? 'Edit CRM Test Value' : 'Add CRM Test Value'}
      </DialogHeader>
      <DialogContent>
        {error && <div className="error-message" style={{ marginBottom: '1rem', color: 'var(--danger-color, #ef4444)' }}>{error}</div>}
        <form id="cert-test-form" onSubmit={handleSubmit(onSubmit)} className={styles.form}>
          <div className="form-group">
            <label>Test *</label>
            {existingTest ? (
              <span>{testDetails?.name || existingTest.testName || 'Unknown'}</span>
            ) : (
              <select
                className={`form-control ${errors.testId ? 'invalid' : ''}`}
                value={watchTestId}
                onChange={onTestChanged}
              >
                <option value={0} disabled>Select test...</option>
                {availableTests.map((t) => {
                  const displayName = t.unitName ? `${t.name} [${t.unitName}]` : t.name;
                  return (
                    <option key={t.id} value={t.id}>
                      {displayName}
                    </option>
                  );
                })}
              </select>
            )}
            {errors.testId?.message && <div className="validation-message">{String(errors.testId.message)}</div>}
          </div>

          <div className="form-group">
            <label>Value *</label>
            {renderControl()}
            {errors.value?.message && <div className="validation-message">{String(errors.value.message)}</div>}
          </div>

          <div className="form-group">
            <label>Uncertainty Value</label>
            <input
              type="number"
              step="any"
              className={`form-control ${errors.uncertaintyValue ? 'invalid' : ''}`}
              {...register('uncertaintyValue', { valueAsNumber: true, emptyAsNull: true } as any)}
            />
            {errors.uncertaintyValue?.message && <div className="validation-message">{String(errors.uncertaintyValue.message)}</div>}
          </div>

          <div className="form-group">
            <label>Coverage Factor (k)</label>
            <input
              type="number"
              step="any"
              className={`form-control ${errors.coverageFactorK ? 'invalid' : ''}`}
              {...register('coverageFactorK', { valueAsNumber: true, emptyAsNull: true } as any)}
            />
            {errors.coverageFactorK?.message && <div className="validation-message">{String(errors.coverageFactorK.message)}</div>}
          </div>

          <div className="form-group">
            <label>Traceability Statement</label>
            <textarea
              className={`form-control ${errors.traceabilityStatement ? 'invalid' : ''}`}
              {...register('traceabilityStatement')}
              rows={3}
            />
            {errors.traceabilityStatement?.message && <div className="validation-message">{String(errors.traceabilityStatement.message)}</div>}
          </div>
        </form>
      </DialogContent>
      <DialogFooter>
        <button type="submit" form="cert-test-form" className="action-button primary" disabled={submitting}>
          {submitting ? 'Saving...' : 'Save'}
        </button>
        <button type="button" onClick={() => onClose(false)} className="action-button secondary" disabled={submitting}>
          Cancel
        </button>
      </DialogFooter>
    </Dialog>
  );
};

export default SupplierLotCertTestDialog;
