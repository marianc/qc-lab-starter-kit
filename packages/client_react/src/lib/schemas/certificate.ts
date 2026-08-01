import { z } from 'zod';

export const certificateSchema = z.object({
  materialId: z.number().min(1, 'Material is required'),
  controlCodeId: z.number().min(1, 'Control code is required')
});

