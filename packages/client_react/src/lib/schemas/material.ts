import { z } from 'zod';

export const materialSchema = z.object({
  id: z.number(),
  name: z.string().min(3).max(50),
  code: z.string().min(2).max(10).regex(/^[A-Z][A-Z0-9]*$/, "Code must start with a letter and contain only uppercase alphanumeric characters."),
  description: z.string().optional().nullable(),
  normId: z.any(),
  isProduct: z.boolean(),
  isRawMaterial: z.boolean(),
  isReagent: z.boolean(),
  isObsolete: z.boolean(),
});


