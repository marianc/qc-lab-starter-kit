import { z } from 'zod';

export const equipmentSchema = z.object({
  id: z.number().optional(),
  equipmentCode: z.string().min(2, 'Code must be at least 2 characters').max(20, 'Code must be at most 20 characters'),
  name: z.string().min(2, 'Name must be at least 2 characters').max(100, 'Name must be at most 100 characters'),
  manufacturer: z.string().max(100).nullable().optional(),
  model: z.string().max(100).nullable().optional(),
  serialNumber: z.string().min(1, 'Serial number is required').max(50),
  location: z.string().max(100).nullable().optional(),
  statusId: z.number().min(1, 'Status is required'),
  calibrationIntervalDays: z.number().int().positive().nullable().optional()
});

export const calibrationSchema = z.object({
  calibrationDate: z.string().min(1, 'Calibration date is required'),
  expirationDate: z.string().min(1, 'Expiration date is required'),
  certificateNumber: z.string().min(1, 'Certificate number is required').max(50),
  calibratedBy: z.string().min(1, 'Calibrated by is required').max(100),
  statusId: z.number().min(1, 'Status is required'),
  referenceStandardsUsed: z.string().max(500).nullable().optional(),
  expandedUncertainty: z.number().nullable().optional()
});
