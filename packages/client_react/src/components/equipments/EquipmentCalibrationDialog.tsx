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
import type { CreateEquipmentCalibrationDto } from '@/types/equipment';

const calibrationSchema = z.object({
  calibrationDate: z.string().min(1, 'Calibration date is required'),
  expirationDate: z.string().min(1, 'Expiration date is required'),
  certificateNumber: z.string().min(1, 'Certificate number is required').max(50),
  calibratedBy: z.string().min(1, 'Calibrated by is required').max(100),
  resultStatus: z.string().min(1, 'Result status is required'),
  referenceStandardsUsed: z.string().max(500).nullable().optional(),
  expandedUncertainty: z.number().nullable().optional()
});

type FormData = z.infer<typeof calibrationSchema>;

interface Props {
  open: boolean;
  onSave: (data: CreateEquipmentCalibrationDto) => void;
  onClose: () => void;
}

const EquipmentCalibrationDialog: React.FC<Props> = ({ open, onSave, onClose }) => {
  const { register, handleSubmit, reset, formState: { errors } } = useForm<FormData>({
    resolver: zodResolver(calibrationSchema),
    defaultValues: {
      calibrationDate: new Date().toISOString().split('T')[0],
      expirationDate: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
      certificateNumber: '',
      calibratedBy: '',
      resultStatus: 'Pass',
      referenceStandardsUsed: '',
      expandedUncertainty: null
    }
  });

  React.useEffect(() => {
    if (open) {
      reset({
        calibrationDate: new Date().toISOString().split('T')[0],
        expirationDate: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
        certificateNumber: '',
        calibratedBy: '',
        resultStatus: 'Pass',
        referenceStandardsUsed: '',
        expandedUncertainty: null
      });
    }
  }, [open, reset]);

  const onSubmit = (data: FormData) => {
    onSave({
      calibrationDate: data.calibrationDate,
      expirationDate: data.expirationDate,
      certificateNumber: data.certificateNumber,
      calibratedBy: data.calibratedBy,
      resultStatus: data.resultStatus,
      referenceStandardsUsed: data.referenceStandardsUsed || null,
      expandedUncertainty: data.expandedUncertainty !== null && !isNaN(data.expandedUncertainty as any) ? Number(data.expandedUncertainty) : null
    });
  };

  if (!open) return null;

  return (
    <Dialog open={open} onClose={onClose}>
      <DialogHeader>Add Equipment Calibration</DialogHeader>
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
            <label htmlFor="resultStatus">Result Status</label>
            <select 
              id="resultStatus" 
              className={`form-control ${errors.resultStatus ? 'invalid' : ''}`}
              {...register('resultStatus')}
            >
              <option value="Pass">Pass</option>
              <option value="Fail">Fail</option>
              <option value="Limited Use">Limited Use</option>
            </select>
            {errors.resultStatus && <div className="validation-message">{errors.resultStatus.message}</div>}
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
