import React, { useEffect, useState } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import * as z from 'zod';
import type { CreateSopWithVersionDto } from '@/types/sop';
import sopsService from '@/services/sopsService';
import { Dialog, DialogContent, DialogHeader, DialogFooter } from '@/components/common/ui';
import { sopCreateSchema } from '@/lib/schemas/sop';
import styles from './SopAddDialog.module.css';

type SopAddFormData = z.infer<typeof sopCreateSchema>;

interface Props {
  open: boolean;
  normId: number;
  onClose: () => void;
  onSave: (dto: CreateSopWithVersionDto) => Promise<void>;
}

const SopAddDialog: React.FC<Props> = ({ open, normId, onClose, onSave }) => {
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const {
    register,
    handleSubmit,
    reset,
    getValues,
    setError: setFormFieldError,
    clearErrors,
    formState: { errors, isValidating }
  } = useForm<SopAddFormData>({
    resolver: zodResolver(sopCreateSchema),
    mode: 'onBlur',
    defaultValues: {
      docCode: '',
      title: '',
      normId,
      versionNumber: '',
      externalEdmsId: '',
      comments: ''
    }
  });

  useEffect(() => {
    if (open) {
      setError(null);
      reset({
        docCode: '',
        title: '',
        normId,
        versionNumber: '',
        externalEdmsId: '',
        comments: ''
      });
    }
  }, [open, normId, reset]);

  const validateDocCodeUniqueness = async (): Promise<boolean> => {
    const docCode = getValues('docCode');
    if (!docCode || docCode.trim().length === 0) return true;

    try {
      const isUnique = await sopsService.validateUniqueness('DocCode', docCode.trim(), 0);
      if (!isUnique) {
        setFormFieldError('docCode', { type: 'manual', message: 'Document code is already in use.' });
        return false;
      } else {
        clearErrors('docCode');
        return true;
      }
    } catch (err) {
      console.error('DocCode uniqueness check failed:', err);
      return true;
    }
  };

  const onSubmit = async (data: SopAddFormData) => {
    try {
      setSubmitting(true);
      setError(null);
      
      const isUnique = await validateDocCodeUniqueness();
      if (!isUnique) {
        setSubmitting(false);
        return;
      }

      await onSave({
        docCode: data.docCode.trim(),
        title: data.title.trim(),
        normId,
        versionNumber: data.versionNumber.trim(),
        externalEdmsId: data.externalEdmsId?.trim() || null,
        comments: data.comments?.trim() || null
      });
      onClose();
    } catch (err: any) {
      console.error('Error saving SOP:', err);
      setError(err?.response?.data?.msg || err?.message || 'Failed to save SOP.');
    } finally {
      setSubmitting(false);
    }
  };

  if (!open) return null;

  return (
    <Dialog open={open} onClose={onClose}>
      <DialogHeader>Add New SOP & Initial Version</DialogHeader>
      <form onSubmit={handleSubmit(onSubmit)} id="sop-add-form" className={styles.form}>
        <DialogContent>
          {error && <div className={styles.errorBanner}>{error}</div>}

          <div className="form-group">
            <label htmlFor="sop-doc-code">Doc Code *</label>
            <input 
              id="sop-doc-code"
              type="text" 
              className={`form-control ${errors.docCode ? 'invalid' : ''}`}
              {...register('docCode')}
              onBlur={validateDocCodeUniqueness}
              placeholder="e.g., SOP-QC-001"
            />
            {errors.docCode && <div className="validation-message">{errors.docCode.message}</div>}
          </div>

          <div className="form-group">
            <label htmlFor="sop-title">Title *</label>
            <input 
              id="sop-title"
              type="text" 
              className={`form-control ${errors.title ? 'invalid' : ''}`}
              {...register('title')}
              placeholder="e.g., Procedure for Sample Testing"
            />
            {errors.title && <div className="validation-message">{errors.title.message}</div>}
          </div>

          <div className="form-group">
            <label htmlFor="sop-version-number">Initial Version Number *</label>
            <input 
              id="sop-version-number"
              type="text" 
              className={`form-control ${errors.versionNumber ? 'invalid' : ''}`}
              {...register('versionNumber')}
              placeholder="e.g., v1.0"
            />
            {errors.versionNumber && <div className="validation-message">{errors.versionNumber.message}</div>}
          </div>

          <div className="form-group">
            <label htmlFor="sop-external-edms">External EDMS ID</label>
            <input 
              id="sop-external-edms"
              type="text" 
              className={`form-control ${errors.externalEdmsId ? 'invalid' : ''}`}
              {...register('externalEdmsId')}
              placeholder="e.g., EDMS-12345" 
            />
            {errors.externalEdmsId && <div className="validation-message">{errors.externalEdmsId.message}</div>}
          </div>

          <div className="form-group">
            <label htmlFor="sop-comments">Comments / Notes</label>
            <textarea 
              id="sop-comments"
              className={`form-control ${errors.comments ? 'invalid' : ''}`}
              {...register('comments')}
              placeholder="Initial version comments..."
              rows={3} 
            />
            {errors.comments && <div className="validation-message">{errors.comments.message}</div>}
          </div>
        </DialogContent>
        <DialogFooter>
          <button type="submit" className="action-button primary" disabled={submitting || isValidating}>
            {submitting ? 'Saving...' : 'Save SOP'}
          </button>
          <button type="button" onClick={onClose} className="action-button secondary" disabled={submitting}>
            Cancel
          </button>
        </DialogFooter>
      </form>
    </Dialog>
  );
};

export default SopAddDialog;
