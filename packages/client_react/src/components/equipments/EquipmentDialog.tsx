import React, { useState } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import * as z from 'zod';
import { 
  Dialog, 
  DialogHeader, 
  DialogContent, 
  DialogFooter 
} from '@/components/common/ui';
import type { EquipmentDto, CreateEquipmentDto } from '@/types/equipment';
import equipmentsService from '@/services/equipmentsService';
import { equipmentSchema } from '@/lib/schemas/equipment';

type FormData = z.infer<typeof equipmentSchema>;

interface Props {
  open: boolean;
  equipment?: EquipmentDto | null;
  onSave: (data: CreateEquipmentDto) => void;
  onClose: () => void;
}

const EquipmentDialog: React.FC<Props> = ({ open, equipment, onSave, onClose }) => {
  const [error, setError] = useState<string | null>(null);

  const { 
    register, 
    handleSubmit, 
    reset, 
    getValues,
    setError: setFormFieldError,
    clearErrors,
    formState: { errors } 
  } = useForm<FormData>({
    resolver: zodResolver(equipmentSchema),
    mode: 'onBlur',
    defaultValues: {
      id: equipment?.id || 0,
      equipmentCode: equipment?.equipmentCode || '',
      name: equipment?.name || '',
      manufacturer: equipment?.manufacturer || '',
      model: equipment?.model || '',
      serialNumber: equipment?.serialNumber || '',
      location: equipment?.location || '',
      status: equipment?.status || 'Active',
      calibrationIntervalDays: equipment?.calibrationIntervalDays || null
    }
  });

  React.useEffect(() => {
    if (open) {
      setError(null);
      reset({
        id: equipment?.id || 0,
        equipmentCode: equipment?.equipmentCode || '',
        name: equipment?.name || '',
        manufacturer: equipment?.manufacturer || '',
        model: equipment?.model || '',
        serialNumber: equipment?.serialNumber || '',
        location: equipment?.location || '',
        status: equipment?.status || 'Active',
        calibrationIntervalDays: equipment?.calibrationIntervalDays || null
      });
    }
  }, [open, equipment, reset]);

  const validateCodeUniqueness = async (): Promise<boolean> => {
    const code = getValues('equipmentCode');
    const id = getValues('id') || 0;
    if (!code || code.length < 2) return true;

    try {
      const isUnique = await equipmentsService.validateUniqueness('EquipmentCode', code, id);
      if (!isUnique) {
        setFormFieldError('equipmentCode', { type: 'manual', message: 'Equipment code is already in use.' });
        return false;
      } else {
        clearErrors('equipmentCode');
        return true;
      }
    } catch (err) {
      console.error('Uniqueness check failed:', err);
      return true;
    }
  };

  const onSubmit = async (data: FormData) => {
    setError(null);
    try {
      const isUnique = await validateCodeUniqueness();
      if (!isUnique) return;

      onSave({
        equipmentCode: data.equipmentCode,
        name: data.name,
        manufacturer: data.manufacturer || null,
        model: data.model || null,
        serialNumber: data.serialNumber,
        location: data.location || null,
        status: data.status,
        calibrationIntervalDays: data.calibrationIntervalDays ? Number(data.calibrationIntervalDays) : null
      });
    } catch (err: any) {
      setError(err.response?.data?.msg || err.message || 'An error occurred while saving.');
    }
  };

  if (!open) return null;

  return (
    <Dialog open={open} onClose={onClose}>
      <DialogHeader>
        {equipment ? 'Edit Equipment' : 'Add New Equipment'}
      </DialogHeader>
      <DialogContent>
        {error && <div className="error-message" style={{ color: 'red', marginBottom: '1rem' }}>{error}</div>}
        <form id="equipment-form" onSubmit={handleSubmit(onSubmit)}>
          <div className="form-group">
            <label htmlFor="equipmentCode">Equipment Code</label>
            <input 
              id="equipmentCode" 
              type="text" 
              className={`form-control ${errors.equipmentCode ? 'invalid' : ''}`}
              {...register('equipmentCode', {
                onBlur: async () => {
                  await validateCodeUniqueness();
                }
              })} 
            />
            {errors.equipmentCode && <div className="validation-message">{errors.equipmentCode.message}</div>}
          </div>
          <div className="form-group">
            <label htmlFor="name">Name</label>
            <input 
              id="name" 
              type="text" 
              className={`form-control ${errors.name ? 'invalid' : ''}`}
              {...register('name')} 
            />
            {errors.name && <div className="validation-message">{errors.name.message}</div>}
          </div>
          <div className="form-group">
            <label htmlFor="manufacturer">Manufacturer</label>
            <input 
              id="manufacturer" 
              type="text" 
              className={`form-control ${errors.manufacturer ? 'invalid' : ''}`}
              {...register('manufacturer')} 
            />
            {errors.manufacturer && <div className="validation-message">{errors.manufacturer.message}</div>}
          </div>
          <div className="form-group">
            <label htmlFor="model">Model</label>
            <input 
              id="model" 
              type="text" 
              className={`form-control ${errors.model ? 'invalid' : ''}`}
              {...register('model')} 
            />
            {errors.model && <div className="validation-message">{errors.model.message}</div>}
          </div>
          <div className="form-group">
            <label htmlFor="serialNumber">Serial Number</label>
            <input 
              id="serialNumber" 
              type="text" 
              className={`form-control ${errors.serialNumber ? 'invalid' : ''}`}
              {...register('serialNumber')} 
            />
            {errors.serialNumber && <div className="validation-message">{errors.serialNumber.message}</div>}
          </div>
          <div className="form-group">
            <label htmlFor="location">Location</label>
            <input 
              id="location" 
              type="text" 
              className={`form-control ${errors.location ? 'invalid' : ''}`}
              {...register('location')} 
            />
            {errors.location && <div className="validation-message">{errors.location.message}</div>}
          </div>
          <div className="form-group">
            <label htmlFor="status">Status</label>
            <select 
              id="status" 
              className={`form-control ${errors.status ? 'invalid' : ''}`}
              {...register('status')}
            >
              <option value="Active">Active</option>
              <option value="Inactive">Inactive</option>
              <option value="Calibration Due">Calibration Due</option>
              <option value="Out of Service">Out of Service</option>
            </select>
            {errors.status && <div className="validation-message">{errors.status.message}</div>}
          </div>
          <div className="form-group">
            <label htmlFor="calibrationIntervalDays">Calibration Interval (Days)</label>
            <input 
              id="calibrationIntervalDays" 
              type="number" 
              className={`form-control ${errors.calibrationIntervalDays ? 'invalid' : ''}`}
              {...register('calibrationIntervalDays', { valueAsNumber: true, emptyAsNull: true } as any)} 
            />
            {errors.calibrationIntervalDays && <div className="validation-message">{errors.calibrationIntervalDays.message}</div>}
          </div>
        </form>
      </DialogContent>
      <DialogFooter>
        <button type="submit" form="equipment-form" className="action-button primary">Save</button>
        <button type="button" onClick={onClose} className="action-button secondary">Cancel</button>
      </DialogFooter>
    </Dialog>
  );
};

export default EquipmentDialog;
