import { z } from 'zod';

export const unitSchema = z.object({
  id: z.number(),
  name: z.string().min(1).max(50),
  description: z.string().optional().nullable(),
});
