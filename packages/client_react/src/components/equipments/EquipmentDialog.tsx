import React from 'react';
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

const equipmentSchema = z.object({
  equipmentCode: z.string().min(2, 'Code must be at least 2 characters').max(20, 'Code must be at most 20 characters'),
  name: z.string().min(2, 'Name must be at least 2 characters').max(100, 'Name must be at most 100 characters'),
  manufacturer: z.string().max(100).nullable().optional(),
  model: z.string().max(100).nullable().optional(),
  serialNumber: z.string().min(1, 'Serial number is required').max(50),
  location: z.string().max(100).nullable().optional(),
  status: z.string().min(1, 'Status is required'),
  calibrationIntervalDays: z.number().int().positive().nullable().optional()
});

type FormData = z.infer<typeof equipmentSchema>;

interface Props {
  open: boolean;
  equipment?: EquipmentDto | null;
  onSave: (data: CreateEquipmentDto) => void;
  onClose: () => void;
}

const EquipmentDialog: React.FC<Props> = ({ open, equipment, onSave, onClose }) => {
  const { register, handleSubmit, reset, formState: { errors } } = useForm<FormData>({
    resolver: zodResolver(equipmentSchema),
    defaultValues: {
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
      reset({
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

  const onSubmit = (data: FormData) => {
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
  };

  if (!open) return null;

  return (
    <Dialog open={open} onClose={onClose}>
      <DialogHeader>
        {equipment ? 'Edit Equipment' : 'Add New Equipment'}
      </DialogHeader>
      <DialogContent>
        <form id="equipment-form" onSubmit={handleSubmit(onSubmit)}>
          <div className="form-group">
            <label htmlFor="equipmentCode">Equipment Code</label>
            <input 
              id="equipmentCode" 
              type="text" 
              className={`form-control ${errors.equipmentCode ? 'invalid' : ''}`}
              {...register('equipmentCode')} 
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
