import React, { useEffect, useState } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { Dialog, DialogHeader, DialogContent, DialogFooter } from '../common/ui';
import styles from './MaterialDialog.module.css';
import type { NormDto } from '@/types/norm';
import normsService from '@/services/normsService';
import materialsService from '@/services/materialsService';
import { materialSchema } from '@/lib/schemas/material';

interface MaterialDialogProps {
  open: boolean;
  materialId?: number | null;
  onClose: (savedId?: number | null) => void;
}

type MaterialFormValues = {
  id: number;
  name: string;
  code: string;
  description?: string | null;
  normId: any;
  isProduct: boolean;
  isRawMaterial: boolean;
  isReagent: boolean;
  isObsolete: boolean;
};

const MaterialDialog: React.FC<MaterialDialogProps> = ({ open, materialId, onClose }) => {
  const [isValidating, setIsValidating] = useState(false);
  const [norms, setNorms] = useState<NormDto[]>([]);
  const {
    register,
    handleSubmit,
    reset,
    setError,
    clearErrors,
    getValues,
    formState: { errors }
  } = useForm<MaterialFormValues>({
    resolver: zodResolver(materialSchema) as any,
    defaultValues: {
      id: 0,
      name: '',
      code: '',
      description: '',
      normId: null,
      isProduct: false,
      isRawMaterial: false,
      isReagent: false,
      isObsolete: false
    }
  });

  useEffect(() => {
    if (open) {
      normsService.getAllNorms().then(setNorms);
      if (materialId) {
        materialsService.getMaterial(materialId).then(data => {
          reset({
            id: data.id,
            name: data.name,
            code: data.code,
            description: data.description || '',
            normId: data.normId || null,
            isProduct: data.isProduct,
            isRawMaterial: data.isRawMaterial,
            isReagent: data.isReagent,
            isObsolete: data.isObsolete
          });
        });
      } else {
        reset({
          id: 0,
          name: '',
          code: '',
          description: '',
          normId: null,
          isProduct: false,
          isRawMaterial: false,
          isReagent: false,
          isObsolete: false
        });
      }
    }
  }, [open, materialId, reset]);

  const validateUniqueness = async (property: "Name" | "Code"): Promise<boolean> => {
    const value = getValues(property.toLowerCase() as any);
    if (!value || typeof value !== 'string') return true;

    setIsValidating(true);
    try {
      const isUnique = await materialsService.validateUniqueness(property, value, getValues('id'));
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

  const onSubmit = async (values: MaterialFormValues) => {
    const isNameUnique = await validateUniqueness('Name');
    const isCodeUnique = await validateUniqueness('Code');

    if (isNameUnique && isCodeUnique) {
      try {
        let savedId: number;
        if (values.id > 0) {
          await materialsService.updateMaterial(values.id, {
            name: values.name,
            code: values.code,
            description: values.description || null,
            normId: values.normId ? Number(values.normId) : null,
            isProduct: values.isProduct,
            isRawMaterial: values.isRawMaterial,
            isReagent: values.isReagent,
            isObsolete: values.isObsolete
          });
          savedId = values.id;
        } else {
          const result = await materialsService.createMaterial({
            name: values.name,
            code: values.code,
            description: values.description || null,
            normId: values.normId ? Number(values.normId) : null,
            isProduct: values.isProduct,
            isRawMaterial: values.isRawMaterial,
            isReagent: values.isReagent,
            isObsolete: values.isObsolete
          });
          savedId = result.id;
        }
        onClose(savedId);
      } catch (err) {
        console.error('Failed to save material', err);
      }
    }
  };

  const nameRegister = register('name');
  const codeRegister = register('code');

  return (
    <Dialog open={open} onClose={() => onClose()}>
      <DialogHeader>
        {materialId ? "Edit Material" : "New Material"}
      </DialogHeader>
      <form onSubmit={handleSubmit(onSubmit)} className={styles.materialEditForm}>
        <DialogContent>
          <div className="form-group">
            <label>Name</label>
            <input 
              {...nameRegister} 
              className="form-control" 
              onBlur={(e) => {
                nameRegister.onBlur(e);
                validateUniqueness('Name');
              }}
            />
            {errors.name && <span className="text-danger">{errors.name.message}</span>}
          </div>

          <div className="form-group">
            <label>Code</label>
            <input 
              {...codeRegister} 
              className="form-control" 
              onBlur={(e) => {
                codeRegister.onBlur(e);
                validateUniqueness('Code');
              }}
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
            <label>Norm</label>
            <select {...register('normId')} className="form-control">
              <option value="">-- Select Norm --</option>
              {norms.map(norm => (
                <option key={norm.id} value={norm.id}>{norm.name}</option>
              ))}
            </select>
            {errors.normId && <span className="text-danger">{errors.normId.message as string}</span>}
          </div>

          <div className={`form-group ${styles.checkboxGroup}`}>
            <input type="checkbox" id="is_product" {...register('isProduct')} />
            <label htmlFor="is_product">Is Product</label>
          </div>

          <div className={`form-group ${styles.checkboxGroup}`}>
            <input type="checkbox" id="is_raw_material" {...register('isRawMaterial')} />
            <label htmlFor="is_raw_material">Is Raw Material</label>
          </div>
        </DialogContent>
        <DialogFooter>
          <button type="submit" className="action-button primary" disabled={isValidating}>Save</button>
          <button type="button" className="action-button secondary" onClick={() => onClose()}>Cancel</button>
        </DialogFooter>
      </form>
    </Dialog>
  );
};

export default MaterialDialog;