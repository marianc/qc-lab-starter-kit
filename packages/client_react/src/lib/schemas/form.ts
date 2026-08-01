import { z } from 'zod';

export const formSchema = z.object({
  id: z.number(),
  formGroupId: z.number(),
  version: z.string().min(1).max(50),
  customNav: z.string().max(100).optional().nullable(),
  isCustomized: z.boolean(),
}).refine((data) => {
  if (data.isCustomized) {
    return !!data.customNav && data.customNav.trim() !== '';
  }
  return true;
}, {
  message: "Custom Nav is required when Is Customized is checked.",
  path: ["customNav"],
});
