import React, { useState, useEffect } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { 
  Dialog, 
  DialogHeader, 
  DialogContent, 
  DialogFooter 
} from '@/components/common/ui';
import type { EquipmentCalibrationDto, CreateEquipmentCalibrationDto, EquipmentCalibrationStatusDto } from '@/types/equipment';
import equipmentsService from '@/services/equipmentsService';
import { calibrationSchema } from '@/lib/schemas/equipment';

type FormData = z.infer<typeof calibrationSchema>;

interface Props {
  open: boolean;
  calibration?: EquipmentCalibrationDto | null;
  onSave: (data: CreateEquipmentCalibrationDto) => void;
  onClose: () => void;
}

const EquipmentCalibrationDialog: React.FC<Props> = ({ open, calibration, onSave, onClose }) => {
  const [statuses, setStatuses] = useState<EquipmentCalibrationStatusDto[]>([]);

  useEffect(() => {
    if (open) {
      equipmentsService.getEquipmentCalibrationStatuses()
        .then(setStatuses)
        .catch(err => console.error('Failed to load equipment calibration statuses', err));
    }
  }, [open]);

  const { register, handleSubmit, reset, formState: { errors } } = useForm<FormData>({
    resolver: zodResolver(calibrationSchema),
    defaultValues: {
      calibrationDate: calibration?.calibrationDate || new Date().toISOString().split('T')[0],
      expirationDate: calibration?.expirationDate || new Date(Date.now() + 365 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
      certificateNumber: calibration?.certificateNumber || '',
      calibratedBy: calibration?.calibratedBy || '',
      statusId: calibration?.statusId || 1,
      referenceStandardsUsed: calibration?.referenceStandardsUsed || '',
      expandedUncertainty: calibration?.expandedUncertainty !== null && calibration?.expandedUncertainty !== undefined ? calibration.expandedUncertainty : null
    }
  });

  React.useEffect(() => {
    if (open) {
      reset({
        calibrationDate: calibration?.calibrationDate || new Date().toISOString().split('T')[0],
        expirationDate: calibration?.expirationDate || new Date(Date.now() + 365 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
        certificateNumber: calibration?.certificateNumber || '',
        calibratedBy: calibration?.calibratedBy || '',
        statusId: calibration?.statusId || (statuses.length > 0 ? statuses[0].id : 1),
        referenceStandardsUsed: calibration?.referenceStandardsUsed || '',
        expandedUncertainty: calibration?.expandedUncertainty !== null && calibration?.expandedUncertainty !== undefined ? calibration.expandedUncertainty : null
      });
    }
  }, [open, calibration, statuses, reset]);

  const onSubmit = (data: FormData) => {
    onSave({
      calibrationDate: data.calibrationDate,
      expirationDate: data.expirationDate,
      certificateNumber: data.certificateNumber,
      calibratedBy: data.calibratedBy,
      statusId: Number(data.statusId),
      referenceStandardsUsed: data.referenceStandardsUsed || null,
      expandedUncertainty: data.expandedUncertainty !== null && !isNaN(data.expandedUncertainty as any) ? Number(data.expandedUncertainty) : null
    });
  };

  if (!open) return null;

  return (
    <Dialog open={open} onClose={onClose}>
      <DialogHeader>{calibration ? 'Edit Equipment Calibration' : 'Add Equipment Calibration'}</DialogHeader>
      <DialogContent>
        <form id="calibration-form" onSubmit={handleSubmit(onSubmit)}>
          <div className="form-group">
            <label htmlFor="calibrationDate">Calibration Date</label>
            <input 
              id="calibrationDate" 
              type="date" 
              className={`form-control ${errors.calibrationDate ? 'invalid' : ''}`}
              {...register('calibrationDate')} 
            />
            {errors.calibrationDate && <div className="validation-message">{errors.calibrationDate.message}</div>}
          </div>
          <div className="form-group">
            <label htmlFor="expirationDate">Expiration Date</label>
            <input 
              id="expirationDate" 
              type="date" 
              className={`form-control ${errors.expirationDate ? 'invalid' : ''}`}
              {...register('expirationDate')} 
            />
            {errors.expirationDate && <div className="validation-message">{errors.expirationDate.message}</div>}
          </div>
          <div className="form-group">
            <label htmlFor="certificateNumber">Certificate Number</label>
            <input 
              id="certificateNumber" 
              type="text" 
              className={`form-control ${errors.certificateNumber ? 'invalid' : ''}`}
              {...register('certificateNumber')} 
            />
            {errors.certificateNumber && <div className="validation-message">{errors.certificateNumber.message}</div>}
          </div>
          <div className="form-group">
            <label htmlFor="calibratedBy">Calibrated By</label>
            <input 
              id="calibratedBy" 
              type="text" 
              className={`form-control ${errors.calibratedBy ? 'invalid' : ''}`}
              {...register('calibratedBy')} 
            />
            {errors.calibratedBy && <div className="validation-message">{errors.calibratedBy.message}</div>}
          </div>
          <div className="form-group">
            <label htmlFor="statusId">Result Status</label>
            <select 
              id="statusId" 
              className={`form-control ${errors.statusId ? 'invalid' : ''}`}
              {...register('statusId', { valueAsNumber: true })}
            >
              {statuses.map(st => (
                <option key={st.id} value={st.id}>{st.name}</option>
              ))}
            </select>
            {errors.statusId && <div className="validation-message">{errors.statusId.message}</div>}
          </div>
          <div className="form-group">
            <label htmlFor="referenceStandardsUsed">Reference Standards Used</label>
            <input 
              id="referenceStandardsUsed" 
              type="text" 
              className={`form-control ${errors.referenceStandardsUsed ? 'invalid' : ''}`}
              {...register('referenceStandardsUsed')} 
            />
            {errors.referenceStandardsUsed && <div className="validation-message">{errors.referenceStandardsUsed.message}</div>}
          </div>
          <div className="form-group">
            <label htmlFor="expandedUncertainty">Expanded Uncertainty</label>
            <input 
              id="expandedUncertainty" 
              type="number" 
              step="any"
              className={`form-control ${errors.expandedUncertainty ? 'invalid' : ''}`}
              {...register('expandedUncertainty', { valueAsNumber: true, emptyAsNull: true } as any)} 
            />
            {errors.expandedUncertainty && <div className="validation-message">{errors.expandedUncertainty.message}</div>}
          </div>
        </form>
      </DialogContent>
      <DialogFooter>
        <button type="submit" form="calibration-form" className="action-button primary">Save</button>
        <button type="button" onClick={onClose} className="action-button secondary">Cancel</button>
      </DialogFooter>
    </Dialog>
  );
};

export default EquipmentCalibrationDialog;
