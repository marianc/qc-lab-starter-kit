import React, { useEffect } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import * as z from 'zod';
import { Dialog, DialogHeader, DialogContent, DialogFooter } from '../common/ui';
import styles from './MeasurementUnitDialog.module.css';
import type { UnitDto } from '@/types/unit';
import unitsService from '@/services/unitsService';
import { unitSchema } from '@/lib/schemas/unit';

interface MeasurementUnitDialogProps {
  open: boolean;
  unitData?: UnitDto | null;
  onSave: (unit: UnitDto) => void;
  onClose: () => void;
}

type UnitFormValues = z.infer<typeof unitSchema>;

const MeasurementUnitDialog: React.FC<MeasurementUnitDialogProps> = ({ open, unitData, onSave, onClose }) => {
  const [isValidating, setIsValidating] = React.useState(false);
  const {
    register,
    handleSubmit,
    reset,
    setError,
    clearErrors,
    getValues,
    formState: { errors }
  } = useForm<UnitFormValues>({
    resolver: zodResolver(unitSchema),
    defaultValues: {
      id: 0,
      name: '',
      description: ''
    }
  });

  useEffect(() => {
    if (open) {
      reset({
        id: unitData?.id ?? 0,
        name: unitData?.name ?? '',
        description: unitData?.description ?? ''
      });
    }
  }, [open, unitData, reset]);

  const validateUniqueness = async (property: string): Promise<boolean> => {
    const value = getValues('name');
    if (!value) return true;

    setIsValidating(true);
    try {
      const isUnique = await unitsService.validateUniqueness(property, value, getValues('id'));
      if (!isUnique) {
        setError('name', {
          type: 'manual',
          message: `${property} is already in use.`
        });
        return false;
      } else {
        clearErrors('name');
        return true;
      }
    } catch (err) {
      console.error(`Uniqueness check failed:`, err);
      return false;
    } finally {
      setIsValidating(false);
    }
  };

  const onSubmit = async (values: UnitFormValues) => {
    const isUnique = await validateUniqueness('Name');
    if (isUnique) {
      onSave(values as UnitDto);
    }
  };

  const nameRegister = register('name');

  return (
    <Dialog open={open} onClose={onClose}>
      <DialogHeader>
        {unitData?.id ? "Edit" : "Add"} Measurement Unit
      </DialogHeader>
      <form onSubmit={handleSubmit(onSubmit)} className={styles.unitEditForm}>
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
            <label>Description</label>
            <textarea 
              {...register('description')} 
              className="form-control" 
              rows={3}
            />
            {errors.description && <span className="text-danger">{errors.description.message}</span>}
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

export default MeasurementUnitDialog;
