import { z } from 'zod';

export const certificationSchema = z.object({
  materialId: z.coerce.number().min(1, 'Material is required'),
  controlCodeId: z.coerce.number().optional().nullable(),
  controlCodeName: z.string().max(50, 'Control code must be maximum 50 characters')
    .regex(/^\S*$/, 'No empty spaces allowed')
    .optional()
    .nullable(),
  comments: z.string().optional().nullable()
}).refine(data => data.controlCodeId || data.controlCodeName, {
  message: "Please select an existing code or enter a new one.",
  path: ["controlCodeId"]
});

export const verificationSchema = z.object({
  materialId: z.coerce.number().min(1, 'Material is required'),
  controlCodeId: z.coerce.number().optional().nullable(),
  controlCodeName: z.string().max(50, 'Control code must be maximum 50 characters')
    .regex(/^\S*$/, 'No empty spaces allowed')
    .optional()
    .nullable(),
  comments: z.string().optional().nullable(),
  testIds: z.array(z.number()).min(1, 'At least one test must be selected.')
}).refine(data => data.controlCodeId || data.controlCodeName, {
  message: "Please select an existing code or enter a new one.",
  path: ["controlCodeId"]
});

export const categoryVerificationSchema = z.object({
  materialName: z.string().min(1, 'Material Name is required'),
  categoryId: z.coerce.number().min(1, 'Category is required'),
  comments: z.string().optional().nullable(),
  testIds: z.array(z.number()).min(1, 'At least one test must be selected.')
});

export const measurementSchema = z.object({
  testId: z.coerce.number().min(1, 'Test is required'),
  note: z.string().optional().nullable(),
  value: z.any()
}).refine((data) => {
  if (data.value === undefined || data.value === null || data.value === '') return false;
  if (Array.isArray(data.value) && data.value.length === 0) return false;
  return true;
}, {
  message: "Value is required",
  path: ["value"]
});
