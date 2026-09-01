import React, { useEffect, useState } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { Dialog, DialogHeader, DialogContent, DialogFooter } from '../common/ui';
import styles from './TestDialog.module.css';
import type { TestDto } from '@/types/test';
import type { UnitDto } from '@/types/unit';
import type { NormDto } from '@/types/norm';
import type { ValueTypeDto } from '@/types/valueType';
import unitsService from '@/services/unitsService';
import normsService from '@/services/normsService';
import valueTypesService from '@/services/valueTypesService';
import testsService from '@/services/testsService';
import { testSchema } from '@/lib/schemas/test';

interface TestDialogProps {
  open: boolean;
  testData?: TestDto | null;
  onSave: (data: TestDto) => void;
  onClose: () => void;
}

type TestFormValues = {
  id: number;
  name: string;
  code: string;
  description: string | null;
  typeId: number;
  isArray: boolean;
  isParam: boolean;
  forCertification: boolean;
  relativeUncertaintyPct: number | null;
  defaultCoverageFactorK: number | null;
  unitId: number | null;
  normId: number | null;
  normRef: string | null;
  nrOrd: number;
  enumListString: string | null;
};

const TestDialog: React.FC<TestDialogProps> = ({ open, testData, onSave, onClose }) => {
  const [isValidating, setIsValidating] = useState(false);
  const [units, setUnits] = useState<UnitDto[]>([]);
  const [norms, setNorms] = useState<NormDto[]>([]);
  const [valueTypes, setValueTypes] = useState<ValueTypeDto[]>([]);
  
  const {
    register,
    handleSubmit,
    reset,
    setError,
    clearErrors,
    getValues,
    watch,
    setValue,
    formState: { errors }
  } = useForm<TestFormValues>({
    resolver: zodResolver(testSchema) as any,
    defaultValues: {
      id: 0,
      name: '',
      code: '',
      description: null,
      typeId: undefined as any,
      isArray: false,
      isParam: false,
      forCertification: false,
      relativeUncertaintyPct: null,
      defaultCoverageFactorK: null,
      unitId: null,
      normId: null,
      normRef: null,
      nrOrd: 0,
      enumListString: null
    }
  });

  const watchNormId = watch('normId');
  const watchTypeId = watch('typeId');
  const watchId = watch('id');
  const watchForCertification = watch('forCertification');
  const watchIsParam = watch('isParam');

  useEffect(() => {
    if (open) {
      Promise.all([
        unitsService.getAllUnits(),
        normsService.getAllNorms(),
        valueTypesService.getAllValueTypes()
      ]).then(([u, n, vt]) => {
        setUnits(u);
        setNorms(n);
        setValueTypes(vt);

        if (testData) {
          reset({
            id: testData.id,
            name: testData.name,
            code: testData.code,
            description: testData.description || '',
            typeId: testData.typeId,
            isArray: testData.isArray,
            isParam: testData.isParam,
            forCertification: testData.forCertification,
            relativeUncertaintyPct: testData.relativeUncertaintyPct ?? null,
            defaultCoverageFactorK: testData.defaultCoverageFactorK ?? null,
            unitId: testData.unitId || null,
            normId: testData.normId || null,
            normRef: testData.normRef || '',
            nrOrd: testData.nrOrd,
            enumListString: testData.id === 0 && testData.typeId === 4 && testData.enums 
              ? testData.enums.map(e => e.name).join('\n') 
              : ''
          });
        } else {
          reset({
            id: 0,
            name: '',
            code: '',
            description: '',
            typeId: undefined as any,
            isArray: false,
            isParam: false,
            forCertification: false,
            relativeUncertaintyPct: null,
            defaultCoverageFactorK: null,
            unitId: null,
            normId: null,
            normRef: '',
            nrOrd: 0,
            enumListString: ''
          });
        }
      });
    }
  }, [open, testData, reset]);

  useEffect(() => {
    if (!watchNormId || watchNormId === 0) {
      setValue('normRef', null);
    }
  }, [watchNormId, setValue]);

  useEffect(() => {
    if (watchForCertification) {
      if (watchIsParam) {
        setValue('isParam', false);
      }
      const currentRelative = getValues('relativeUncertaintyPct');
      const currentCoverage = getValues('defaultCoverageFactorK');
      if (currentRelative === null || currentRelative === undefined || currentRelative === 0) {
        setValue('relativeUncertaintyPct', 3.0);
      }
      if (currentCoverage === null || currentCoverage === undefined || currentCoverage === 0) {
        setValue('defaultCoverageFactorK', 2.0);
      }
    } else {
      setValue('relativeUncertaintyPct', null);
      setValue('defaultCoverageFactorK', null);
    }
  }, [watchForCertification, setValue, getValues]);

  useEffect(() => {
    if (watchIsParam && watchForCertification) {
      setValue('forCertification', false);
    }
  }, [watchIsParam, watchForCertification, setValue]);

  const validateUniqueness = async (property: "Name" | "Code"): Promise<boolean> => {
    const value = getValues(property.toLowerCase() as any);
    if (!value) return true;

    setIsValidating(true);
    try {
      const isUnique = await testsService.validateUniqueness(property, value, getValues('id'));
      const field = property.toLowerCase() as any;
      if (!isUnique) {
        setError(field, {
          type: 'manual',
          message: `${property} is already in use.`
        });
        return false;
      } else {
        clearErrors(field);
        return true;
      }
    } catch (err) {
      console.error(`Uniqueness check failed:`, err);
      return false;
    } finally {
      setIsValidating(false);
    }
  };

  const onSubmit = async (values: TestFormValues) => {
    const isNameUnique = await validateUniqueness('Name');
    const isCodeUnique = await validateUniqueness('Code');

    if (isNameUnique && isCodeUnique) {
      let enums: any[] | null = null;
      if (values.id === 0 && Number(values.typeId) === 4 && values.enumListString) {
        const items = values.enumListString.split(/[\n\r,;]+/).map(s => s.trim()).filter(s => s !== '');
        const uniqueItems = Array.from(new Set(items));
        enums = uniqueItems.map((name, index) => ({
          name,
          value: index + 1,
          nrOrd: index + 1
        }));
      }
      onSave({ ...values, enums } as unknown as TestDto);
    }
  };

  return (
    <Dialog open={open} onClose={onClose}>
      <DialogHeader>
        {testData?.id ? "Edit Test" : "Add Test"}
      </DialogHeader>
      <form onSubmit={handleSubmit(onSubmit)} className={styles.testEditForm}>
        <DialogContent>
          <div className="form-group">
            <label>Name</label>
            <input 
              {...register('name')} 
              className="form-control" 
              disabled={Boolean(testData?.isFormValidated)}
              onBlur={() => validateUniqueness('Name')}
            />
            {errors.name && <span className="text-danger">{errors.name.message}</span>}
          </div>

          <div className="form-group">
            <label>Code</label>
            <input 
              {...register('code')} 
              className="form-control" 
              disabled={Boolean(testData?.isFormValidated)}
              onBlur={() => validateUniqueness('Code')}
            />
            {errors.code && <span className="text-danger">{errors.code.message}</span>}
          </div>

          <div className="form-group">
            <label>Description</label>
            <textarea 
              {...register('description')} 
              className="form-control" 
              rows={3}
            />
            {errors.description && <span className="text-danger">{errors.description.message}</span>}
          </div>

          <div className="form-group">
            <label>Value Type</label>
            <select {...register('typeId', { valueAsNumber: true })} className="form-control" disabled={Boolean(testData?.isFormValidated)}>
              <option value="">-- Select Value Type --</option>
              {valueTypes.map(vt => (
                <option key={vt.id} value={vt.id}>{vt.name}</option>
              ))}
            </select>
            {errors.typeId && <span className="text-danger">{errors.typeId.message as string}</span>}
          </div>

          {Number(watchTypeId) === 4 && watchId === 0 && (
            <div className="form-group">
              <label>Enum List</label>
              <textarea 
                {...register('enumListString')} 
                className="form-control" 
                rows={5} 
                placeholder="Item 1&#10;Item 2"
              />
              <small className="form-text text-muted">Introduce a list of items separated by new line, comma (,) or semicolon (;).</small>
              {errors.enumListString && <span className="text-danger">{errors.enumListString.message as string}</span>}
            </div>
          )}

          <div className={`form-group ${styles.checkboxGroup}`}>
            <input type="checkbox" id="is_array" {...register('isArray')} disabled={Boolean(testData?.isFormValidated)} />
            <label htmlFor="is_array">Is Array</label>
          </div>

          {!watchForCertification && (
            <div className={`form-group ${styles.checkboxGroup}`}>
              <input type="checkbox" id="is_param" {...register('isParam')} disabled={Boolean(testData?.isFormValidated)} />
              <label htmlFor="is_param">Is Parameter</label>
            </div>
          )}

          {!watchIsParam && (
            <div className={`form-group ${styles.checkboxGroup}`}>
              <input type="checkbox" id="for_certification" {...register('forCertification')} />
              <label htmlFor="for_certification">For Certification</label>
            </div>
          )}

          {watchForCertification && (
            <>
              <div className="form-group">
                <label>Relative Uncertainty (%)</label>
                <input 
                  type="number" 
                  step="0.01" 
                  {...register('relativeUncertaintyPct', { valueAsNumber: true })} 
                  className="form-control" 
                />
                {errors.relativeUncertaintyPct && <span className="text-danger">{errors.relativeUncertaintyPct.message as string}</span>}
              </div>

              <div className="form-group">
                <label>Default Coverage Factor (k)</label>
                <input 
                  type="number" 
                  step="0.01" 
                  {...register('defaultCoverageFactorK', { valueAsNumber: true })} 
                  className="form-control" 
                />
                {errors.defaultCoverageFactorK && <span className="text-danger">{errors.defaultCoverageFactorK.message as string}</span>}
              </div>
            </>
          )}

          <div className="form-group">
            <label>Unit</label>
            <select {...register('unitId', { valueAsNumber: true })} className="form-control">
              <option value="">None</option>
              {units.map(u => (
                <option key={u.id} value={u.id}>{u.name}</option>
              ))}
            </select>
          </div>

          <div className="form-group">
            <label>Norm</label>
            <select {...register('normId', { valueAsNumber: true })} className="form-control">
              <option value="">None</option>
              {norms.map(n => (
                <option key={n.id} value={n.id}>{n.name}</option>
              ))}
            </select>
          </div>

          {Number(watchNormId) > 0 && (
            <div className="form-group">
              <label>Norm Ref</label>
              <input {...register('normRef')} className="form-control" />
              {errors.normRef && <span className="text-danger">{errors.normRef.message as string}</span>}
            </div>
          )}

          <div className="form-group">
            <label>Order</label>
            <input type="number" {...register('nrOrd', { valueAsNumber: true })} className="form-control" />
          </div>
        </DialogContent>
        <DialogFooter>
          <button type="submit" className="action-button primary" disabled={isValidating}>Save</button>
          <button type="button" className="action-button secondary" onClick={onClose}>Cancel</button>
        </DialogFooter>
      </form>
    </Dialog>
  );
};

export default TestDialog;
