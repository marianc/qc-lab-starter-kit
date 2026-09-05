import React, { useEffect, useState } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import * as z from 'zod';
import type { SopVersionDto, UpdateSopVersionDto } from '@/types/sop';
import sopsService from '@/services/sopsService';
import { Dialog, DialogContent, DialogHeader, DialogFooter } from '@/components/common/ui';
import { sopVersionUpdateSchema } from '@/lib/schemas/sop';
import styles from './SopVersionEditDialog.module.css';

type SopVersionEditFormData = z.infer<typeof sopVersionUpdateSchema>;

interface Props {
  open: boolean;
  sopId: number;
  versionData?: SopVersionDto | null;
  onClose: () => void;
  onSave: (dto: UpdateSopVersionDto) => Promise<void>;
}

const SopVersionEditDialog: React.FC<Props> = ({ open, sopId, versionData, onClose, onSave }) => {
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const isEditing = !!versionData;

  const {
    register,
    handleSubmit,
    reset,
    getValues,
    setError: setFormFieldError,
    clearErrors,
    formState: { errors, isValidating }
  } = useForm<SopVersionEditFormData>({
    resolver: zodResolver(sopVersionUpdateSchema),
    mode: 'onBlur',
    defaultValues: {
      versionNumber: versionData?.versionNumber || '',
      externalEdmsId: versionData?.externalEdmsId || '',
      comments: versionData?.comments || ''
    }
  });

  useEffect(() => {
    if (open) {
      setError(null);
      reset({
        versionNumber: versionData?.versionNumber || '',
        externalEdmsId: versionData?.externalEdmsId || '',
        comments: versionData?.comments || ''
      });
    }
  }, [open, versionData, reset]);

  const validateVersionNumberUniqueness = async (): Promise<boolean> => {
    const versionNumber = getValues('versionNumber');
    if (!versionNumber || versionNumber.trim().length === 0) return true;

    try {
      const isUnique = await sopsService.validateVersionUniqueness(
        'VersionNumber', 
        versionNumber.trim(), 
        isEditing ? versionData.id : 0, 
        sopId
      );
      if (!isUnique) {
        setFormFieldError('versionNumber', { type: 'manual', message: 'Version number already exists for this SOP.' });
        return false;
      } else {
        clearErrors('versionNumber');
        return true;
      }
    } catch (err) {
      console.error('VersionNumber uniqueness check failed:', err);
      return true;
    }
  };

  const onSubmit = async (data: SopVersionEditFormData) => {
    try {
      setSubmitting(true);
      setError(null);

      const isUnique = await validateVersionNumberUniqueness();
      if (!isUnique) {
        setSubmitting(false);
        return;
      }

      await onSave({
        versionNumber: data.versionNumber.trim(),
        externalEdmsId: data.externalEdmsId?.trim() || null,
        comments: data.comments?.trim() || null
      });
      onClose();
    } catch (err: any) {
      console.error('Error saving SOP version:', err);
      setError(err?.response?.data?.msg || err?.message || 'Failed to save SOP version.');
    } finally {
      setSubmitting(false);
    }
  };

  if (!open) return null;

  return (
    <Dialog open={open} onClose={onClose}>
      <DialogHeader>{isEditing ? `Edit SOP Version ${versionData.versionNumber}` : 'Add New SOP Version'}</DialogHeader>
      <form onSubmit={handleSubmit(onSubmit)} id="sop-version-edit-form" className={styles.form}>
        <DialogContent>
          {error && <div className={styles.errorBanner}>{error}</div>}

          <div className="form-group">
            <label htmlFor="sop-edit-version-number">Version Number *</label>
            <input 
              id="sop-edit-version-number"
              type="text" 
              className={`form-control ${errors.versionNumber ? 'invalid' : ''}`}
              {...register('versionNumber')}
              onBlur={validateVersionNumberUniqueness}
              required 
            />
            {errors.versionNumber && <div className="validation-message">{errors.versionNumber.message}</div>}
          </div>

          <div className="form-group">
            <label htmlFor="sop-edit-external-edms">External EDMS ID</label>
            <input 
              id="sop-edit-external-edms"
              type="text" 
              className={`form-control ${errors.externalEdmsId ? 'invalid' : ''}`}
              {...register('externalEdmsId')}
            />
            {errors.externalEdmsId && <div className="validation-message">{errors.externalEdmsId.message}</div>}
          </div>

          <div className="form-group">
            <label htmlFor="sop-edit-comments">Comments / Notes</label>
            <textarea 
              id="sop-edit-comments"
              className={`form-control ${errors.comments ? 'invalid' : ''}`}
              {...register('comments')}
              rows={3} 
            />
            {errors.comments && <div className="validation-message">{errors.comments.message}</div>}
          </div>
        </DialogContent>
        <DialogFooter>
          <button type="submit" className="action-button primary" disabled={submitting || isValidating}>
            {submitting ? 'Saving...' : 'Save Changes'}
          </button>
          <button type="button" onClick={onClose} className="action-button secondary" disabled={submitting}>
            Cancel
          </button>
        </DialogFooter>
      </form>
    </Dialog>
  );
};

export default SopVersionEditDialog;
