import { z } from 'zod';

export const reagentSchema = z.object({
  id: z.number(),
  name: z.string().min(3, "Name must be between 3 and 50 characters.").max(50, "Name must be between 3 and 50 characters."),
  code: z.string().min(2, "Code must be between 2 and 5 characters.").max(5, "Code must be between 2 and 5 characters.").regex(/^[A-Z][A-Z0-9]*$/, "Code must start with a letter and contain only uppercase alphanumeric characters."),
  description: z.string().optional().nullable(),
  casNumber: z.string().max(20).optional().nullable(),
  normId: z.any(),
  isObsolete: z.boolean(),
});

export const supplierLotSchema = z.object({
  controlCode: z.string().min(1, "Control code is required.").max(50),
  catalogNumber: z.string().max(50).optional().nullable(),
  supplierId: z.any().refine(val => val !== undefined && val !== null && val !== '', { message: "Supplier is required." }),
  manufacturerLotNumber: z.string().min(1, "Manufacturer lot number is required.").max(50),
  certificateOfAnalysisRef: z.string().max(255).optional().nullable(),
  comments: z.string().max(100).optional().nullable(),
  statusId: z.number().min(1, "Status is required."),
  unitId: z.any(),
  quantity: z.number().min(0, "Quantity must be greater than or equal to 0."),
  expirationDate: z.string().min(1, "Expiration date is required.")
});

export const productionLotSchema = z.object({
  controlCode: z.string().min(1, "Control code is required.").max(50),
  producedByUserId: z.any(),
  statusId: z.number().min(1, "Status is required."),
  unitId: z.any(),
  quantity: z.number().min(0, "Quantity must be greater than or equal to 0."),
  expirationDate: z.string().min(1, "Expiration date is required."),
  ingredientControlCodeIds: z.array(z.number())
});
