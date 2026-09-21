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
import styles from './VerificationDialog.module.css';
import type { ReceptionDto } from '@/types/reception';
import type { MaterialDto, MaterialTestDto } from '@/types/material';
import type { ControlCodeSelectionDto } from '@/types/controlCode';
import materialsService from '@/services/materialsService';
import controlCodesService from '@/services/controlCodesService';
import receptionsService from '@/services/receptionsService';
import apiClient from '@/services/apiClient';
import { verificationSchema } from '@/lib/schemas/reception';

interface Props {
  open: boolean;
  onClose: () => void;
  onSave: (id: number) => void;
  reception?: ReceptionDto | null;
  initialTypeId?: number;
}

type FormData = z.infer<typeof verificationSchema>;

const VerificationDialog: React.FC<Props> = ({ 
  open, 
  onClose, 
  onSave, 
  reception, 
  initialTypeId = 2 
}) => {
  const { user } = useAuthStore();
  const [materials, setMaterials] = useState<MaterialDto[]>([]);
  const [filteredCCs, setFilteredCCs] = useState<ControlCodeSelectionDto[]>([]);
  const [materialTests, setMaterialTests] = useState<MaterialTestDto[]>([]);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [serverError, setServerError] = useState<string | null>(null);

  const { register, handleSubmit, watch, setValue, reset, formState: { errors, isValidating } } = useForm<FormData>({
    resolver: zodResolver(verificationSchema) as any,
    defaultValues: {
      materialId: 0,
      controlCodeId: null,
      controlCodeName: '',
      comments: '',
      testIds: []
    }
  });

  const watchMaterialId = watch('materialId');
  const watchControlCodeId = watch('controlCodeId');
  const watchTestIds = watch('testIds');

  const selectedMaterial = materials.find(m => m.id === Number(watchMaterialId));
  const isReagent = selectedMaterial?.isReagent ?? false;

  useEffect(() => {
    if (isReagent) {
      setValue('controlCodeName', '');
    }
  }, [isReagent, setValue]);

  useEffect(() => {
    if (open) {
      setServerError(null);
      loadInitialData();
    }
  }, [open, reception]);

  useEffect(() => {
    if (watchMaterialId > 0) {
      loadMaterialData(watchMaterialId);
    } else {
      setFilteredCCs([]);
      setMaterialTests([]);
    }
  }, [watchMaterialId]);

  const loadInitialData = async () => {
    if (!user) return;
    try {
      const mats = await materialsService.getAllMaterials();
      setMaterials(mats);

      if (reception) {
        let materialId = 0;
        if (reception.controlCodeId) {
          const allCCs = await controlCodesService.getAllControlCodes();
          const found = allCCs.find(c => c.id === reception.controlCodeId);
          if (found) materialId = found.materialId;
        }

        const currentTests = await receptionsService.getReceptionTests(reception.id);
        
        reset({
          materialId: materialId,
          controlCodeId: reception.controlCodeId,
          controlCodeName: '',
          comments: reception.commentsSubmitted || '',
          testIds: currentTests.map(t => t.id)
        });
      } else {
        reset({
          materialId: 0,
          controlCodeId: null,
          controlCodeName: '',
          comments: '',
          testIds: []
        });
      }
    } catch (err) {
      console.error('Failed to load initial data:', err);
    }
  };

  const loadMaterialData = async (mid: number) => {
    try {
      const ccs = await controlCodesService.getControlCodesByMaterial(mid);
      const tests = await materialsService.getMaterialTests(mid);
      setFilteredCCs(ccs);
      setMaterialTests(tests);
    } catch (err) {
      console.error('Failed to load material data:', err);
    }
  };

  const validateUniqueness = async (name: string, mid: number): Promise<boolean> => {
    if (!name.trim() || mid <= 0) return true;
    try {
      const response = await apiClient.get<{ is_unique: boolean }>(`api/validate/unique?entity=ControlCode&property=Code&value=${encodeURIComponent(name.trim())}&scope_id=${mid}`);
      return response.data.is_unique;
    } catch (err) {
      console.error('Uniqueness check failed:', err);
      return true;
    }
  };

  const onCCInputFocus = () => {
    setValue('controlCodeId', null);
  };

  const onCCSelectChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
    const val = e.target.value ? parseInt(e.target.value) : null;
    setValue('controlCodeId', val);
    if (val) {
      setValue('controlCodeName', '');
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
      if (data.controlCodeName) {
        const isUnique = await validateUniqueness(data.controlCodeName, data.materialId);
        if (!isUnique) {
          setServerError('This control code already exists for this material.');
          setIsSubmitting(false);
          return;
        }
      }

      let finalCCId = data.controlCodeId;
      if (data.controlCodeName?.trim()) {
        const res = await controlCodesService.createControlCode({
          materialId: data.materialId,
          code: data.controlCodeName.trim()
        });
        finalCCId = res.id;
      }

      let finalId: number;
      if (reception) {
        await receptionsService.updateReception(reception.id, {
          typeId: reception.typeId,
          controlCodeId: finalCCId || null,
          categoryId: null,
          materialName: null,
          userId: user.id,
          commentsSubmitted: data.comments || null
        });
        finalId = reception.id;

        if (!reception.isSubmitted) {
          await submitAndAutoReceive(finalId, data.comments || '');
        }
      } else {
        const res = await receptionsService.createReception({
          typeId: initialTypeId,
          controlCodeId: finalCCId || null,
          categoryId: null,
          materialName: null,
          userId: user.id,
          commentsSubmitted: data.comments || null
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
        {reception ? 'Edit' : 'Add New'} Verification Reception
      </DialogHeader>
      <DialogContent>
        <form id="verification-form" onSubmit={handleSubmit(onSubmit)}>
          {serverError && <div className="error-message">{serverError}</div>}
          
          <div className="form-group">
            <label htmlFor="materialId">Material:</label>
            <select 
              id="materialId"
              className={`form-control ${errors.materialId ? 'invalid' : ''}`}
              {...register('materialId')}
            >
              <option value="0">-- Select Material --</option>
              {materials.map(m => (
                <option key={m.id} value={m.id}>{m.name}</option>
              ))}
            </select>
            {errors.materialId && <div className="validation-message">{errors.materialId.message}</div>}
          </div>

          <div className="form-group">
            <label>Control Code:</label>
            <div className={styles.ccSelectionRow}>
              {!isReagent && (
                <input 
                  type="text"
                  placeholder="Enter new code"
                  className={`form-control ${styles.flex1} ${errors.controlCodeName ? 'invalid' : ''}`}
                  {...register('controlCodeName')}
                  onFocus={onCCInputFocus}
                />
              )}
              <select 
                className={`form-control ${styles.flex1} ${errors.controlCodeId ? 'invalid' : ''}`}
                value={watchControlCodeId || ''}
                onChange={onCCSelectChange}
              >
                <option value="">{isReagent ? '-- Select Existing Code --' : '-- Or Select Code --'}</option>
                {filteredCCs.map(c => (
                  <option key={c.id} value={c.id}>{c.code}</option>
                ))}
              </select>
            </div>
            {errors.controlCodeId && <div className="validation-message">{errors.controlCodeId.message}</div>}
            {!isReagent && errors.controlCodeName && <div className="validation-message">{errors.controlCodeName.message}</div>}
          </div>

          <div className="form-group">
            <label>Associated Tests:</label>
            {materialTests.length > 0 ? (
              <div className={`${styles.checkboxListContainer} ${errors.testIds ? 'invalid-border' : ''}`}>
                {materialTests.map(t => (
                  <div key={t.id} className={styles.checkboxItem}>
                    <input 
                      type="checkbox"
                      id={`test-${t.id}`}
                      className={styles.checkboxInput}
                      checked={watchTestIds.includes(t.id)}
                      onChange={(e) => onTestCheck(t.id, e.target.checked)}
                    />
                    <label htmlFor={`test-${t.id}`} className={styles.checkboxLabel}>{t.name}</label>
                  </div>
                ))}
              </div>
            ) : (
              <p>No tests available for the selected material.</p>
            )}
            {errors.testIds && <div className="validation-message">{errors.testIds.message}</div>}
          </div>

          <div className="form-group">
            <label htmlFor="comments">Submit Comments:</label>
            <textarea 
              id="comments"
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
          form="verification-form" 
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

export default VerificationDialog;
