import { z } from 'zod';

export const normSchema = z.object({
  id: z.number().optional(),
  name: z.string()
    .min(3, 'Name must be between 3 and 50 characters.')
    .max(50, 'Name must be between 3 and 50 characters.'),
  description: z.string().optional().nullable()
});

