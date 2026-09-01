import { z } from 'zod';

export const specTestEvalSchema = z.object({
  id: z.number().optional().nullable(),
  value: z.number(),
  expectedResult: z.number(),
  note: z.string().optional().nullable()
});

export const specTestSchema = z.object({
  testId: z.number().min(1, 'Test is required'),
  condition: z.string().min(1, 'Condition is required'),
  note: z.string().min(1, 'Note is required'),
  useUncertainty: z.boolean(),
  testFrequency: z.number().min(0, 'Frequency must be at least 0'),
  evals: z.array(specTestEvalSchema).min(1, 'At least one evaluation test is required')
});

export const specSchema = z.object({
  materialId: z.number().min(1, 'Material is required')
});
