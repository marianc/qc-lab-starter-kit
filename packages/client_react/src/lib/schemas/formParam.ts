import { z } from 'zod';

const formConditionEvalSchema = z.object({
  id: z.number().optional().nullable(),
  value: z.coerce.number(),
  expectedResult: z.coerce.number(),
  note: z.string().optional().nullable()
});

export const formParamSchema = z.object({
  testId: z.coerce.number().min(1, "Test is required."),
  isCalculated: z.boolean(),
  formula: z.string().optional().nullable(),
  codeRelatedArrays: z.string().optional().nullable(),
  isRequired: z.boolean(),
  defaultValue: z.coerce.number().optional().nullable(),
  nrOrd: z.number().int(),
  nrOrdCalc: z.number().int(),
  hasCondition: z.boolean(),
  condition: z.string().optional().nullable(),
  conditionNote: z.string().optional().nullable(),
  evals: z.array(formConditionEvalSchema).optional()
}).superRefine((data, ctx) => {
  if (data.hasCondition) {
    if (!data.condition || data.condition.trim().length === 0) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: "Condition is required.",
        path: ["condition"],
      });
    }
    if (!data.conditionNote || data.conditionNote.trim().length === 0) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: "Condition Note is required.",
        path: ["conditionNote"],
      });
    }
    if (!data.evals || data.evals.length === 0) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: "At least one verification test is required.",
        path: ["evals"],
      });
    }
  }
});
