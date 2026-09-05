import { z } from 'zod';

export const sopCreateSchema = z.object({
  docCode: z.string()
    .min(1, 'Doc code is required.')
    .max(50, 'Doc code cannot exceed 50 characters.'),
  title: z.string()
    .min(1, 'Title is required.')
    .max(150, 'Title cannot exceed 150 characters.'),
  normId: z.number().nullable().optional(),
  versionNumber: z.string()
    .min(1, 'Version number is required.')
    .max(20, 'Version number cannot exceed 20 characters.'),
  externalEdmsId: z.string().max(100, 'External EDMS ID cannot exceed 100 characters.').optional().nullable(),
  comments: z.string().optional().nullable()
});

export const sopVersionUpdateSchema = z.object({
  versionNumber: z.string()
    .min(1, 'Version number is required.')
    .max(20, 'Version number cannot exceed 20 characters.'),
  externalEdmsId: z.string().max(100, 'External EDMS ID cannot exceed 100 characters.').optional().nullable(),
  comments: z.string().optional().nullable()
});
