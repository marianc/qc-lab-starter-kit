import React, { useEffect, useState } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import * as z from 'zod';
import { Dialog, DialogHeader, DialogContent, DialogFooter } from '../common/ui';
import styles from './FormGroupDialog.module.css';
import type { FormGroupDto } from '@/types/formGroup';
import { formGroupSchema } from '@/lib/schemas/formGroup';

interface FormGroupDialogProps {
  open: boolean;
  formGroupData?: FormGroupDto | null;
  onSave: (data: FormGroupDto) => void;
  onClose: () => void;
}

type FormGroupFormValues = z.infer<typeof formGroupSchema>;

const FormGroupDialog: React.FC<FormGroupDialogProps> = ({ open, formGroupData, onSave, onClose }) => {
  const {
    register,
    handleSubmit,
    reset,
    formState: { errors }
  } = useForm<FormGroupFormValues>({
    resolver: zodResolver(formGroupSchema),
    defaultValues: {
      id: 0,
      name: '',
      description: '',
      nrOrd: 0
    }
  });

  useEffect(() => {
    if (open) {
      if (formGroupData) {
        reset({
          id: formGroupData.id,
          name: formGroupData.name,
          description: formGroupData.description || '',
          nrOrd: formGroupData.nrOrd
        });
      } else {
        reset({
          id: 0,
          name: '',
          description: '',
          nrOrd: 0
        });
      }
    }
  }, [open, formGroupData, reset]);

  const onSubmit = (values: FormGroupFormValues) => {
    onSave(values as FormGroupDto);
  };

  return (
    <Dialog open={open} onClose={onClose}>
      <DialogHeader>
        {formGroupData?.id ? "Edit Form Group" : "Add Form Group"}
      </DialogHeader>
      <form onSubmit={handleSubmit(onSubmit)} className={styles.formGroupEditForm}>
        <DialogContent>
          <div className="form-group">
            <label>Name</label>
            <input 
              {...register('name')} 
              className="form-control" 
            />
            {errors.name && <span className="text-danger">{errors.name.message}</span>}
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
            <label>Order</label>
            <input 
              type="number" 
              {...register('nrOrd', { valueAsNumber: true })} 
              className="form-control" 
            />
            {errors.nrOrd && <span className="text-danger">{errors.nrOrd.message}</span>}
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

export default FormGroupDialog;
