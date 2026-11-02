import React, { useEffect } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import * as z from 'zod';
import { Dialog, DialogHeader, DialogContent, DialogFooter } from '@/components/common/ui';
import { worksheetTestSchema } from '@/lib/schemas/worksheet';
import type { WorksheetTestItem } from '@/types/worksheet';
import worksheetService from '@/services/worksheetService';
import specificationsService from '@/services/specificationsService';
import styles from './WorksheetTestDialog.module.css';

interface WorksheetTestDialogProps {
  open: boolean;
  item?: WorksheetTestItem | null;
  items: WorksheetTestItem[];
  onSave: (data: WorksheetTestItem) => void;
  onClose: () => void;
}

type WorksheetFormValues = z.infer<typeof worksheetTestSchema>;

const WorksheetTestDialog: React.FC<WorksheetTestDialogProps> = ({
  open,
  item,
  items,
  onSave,
  onClose
}) => {
  const {
    register,
    handleSubmit,
    reset,
    watch,
    setError,
    clearErrors,
    formState: { errors }
  } = useForm<WorksheetFormValues>({
    resolver: zodResolver(worksheetTestSchema) as any,
    defaultValues: {
      name: '',
      code: '',
      description: '',
      measurement_unit: '',
      value_type: '' as any,
      enumListString: 'Option 1\nOption 2',
      is_array: false,
      for_certification: false,
      formula: '',
      code_related_arrays: '',
      condition: '',
      condition_note: null
    }
  });

  const watchValueType = watch('value_type');
  const watchFormula = watch('formula');
  const watchIsArray = watch('is_array');

  const isCodeUsedAsDependency = React.useMemo(() => {
    if (!item || !item.code) return false;
    const targetCode = item.code.trim().toLowerCase();
    return items.some(it => {
      if (it.id === item.id) return false;
      if (!it.formula_dependencies) return false;
      const deps = it.formula_dependencies.split(',').map(d => d.trim().toLowerCase());
      return deps.includes(targetCode);
    });
  }, [item, items]);

  const codeRegister = register('code', {
    onChange: () => {
      if (errors.code?.type === 'manual') {
        clearErrors('code');
      }
    }
  });

  const validateFormula = async (formula: string | null | undefined, code: string, isArray: boolean): Promise<boolean> => {
    if (!formula || formula.trim() === '') {
      clearErrors('formula');
      return true;
    }
    try {
      await worksheetService.validateFormula(formula, code, isArray, items);
      clearErrors('formula');
      return true;
    } catch (err: any) {
      setError('formula', { type: 'manual', message: err.message });
      return false;
    }
  };

  const validateCondition = async (condition: string | null | undefined): Promise<boolean> => {
    if (!condition || condition.trim() === '') {
      clearErrors('condition');
      return true;
    }
    try {
      await specificationsService.validateCondition(condition);
      clearErrors('condition');
      return true;
    } catch (err: any) {
      setError('condition', { type: 'manual', message: err.message });
      return false;
    }
  };

  useEffect(() => {
    if (open) {
      if (item) {
        reset({
          name: item.name,
          code: item.code,
          description: item.description || '',
          measurement_unit: item.measurement_unit || '',
          value_type: item.value_type,
          enumListString: item.enums && item.enums.length > 0 ? item.enums.join('\n') : 'Option 1\nOption 2',
          is_array: item.is_array,
          for_certification: item.for_certification,
          formula: item.formula || '',
          code_related_arrays: item.code_related_arrays || '',
          condition: item.condition || '',
          condition_note: item.condition_note || null
        });
      } else {
        reset({
          name: '',
          code: '',
          description: '',
          measurement_unit: '',
          value_type: '' as any,
          enumListString: 'Option 1\nOption 2',
          is_array: false,
          for_certification: false,
          formula: '',
          code_related_arrays: '',
          condition: '',
          condition_note: null
        });
      }
    }
  }, [open, item, reset]);

  const onSubmit = async (data: WorksheetFormValues) => {
    const trimmedCode = data.code.trim();
    const isDuplicate = items.some(i => 
      i.code.trim().toLowerCase() === trimmedCode.toLowerCase() && 
      (!item || i.id !== item.id)
    );

    if (isDuplicate) {
      setError('code', {
        type: 'manual',
        message: 'Test code must be unique. This code is already used by another test.'
      });
      return;
    }

    const isFormulaValid = await validateFormula(data.formula, data.code, data.is_array);
    if (!isFormulaValid) {
      return;
    }

    const isConditionValid = await validateCondition(data.condition);
    if (!isConditionValid) {
      return;
    }

    let enums: string[] | null = null;
    if (data.value_type === 'enum' && data.enumListString) {
      enums = data.enumListString.split(/[\n\r,;]+/).map(s => s.trim()).filter(s => s !== '');
    }

    const savedItem: WorksheetTestItem = {
      id: item ? item.id : `test_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
      name: data.name,
      code: data.code,
      description: data.description || null,
      measurement_unit: data.measurement_unit,
      value_type: data.value_type,
      enums: enums,
      is_array: data.is_array,
      for_certification: data.for_certification,
      formula: data.formula || null,
      formula_dependencies: item?.formula_dependencies || null,
      nr_ord_calc: item?.nr_ord_calc || 0,
      value: item?.value || null,
      code_related_arrays: (!data.formula && data.is_array) ? (data.code_related_arrays || null) : null,
      condition: data.condition || null,
      condition_note: data.condition_note && data.condition_note.trim() !== '' ? data.condition_note : null,
      is_conforming_condition: (data.condition && data.condition.trim() !== '') ? (item?.is_conforming_condition ?? true) : null
    };
    onSave(savedItem);
  };

  return (
    <Dialog open={open} onClose={onClose}>
      <DialogHeader>{item ? "Edit Test" : "Add Test"}</DialogHeader>
      <form onSubmit={handleSubmit(onSubmit, (errors) => console.error("Validation errors:", errors))} className={styles.testEditForm}>
        <DialogContent>
          <div className="form-group">
            <label>Name</label>
            <input type="text" {...register('name')} className="form-control" />
            {errors.name && <span className="text-danger">{errors.name.message}</span>}
          </div>

          <div className="form-group">
            <label>Code</label>
            <input type="text" {...codeRegister} disabled={isCodeUsedAsDependency} className="form-control" />
            {errors.code && <span className="text-danger">{errors.code.message}</span>}
          </div>

          <div className="form-group">
            <label>Description</label>
            <textarea {...register('description')} className="form-control" rows={2} />
            {errors.description && <span className="text-danger">{errors.description.message as string}</span>}
          </div>

          <div className="form-group">
            <label>Measurement Unit</label>
            <input type="text" {...register('measurement_unit')} className="form-control" />
            {errors.measurement_unit && <span className="text-danger">{errors.measurement_unit.message}</span>}
          </div>

          <div className="form-group">
            <label>Value Type</label>
            <select {...register('value_type')} disabled={isCodeUsedAsDependency} className="form-control">
              <option value="">-- Select Value Type --</option>
              <option value="integer">integer</option>
              <option value="real">real</option>
              <option value="boolean">boolean</option>
              <option value="enum">enum</option>
            </select>
            {errors.value_type && <span className="text-danger">{errors.value_type.message as string}</span>}
          </div>

          {watchValueType === 'enum' && (
            <div className="form-group">
              <label>Enum List</label>
              <textarea 
                {...register('enumListString')} 
                className={`form-control ${styles.formulaTextarea}`} 
                rows={6} 
                disabled={isCodeUsedAsDependency}
                placeholder="Option 1&#10;Option 2"
              />
              <small className="form-text text-muted">Introduce a list of items separated by new line, comma (,) or semicolon (;).</small>
              {errors.enumListString && <span className="text-danger">{errors.enumListString.message as string}</span>}
            </div>
          )}

          <div className={`form-group ${styles.checkboxGroup}`}>
            <input type="checkbox" id="is_array" {...register('is_array')} disabled={isCodeUsedAsDependency} />
            <label htmlFor="is_array">Is Array</label>
          </div>

          {!watchFormula && watchIsArray && (
            <div className="form-group">
              <label>Code Related Arrays (Optional)</label>
              <input type="text" {...register('code_related_arrays')} className="form-control" placeholder="Group code for related arrays" />
              {errors.code_related_arrays && <span className="text-danger">{errors.code_related_arrays.message}</span>}
            </div>
          )}

          <div className="form-group">
            <label>Formula</label>
            <textarea 
              {...register('formula')} 
              className={`form-control ${styles.formulaTextarea}`} 
              rows={6} 
              placeholder="e.g. [density] * [volume]" 
              onBlur={async (e) => await validateFormula(e.target.value, watch('code'), watch('is_array'))}
            />
            {errors.formula && <span className="text-danger">{errors.formula.message as string}</span>}
          </div>

          <div className="form-group">
            <label>Condition Formula</label>
            <input 
              type="text" 
              {...register('condition')} 
              className="form-control" 
              placeholder="[value] >= 0" 
              onBlur={async (e) => await validateCondition(e.target.value)}
            />
            {errors.condition && <span className="text-danger">{errors.condition.message}</span>}
          </div>

          <div className="form-group">
            <label>Condition Note</label>
            <input type="text" {...register('condition_note')} className="form-control" />
            {errors.condition_note && <span className="text-danger">{errors.condition_note.message}</span>}
          </div>

          <div className={`form-group ${styles.checkboxGroup}`}>
            <input type="checkbox" id="for_certification" {...register('for_certification')} />
            <label htmlFor="for_certification">For Certification</label>
          </div>
        </DialogContent>
        <DialogFooter>
          <button type="submit" className="action-button primary">Save</button>
          <button type="button" className="action-button secondary" onClick={onClose}>Cancel</button>
        </DialogFooter>
      </form>
    </Dialog>
  );
};

export default WorksheetTestDialog;
