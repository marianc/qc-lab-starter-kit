import React, { useEffect, useState } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { Dialog, DialogHeader, DialogContent, DialogFooter } from '@/components/common/ui';
import styles from './ReagentDialog.module.css';
import type { NormDto } from '@/types/norm';
import normsService from '@/services/normsService';
import reagentsService from '@/services/reagentsService';
import { reagentSchema } from '@/lib/schemas/reagent';

interface ReagentDialogProps {
  open: boolean;
  reagentId?: number | null;
  onClose: (savedId?: number | null) => void;
}

type ReagentFormValues = {
  id: number;
  name: string;
  code: string;
  description?: string | null;
  casNumber?: string | null;
  normId: any;
  isObsolete: boolean;
};

const ReagentDialog: React.FC<ReagentDialogProps> = ({ open, reagentId, onClose }) => {
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
  } = useForm<ReagentFormValues>({
    resolver: zodResolver(reagentSchema) as any,
    defaultValues: {
      id: 0,
      name: '',
      code: '',
      description: '',
      casNumber: '',
      normId: null,
      isObsolete: false
    }
  });

  useEffect(() => {
    if (open) {
      normsService.getAllNorms().then(setNorms);
      if (reagentId) {
        reagentsService.getReagent(reagentId).then(data => {
          reset({
            id: data.id,
            name: data.name,
            code: data.code,
            description: data.description || '',
            casNumber: data.casNumber || '',
            normId: data.normId || null,
            isObsolete: data.isObsolete
          });
        });
      } else {
        reset({
          id: 0,
          name: '',
          code: '',
          description: '',
          casNumber: '',
          normId: null,
          isObsolete: false
        });
      }
    }
  }, [open, reagentId, reset]);

  const validateUniqueness = async (property: "Name" | "Code"): Promise<boolean> => {
    const value = getValues(property.toLowerCase() as any);
    if (!value || typeof value !== 'string') return true;

    setIsValidating(true);
    try {
      const isUnique = await reagentsService.validateUniqueness(property, value, getValues('id'));
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
    } finally {
      setIsValidating(false);
    }
  };

  const onSubmit = async (values: ReagentFormValues) => {
    const isNameUnique = await validateUniqueness('Name');
    const isCodeUnique = await validateUniqueness('Code');

    if (!isNameUnique || !isCodeUnique) {
      return;
    }

    try {
      const parsedNormId = values.normId ? Number(values.normId) : null;
      if (reagentId) {
        await reagentsService.updateReagent(reagentId, {
          name: values.name,
          code: values.code,
          description: values.description || null,
          casNumber: values.casNumber || null,
          normId: parsedNormId,
          isObsolete: values.isObsolete
        });
        onClose(reagentId);
      } else {
        const result = await reagentsService.createReagent({
          name: values.name,
          code: values.code,
          description: values.description || null,
          casNumber: values.casNumber || null,
          normId: parsedNormId,
          isObsolete: values.isObsolete
        });
        onClose(result.id);
      }
    } catch (err: any) {
      console.error('Failed to save reagent', err);
      if (err.response?.data?.msg) {
        setError('root', { message: err.response.data.msg });
      }
    }
  };

  const nameRegister = register('name');
  const codeRegister = register('code');

  return (
    <Dialog open={open} onClose={() => onClose()}>
      <DialogHeader>
        {reagentId ? "Edit Reagent" : "New Reagent"}
      </DialogHeader>
      <form onSubmit={handleSubmit(onSubmit)} className={styles.reagentEditForm}>
        <DialogContent>
          {errors.root && <div className="text-danger mb-3">{errors.root.message}</div>}

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
            <label>CAS Number</label>
            <input 
              {...register('casNumber')} 
              className="form-control" 
              placeholder="e.g. 7647-01-0"
            />
            {errors.casNumber && <span className="text-danger">{errors.casNumber.message}</span>}
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
        </DialogContent>
        <DialogFooter>
          <button type="submit" className="action-button primary" disabled={isValidating}>Save</button>
          <button type="button" className="action-button secondary" onClick={() => onClose()}>Cancel</button>
        </DialogFooter>
      </form>
    </Dialog>
  );
};

export default ReagentDialog;