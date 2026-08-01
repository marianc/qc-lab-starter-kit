import React, { useEffect, useState } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import * as z from 'zod';
import { Dialog, DialogHeader, DialogContent, DialogFooter } from '../common/ui';
import styles from './CategoryDialog.module.css';
import categoriesService from '@/services/categoriesService';
import { categorySchema } from '@/lib/schemas/category';

interface CategoryDialogProps {
  open: boolean;
  categoryId?: number | null;
  onClose: (savedId?: number | null) => void;
}

type CategoryFormValues = z.infer<typeof categorySchema>;

const CategoryDialog: React.FC<CategoryDialogProps> = ({ open, categoryId, onClose }) => {
  const [isValidating, setIsValidating] = useState(false);
  const {
    register,
    handleSubmit,
    reset,
    setError,
    clearErrors,
    getValues,
    formState: { errors }
  } = useForm<CategoryFormValues>({
    resolver: zodResolver(categorySchema),
    defaultValues: {
      id: 0,
      name: '',
      code: '',
      description: ''
    }
  });

  useEffect(() => {
    if (open) {
      if (categoryId) {
        categoriesService.getCategory(categoryId).then(data => {
          reset({
            id: data.id,
            name: data.name,
            code: data.code,
            description: data.description || ''
          });
        });
      } else {
        reset({
          id: 0,
          name: '',
          code: '',
          description: ''
        });
      }
    }
  }, [open, categoryId, reset]);

  const validateUniqueness = async (property: "Name" | "Code"): Promise<boolean> => {
    const value = getValues(property.toLowerCase() as any);
    if (!value) return true;

    setIsValidating(true);
    try {
      const isUnique = await categoriesService.validateUniqueness(property, value, getValues('id'));
      const field = property.toLowerCase() as any;
      if (!isUnique) {
        setError(field, {
          type: 'manual',
          message: `${property} is already in use.`
        });
        return false;
      } else {
        clearErrors(field);
        return true;
      }
    } catch (err) {
      console.error(`Uniqueness check failed:`, err);
      return false;
    } finally {
      setIsValidating(false);
    }
  };

  const onSubmit = async (values: CategoryFormValues) => {
    const isNameUnique = await validateUniqueness('Name');
    const isCodeUnique = await validateUniqueness('Code');

    if (isNameUnique && isCodeUnique) {
      try {
        let savedId: number;
        if (values.id > 0) {
          await categoriesService.updateCategory(values.id, {
            name: values.name,
            code: values.code,
            description: values.description
          });
          savedId = values.id;
        } else {
          const result = await categoriesService.createCategory({
            name: values.name,
            code: values.code,
            description: values.description
          });
          savedId = result.id;
        }
        onClose(savedId);
      } catch (err) {
        console.error('Failed to save category', err);
      }
    }
  };

  const nameRegister = register('name');
  const codeRegister = register('code');

  return (
    <Dialog open={open} onClose={() => onClose()}>
      <DialogHeader>
        {categoryId ? "Edit Category" : "New Category"}
      </DialogHeader>
      <form onSubmit={handleSubmit(onSubmit)} className={styles.categoryEditForm}>
        <DialogContent>
          <div className="form-group">
            <label>Name</label>
            <input 
              {...nameRegister} 
              className="form-control" 
              onBlur={(e) => {
                nameRegister.onBlur(e);
                validateUniqueness('Name');
              }}
            />
            {errors.name && <span className="text-danger">{errors.name.message}</span>}
          </div>

          <div className="form-group">
            <label>Code</label>
            <input 
              {...codeRegister} 
              className="form-control" 
              onBlur={(e) => {
                codeRegister.onBlur(e);
                validateUniqueness('Code');
              }}
            />
            {errors.code && <span className="text-danger">{errors.code.message}</span>}
          </div>

          <div className="form-group">
            <label>Description</label>
            <textarea 
              {...register('description')} 
              className="form-control" 
              rows={3}
            />
            {errors.description && <span className="text-danger">{errors.description.message}</span>}
          </div>
        </DialogContent>
        <DialogFooter>
          <button type="submit" className="action-button primary" disabled={isValidating}>Save</button>
          <button type="button" className="action-button secondary" onClick={() => onClose()}>Cancel</button>
        </DialogFooter>
      </form>
    </Dialog>
  );
};

export default CategoryDialog;
