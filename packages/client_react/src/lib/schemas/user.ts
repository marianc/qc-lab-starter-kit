import { z } from 'zod';

export const userSchema = z.object({
  id: z.number(),
  tag: z.string().min(3).max(12).regex(/^[a-z][a-z0-9_]*[a-z0-9]$/, "Tag must start with a letter, end with an alphanumeric character, contain only lowercase alphanumeric characters or underscores."),
  code: z.string().min(2).max(3).regex(/^[A-Z][A-Z0-9]*$/, "Code must start with a letter and contain only uppercase alphanumeric characters."),
  email: z.string().email("Invalid email address."),
  firstName: z.string().optional().nullable(),
  lastName: z.string().optional().nullable(),
  isAdmin: z.boolean(),
  isLabPers: z.boolean(),
  isQcPers: z.boolean(),
  mustChangePassword: z.boolean(),
  password: z.string().optional().nullable(),
  confirmPassword: z.string().optional().nullable(),
}).refine((data) => {
  if (data.id === 0) {
    return data.password && data.password.length >= 8;
  }
  return true;
}, {
  message: "Password is required and must be at least 8 characters for new users.",
  path: ["password"],
}).refine((data) => {
  if (data.id === 0) {
    return data.password === data.confirmPassword;
  }
  return true;
}, {
  message: "Passwords do not match.",
  path: ["confirmPassword"],
});
