import React, { useEffect, useState } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import * as z from 'zod';
import { 
  Dialog, 
  DialogHeader, 
  DialogContent, 
  DialogFooter 
} from '../common/ui';
import styles from './NormDialog.module.css';
import type { NormDto } from '@/types/norm';
import normsService from '@/services/normsService';
import { normSchema } from '@/lib/schemas/norm';

type NormFormData = z.infer<typeof normSchema>;

interface Props {
  open: boolean;
  onClose: () => void;
  normData?: NormDto | null;
  onSave: (data: NormDto) => Promise<void>;
}

const NormDialog: React.FC<Props> = ({ open, onClose, normData, onSave }) => {
  const [error, setError] = useState<string | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);

  const {
    register,
    handleSubmit,
    reset,
    formState: { errors, isValidating },
    getValues,
    setError: setFormFieldError,
    clearErrors
  } = useForm<NormFormData>({
    resolver: zodResolver(normSchema),
    mode: 'onBlur',
    defaultValues: {
      id: 0,
      name: '',
      description: ''
    }
  });

  useEffect(() => {
    if (open) {
      setError(null);
      reset({
        id: normData?.id || 0,
        name: normData?.name || '',
        description: normData?.description || ''
      });
    }
  }, [open, normData, reset]);

  const validateUniqueness = async (property: string): Promise<boolean> => {
    const value = getValues('name');
    const id = getValues('id') || 0;
    if (!value || value.length < 3) return true;

    try {
      const isUnique = await normsService.validateUniqueness(property, value, id);
      if (!isUnique) {
        setFormFieldError('name', { type: 'manual', message: 'Norm name is already in use.' });
        return false;
      } else {
        clearErrors('name');
        return true;
      }
    } catch (err) {
      console.error('Uniqueness check failed:', err);
      return true;
    }
  };

  const onSubmit = async (data: NormFormData) => {
    setError(null);
    setIsSubmitting(true);
    try {
      const isUnique = await validateUniqueness('Name');
      if (!isUnique) {
        setIsSubmitting(false);
        return;
      }
      await onSave({ ...normData, ...data } as NormDto);
    } catch (err: any) {
      setError(err.response?.data?.message || err.message || 'An error occurred while saving.');
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <Dialog open={open} onClose={onClose}>
      <DialogHeader>{normData?.id ? 'Edit Norm' : 'Add Norm'}</DialogHeader>
      <form onSubmit={handleSubmit(onSubmit)} className={styles.normEditForm}>
        <DialogContent>
          {error && <div className="error-message">{error}</div>}
          <div className="form-group">
            <label htmlFor="norm-name">Name</label>
            <input
              id="norm-name"
              className={`form-control ${errors.name ? 'invalid' : ''}`}
              {...register('name')}
              onBlur={() => validateUniqueness('Name')}
            />
            {errors.name && <div className="validation-message">{errors.name.message}</div>}
          </div>
          <div className="form-group">
            <label htmlFor="norm-description">Description</label>
            <textarea
              id="norm-description"
              className={`form-control ${errors.description ? 'invalid' : ''}`}
              rows={3}
              {...register('description')}
            />
            {errors.description && <div className="validation-message">{errors.description.message}</div>}
          </div>
        </DialogContent>
        <DialogFooter>
          <button 
            type="submit" 
            className="action-button primary" 
            disabled={isSubmitting || isValidating}
          >
            Save
          </button>
          <button type="button" onClick={onClose} className="action-button secondary">
            Cancel
          </button>
        </DialogFooter>
      </form>
    </Dialog>
  );
};

export default NormDialog;
