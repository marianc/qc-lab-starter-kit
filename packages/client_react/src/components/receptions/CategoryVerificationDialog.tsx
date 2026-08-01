import React, { useEffect, useState } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import * as z from 'zod';
import { useAuthStore } from '@/store/authStore';
import { 
  Dialog, 
  DialogHeader, 
  DialogContent, 
  DialogFooter 
} from '@/components/common/ui';
import styles from './CategoryVerificationDialog.module.css';
import type { ReceptionDto } from '@/types/reception';
import type { CategoryDto } from '@/types/category';
import type { TestDto } from '@/types/test';
import categoriesService from '@/services/categoriesService';
import receptionsService from '@/services/receptionsService';
import { categoryVerificationSchema } from '@/lib/schemas/reception';

interface Props {
  open: boolean;
  onClose: () => void;
  onSave: (id: number) => void;
  reception?: ReceptionDto | null;
  initialTypeId?: number;
}

type FormData = z.infer<typeof categoryVerificationSchema>;

const CategoryVerificationDialog: React.FC<Props> = ({ 
  open, 
  onClose, 
  onSave, 
  reception, 
  initialTypeId = 3 
}) => {
  const { user } = useAuthStore();
  const [categories, setCategories] = useState<CategoryDto[]>([]);
  const [categoryTests, setCategoryTests] = useState<TestDto[]>([]);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [serverError, setServerError] = useState<string | null>(null);

  const { register, handleSubmit, watch, setValue, reset, formState: { errors, isValidating } } = useForm<FormData>({
    resolver: zodResolver(categoryVerificationSchema) as any,
    defaultValues: {
      materialName: '',
      categoryId: 0,
      comments: '',
      testIds: []
    }
  });

  const watchCategoryId = watch('categoryId');
  const watchTestIds = watch('testIds');

  useEffect(() => {
    if (open) {
      setServerError(null);
      loadInitialData();
    }
  }, [open, reception]);

  useEffect(() => {
    if (watchCategoryId > 0) {
      loadCategoryTests(watchCategoryId);
    } else {
      setCategoryTests([]);
    }
  }, [watchCategoryId]);

  const loadInitialData = async () => {
    if (!user) return;
    try {
      const cats = await categoriesService.getAllCategories();
      setCategories(cats);

      if (reception) {
        const currentTests = await receptionsService.getReceptionTests(reception.id);
        reset({
          materialName: reception.materialName || '',
          categoryId: reception.categoryId || 0,
          comments: reception.commentsSubmitted || '',
          testIds: currentTests.map(t => t.id)
        });
      } else {
        reset({
          materialName: '',
          categoryId: 0,
          comments: '',
          testIds: []
        });
      }
    } catch (err) {
      console.error('Failed to load initial data:', err);
    }
  };

  const loadCategoryTests = async (cid: number) => {
    try {
      const tests = await categoriesService.getCategoryTests(cid);
      setCategoryTests(tests as any);
    } catch (err) {
      console.error('Failed to load category tests:', err);
    }
  };

  const onTestCheck = (tid: number, checked: boolean) => {
    const current = [...watchTestIds];
    if (checked) {
      if (!current.includes(tid)) current.push(tid);
    } else {
      const idx = current.indexOf(tid);
      if (idx > -1) current.splice(idx, 1);
    }
    setValue('testIds', current);
  };

  const onSubmit = async (data: FormData) => {
    if (!user) return;
    setServerError(null);
    setIsSubmitting(true);

    try {
      let finalId: number;
      if (reception) {
        await receptionsService.updateReception(reception.id, {
          typeId: reception.typeId,
          categoryId: data.categoryId,
          materialName: data.materialName,
          controlCodeId: null,
          commentsSubmitted: data.comments || null,
          userId: user.id
        });
        finalId = reception.id;

        if (!reception.isSubmitted) {
          await submitAndAutoReceive(finalId, data.comments || '');
        }
      } else {
        const res = await receptionsService.createReception({
          typeId: initialTypeId,
          categoryId: data.categoryId,
          materialName: data.materialName,
          controlCodeId: null,
          commentsSubmitted: data.comments || null,
          userId: user.id
        });
        finalId = res.id;
        await submitAndAutoReceive(finalId, data.comments || '');
      }

      await receptionsService.updateReceptionTests(finalId, { testIds: data.testIds });
      onSave(finalId);
      onClose();
    } catch (err: any) {
      setServerError(err.response?.data?.message || err.message || 'An error occurred while saving.');
    } finally {
      setIsSubmitting(false);
    }
  };

  const submitAndAutoReceive = async (receptionId: number, comments: string) => {
    if (!user) return;
    await receptionsService.submitReception(receptionId, { 
      userId: user.id, 
      comments 
    });

    if (user.roles.includes('LabPers')) {
      await receptionsService.receiveReception(receptionId, {
        userId: user.id,
        comments: 'Automatically received'
      });
    }
  };

  return (
    <Dialog open={open} onClose={onClose}>
      <DialogHeader>
        {reception ? 'Edit' : 'Add New'} Category Verification Reception
      </DialogHeader>
      <DialogContent>
        <form id="category-verification-form" onSubmit={handleSubmit(onSubmit)}>
          {serverError && <div className="error-message">{serverError}</div>}
          
          <div className="form-group">
            <label htmlFor="cv-materialName">Material Name:</label>
            <input 
              id="cv-materialName"
              type="text"
              className={`form-control ${errors.materialName ? 'invalid' : ''}`}
              {...register('materialName')}
            />
            {errors.materialName && <div className="validation-message">{errors.materialName.message}</div>}
          </div>

          <div className="form-group">
            <label htmlFor="cv-category">Category:</label>
            <select 
              id="cv-category"
              className={`form-control ${errors.categoryId ? 'invalid' : ''}`}
              {...register('categoryId')}
            >
              <option value="">-- Select Category --</option>
              {categories.map(cat => (
                <option key={cat.id} value={cat.id}>{cat.name}</option>
              ))}
            </select>
            {errors.categoryId && <div className="validation-message">{errors.categoryId.message}</div>}
          </div>

          <div className="form-group">
            <label>Associated Tests:</label>
            {categoryTests.length > 0 ? (
              <div className={`${styles.checkboxListContainer} ${errors.testIds ? 'invalid-border' : ''}`}>
                {categoryTests.map(t => (
                  <div key={t.id} className={styles.checkboxItem}>
                    <input 
                      type="checkbox"
                      id={`cv-test-${t.id}`}
                      className={styles.checkboxInput}
                      checked={watchTestIds.includes(t.id)}
                      onChange={(e) => onTestCheck(t.id, e.target.checked)}
                    />
                    <label htmlFor={`cv-test-${t.id}`} className={styles.checkboxLabel}>{t.name}</label>
                  </div>
                ))}
              </div>
            ) : (
              <p>No tests available for the selected category.</p>
            )}
            {errors.testIds && <div className="validation-message">{errors.testIds.message}</div>}
          </div>

          <div className="form-group">
            <label htmlFor="cv-comments">Submit Comments:</label>
            <textarea 
              id="cv-comments"
              className="form-control"
              rows={3}
              {...register('comments')}
            />
          </div>
        </form>
      </DialogContent>
      <DialogFooter>
        <button 
          type="submit" 
          form="category-verification-form" 
          className="action-button primary" 
          disabled={isSubmitting || isValidating}
        >
          Save & Submit
        </button>
        <button type="button" onClick={onClose} className="action-button secondary">
          Cancel
        </button>
      </DialogFooter>
    </Dialog>
  );
};

export default CategoryVerificationDialog;
