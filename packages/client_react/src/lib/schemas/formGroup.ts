import { z } from 'zod';

export const formGroupSchema = z.object({
  id: z.number(),
  name: z.string().min(3).max(100),
  description: z.string().optional().nullable(),
  nrOrd: z.number().int(),
});

