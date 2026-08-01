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
import styles from './CertificationDialog.module.css';
import type { ReceptionDto } from '@/types/reception';
import type { MaterialDto } from '@/types/material';
import type { ControlCodeSelectionDto } from '@/types/controlCode';
import materialsService from '@/services/materialsService';
import controlCodesService from '@/services/controlCodesService';
import apiClient from '@/services/apiClient';
import receptionsService from '@/services/receptionsService';
import { certificationSchema } from '@/lib/schemas/reception';

interface Props {
  open: boolean;
  onClose: () => void;
  onSave: (id: number) => void;
  reception?: ReceptionDto | null;
  initialTypeId?: number;
}

type FormData = z.infer<typeof certificationSchema>;

const CertificationDialog: React.FC<Props> = ({ 
  open, 
  onClose, 
  onSave, 
  reception, 
  initialTypeId = 1 
}) => {
  const { user } = useAuthStore();
  const [materials, setMaterials] = useState<MaterialDto[]>([]);
  const [filteredCCs, setFilteredCCs] = useState<ControlCodeSelectionDto[]>([]);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [serverError, setServerError] = useState<string | null>(null);

  const { register, handleSubmit, watch, setValue, reset, formState: { errors, isValidating } } = useForm<FormData>({
    resolver: zodResolver(certificationSchema) as any,
    defaultValues: {
      materialId: 0,
      controlCodeId: null,
      controlCodeName: '',
      comments: ''
    }
  });

  const watchMaterialId = watch('materialId');
  const watchControlCodeId = watch('controlCodeId');

  useEffect(() => {
    if (open) {
      setServerError(null);
      loadInitialData();
    }
  }, [open, reception]);

  useEffect(() => {
    if (watchMaterialId > 0) {
      loadFilteredCCs(watchMaterialId);
    } else {
      setFilteredCCs([]);
    }
  }, [watchMaterialId]);

  const loadInitialData = async () => {
    if (!user) return;
    try {
      const mats = await materialsService.getMaterialsWithValidSpec();
      setMaterials(mats);

      if (reception) {
        let materialId = 0;
        if (reception.controlCodeId) {
          const allCCs = await controlCodesService.getAllControlCodes();
          const found = allCCs.find(c => c.id === reception.controlCodeId);
          if (found) materialId = found.materialId;
        }

        reset({
          materialId: materialId,
          controlCodeId: reception.controlCodeId,
          controlCodeName: '',
          comments: reception.commentsSubmitted || ''
        });
      } else {
        reset({
          materialId: 0,
          controlCodeId: null,
          controlCodeName: '',
          comments: ''
        });
      }
    } catch (err) {
      console.error('Failed to load initial data:', err);
    }
  };

  const loadFilteredCCs = async (mid: number) => {
    try {
      const ccs = await controlCodesService.getControlCodesByMaterial(mid);
      setFilteredCCs(ccs);
    } catch (err) {
      console.error('Failed to load filtered CCs:', err);
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
        {reception ? 'Edit' : 'Add New'} Certification Reception
      </DialogHeader>
      <DialogContent>
        <form id="certification-form" onSubmit={handleSubmit(onSubmit)}>
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
              <input 
                type="text"
                placeholder="Enter new code"
                className={`form-control ${styles.flex1} ${errors.controlCodeName ? 'invalid' : ''}`}
                {...register('controlCodeName')}
                onFocus={onCCInputFocus}
              />
              <select 
                className={`form-control ${styles.flex1} ${errors.controlCodeId ? 'invalid' : ''}`}
                value={watchControlCodeId || ''}
                onChange={onCCSelectChange}
              >
                <option value="">-- Or Select Code --</option>
                {filteredCCs.map(c => (
                  <option key={c.id} value={c.id}>{c.code}</option>
                ))}
              </select>
            </div>
            {errors.controlCodeId && <div className="validation-message">{errors.controlCodeId.message}</div>}
            {errors.controlCodeName && <div className="validation-message">{errors.controlCodeName.message}</div>}
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
          form="certification-form" 
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

export default CertificationDialog;
