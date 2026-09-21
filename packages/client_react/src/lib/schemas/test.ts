import { z } from 'zod';

export const testEnumSchema = z.object({
  testId: z.number(),
  value: z.number().int(),
  name: z.string().min(1).max(50),
  nrOrd: z.number().int(),
  originalValue: z.number().optional().nullable(),
});

export const testSchema = z.object({
  id: z.number(),
  name: z.string().min(3).max(50),
  code: z.string().min(2).max(50).regex(/^(?!.*__)[a-zA-Z][a-zA-Z0-9_]*[a-zA-Z0-9]$/, "Code must start with a letter, end with an alphanumeric character, contain only alphanumeric characters and underscores, and cannot have consecutive underscores."),
  description: z.string().optional().nullable(),
  typeId: z.coerce.number().min(1, "Value Type is required."),
  isArray: z.boolean(),
  isParam: z.boolean(),
  forEnvironmentalControl: z.boolean(),
  forCertification: z.boolean(),
  relativeUncertaintyPct: z.coerce.number().optional().nullable(),
  defaultCoverageFactorK: z.coerce.number().optional().nullable(),
  unitId: z.any(),
  normId: z.any(),
  normRef: z.string().max(50).optional().nullable(),
  sopId: z.any(),
  nrOrd: z.number().int(),
  enumListString: z.string().optional().nullable(),
}).refine((data) => {
  if (data.id === 0 && Number(data.typeId) === 4) {
    if (!data.enumListString) return false;
    const items = data.enumListString.split(/[\n\r,;]+/).map(s => s.trim()).filter(s => s !== '');
    const uniqueItems = Array.from(new Set(items));
    return uniqueItems.length >= 2;
  }
  return true;
}, {
  message: "At least two unique items must be introduced in the list.",
  path: ["enumListString"]
});
