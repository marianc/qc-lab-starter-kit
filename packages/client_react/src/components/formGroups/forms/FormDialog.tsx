import React, { useEffect } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import * as z from 'zod';
import { Dialog, DialogHeader, DialogContent, DialogFooter } from '../../common/ui';
import styles from './FormDialog.module.css';
import type { FormDetailDto } from '@/types/form';
import { formSchema } from '@/lib/schemas/form';

interface FormDialogProps {
  open: boolean;
  formData: FormDetailDto;
  onSave: (data: FormDetailDto) => void;
  onClose: () => void;
}

type FormValues = z.infer<typeof formSchema>;

const FormDialog: React.FC<FormDialogProps> = ({ open, formData, onSave, onClose }) => {
  const {
    register,
    handleSubmit,
    reset,
    watch,
    formState: { errors }
  } = useForm<FormValues>({
    resolver: zodResolver(formSchema),
    defaultValues: {
      id: 0,
      formGroupId: 0,
      version: '',
      customNav: '',
      isCustomized: false
    }
  });

  const watchIsCustomized = watch('isCustomized');

  useEffect(() => {
    if (open) {
      reset({
        id: formData.id,
        formGroupId: formData.formGroupId,
        version: formData.version || '',
        customNav: formData.customNav || '',
        isCustomized: formData.isCustomized
      });
    }
  }, [open, formData, reset]);

  const onSubmit = (values: FormValues) => {
    onSave({ ...formData, ...values });
  };

  return (
    <Dialog open={open} onClose={onClose}>
      <DialogHeader>
        Edit Form {formData.id}
      </DialogHeader>
      <form onSubmit={handleSubmit(onSubmit)} className={styles.formEditForm}>
        <DialogContent>
          <div className="form-group">
            <label>Version</label>
            <input {...register('version')} className="form-control" />
            {errors.version && <span className="text-danger">{errors.version.message}</span>}
          </div>

          <div className={`form-group ${styles.checkboxGroup}`}>
            <input type="checkbox" id="is_customized" {...register('isCustomized')} />
            <label htmlFor="is_customized">Is Customized</label>
          </div>

          {watchIsCustomized && (
            <div className="form-group">
              <label>Custom Navigation</label>
              <input {...register('customNav')} className="form-control" />
              {errors.customNav && <span className="text-danger">{errors.customNav.message}</span>}
            </div>
          )}
        </DialogContent>
        <DialogFooter>
          <button type="submit" className="action-button primary">Save</button>
          <button type="button" className="action-button secondary" onClick={onClose}>Cancel</button>
        </DialogFooter>
      </form>
    </Dialog>
  );
};

export default FormDialog;
