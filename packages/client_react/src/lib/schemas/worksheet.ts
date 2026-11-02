import { z } from 'zod';

const codeRegex = /^(?!.*__)[a-zA-Z][a-zA-Z0-9_]*[a-zA-Z0-9]$/;
const relatedArrayRegex = /^[a-zA-Z][a-zA-Z0-9_]*$/;

export const worksheetTestSchema = z.object({
  name: z.string().min(3, "Name must be at least 3 characters long").max(50, "Name cannot exceed 50 characters"),
  code: z.string().min(2, "Code must be at least 2 characters long").max(50, "Code cannot exceed 50 characters")
    .regex(codeRegex, "Code must start with a letter, end with an alphanumeric character, contain only alphanumeric characters and underscores, and cannot have consecutive underscores."),
  description: z.string().optional().nullable(),
  measurement_unit: z.string().max(50, "Measurement unit cannot exceed 50 characters"),
  value_type: z.enum(['integer', 'real', 'boolean', 'enum'], {
    message: "Please select a value type"
  }),
  enumListString: z.string().optional().nullable(),
  is_array: z.boolean(),
  for_certification: z.boolean(),
  formula: z.string().optional().nullable(),
  code_related_arrays: z.string().max(50).optional().nullable().refine((val) => !val || val === '' || relatedArrayRegex.test(val), "Must start with a letter followed by letters, numbers and underscores"),
  condition: z.string().optional().nullable(),
  condition_note: z.string().max(150, "Condition note cannot exceed 150 characters").optional().nullable()
}).refine((data) => {
  if (data.value_type === 'enum') {
    if (!data.enumListString || data.enumListString.trim() === '') return false;
    const items = data.enumListString.split(/[\n\r,;]+/).map(s => s.trim()).filter(s => s !== '');
    if (items.length < 2) return false;
    if (items.some(item => item.length < 2 || item.length > 50)) return false;
  }
  return true;
}, {
  message: "Enum value type requires at least two items (2-50 characters each) separated by new line, comma or semicolon.",
  path: ["enumListString"]
}).refine((data) => {
  if (data.for_certification && (!data.condition || data.condition.trim() === '')) {
    return false;
  }
  return true;
}, {
  message: "Condition is required when For Certification is enabled.",
  path: ["condition"]
}).refine((data) => {
  if (data.condition && data.condition.trim() !== '') {
    if (!data.condition_note || data.condition_note.trim().length < 3) {
      return false;
    }
  }
  return true;
}, {
  message: "Condition note must be at least 3 characters when condition formula is present.",
  path: ["condition_note"]
});
