import React, { useEffect, useState } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import * as z from 'zod';
import { 
  Dialog, 
  DialogHeader, 
  DialogContent, 
  DialogFooter 
} from '../common/ui';
import type { MaterialControlCodeDto, MaterialDto } from '@/types/material';
import materialsService from '@/services/materialsService';
import authService from '@/services/authService';
import certificatesService from '@/services/certificatesService';
import { certificateSchema } from '@/lib/schemas/certificate';

type FormData = z.infer<typeof certificateSchema>;

interface Props {
  open: boolean;
  onClose: () => void;
  onCreated: (id: number) => void;
}

const CertificateDialog: React.FC<Props> = ({ open, onClose, onCreated }) => {
  const [materials, setMaterials] = useState<MaterialDto[]>([]);
  const [controlCodes, setControlCodes] = useState<MaterialControlCodeDto[]>([]);
  const [loadingMaterials, setLoadingMaterials] = useState(false);
  const [loadingControlCodes, setLoadingControlCodes] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);

  const { register, handleSubmit, watch, setValue, reset, formState: { errors } } = useForm<FormData>({
    resolver: zodResolver(certificateSchema),
    defaultValues: {
      materialId: 0,
      controlCodeId: 0
    }
  });

  const watchedMaterialId = watch('materialId');

  useEffect(() => {
    if (open) {
      fetchMaterials();
      reset({ materialId: 0, controlCodeId: 0 });
      setControlCodes([]);
    }
  }, [open, reset]);

  useEffect(() => {
    if (watchedMaterialId > 0) {
      fetchControlCodes(watchedMaterialId);
    } else {
      setControlCodes([]);
      setValue('controlCodeId', 0);
    }
  }, [watchedMaterialId, setValue]);

  const fetchMaterials = async () => {
    setLoadingMaterials(true);
    try {
      const data = await materialsService.getMaterialsWithValidSpec();
      setMaterials(data);
    } catch (err) {
      console.error('Error fetching materials:', err);
    } finally {
      setLoadingMaterials(false);
    }
  };

  const fetchControlCodes = async (matId: number) => {
    setLoadingControlCodes(true);
    try {
      const data = await materialsService.getControlCodesForCertificate(matId);
      setControlCodes(data);
      setValue('controlCodeId', 0);
    } catch (err) {
      console.error('Error fetching control codes:', err);
    } finally {
      setLoadingControlCodes(false);
    }
  };

  const onSubmit = async (data: FormData) => {
    setIsSubmitting(true);
    try {
      const user = await authService.me();
      if (!user) return;

      const res = await certificatesService.generateCertificate({
        materialId: data.materialId,
        controlCodeId: data.controlCodeId,
        userId: user.id
      });
      onCreated(res.id);
    } catch (err) {
      console.error('Error creating certificate:', err);
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <Dialog open={open} onClose={onClose}>
      <DialogHeader>
        <h2>Add New Certificate</h2>
      </DialogHeader>
      <DialogContent>
        <form id="certificate-form" onSubmit={handleSubmit(onSubmit)}>
          <div className="form-group">
            <label htmlFor="material">Material:</label>
            <select 
              id="material"
              className={`form-control ${errors.materialId ? 'invalid' : ''}`}
              {...register('materialId', { valueAsNumber: true })}
              disabled={loadingMaterials}
            >
              <option value="0">Select Material...</option>
              {materials.map(m => (
                <option key={m.id} value={m.id}>{m.name}</option>
              ))}
            </select>
            {errors.materialId && <div className="validation-message">{errors.materialId.message}</div>}
          </div>
          <div className="form-group">
            <label htmlFor="controlCode">Control Code:</label>
            <select 
              id="controlCode"
              className={`form-control ${errors.controlCodeId ? 'invalid' : ''}`}
              {...register('controlCodeId', { valueAsNumber: true })}
              disabled={watchedMaterialId === 0 || loadingControlCodes}
            >
              <option value="0">Select Control Code...</option>
              {controlCodes.map(cc => (
                <option key={cc.id} value={cc.id}>{cc.code}</option>
              ))}
            </select>
            {errors.controlCodeId && <div className="validation-message">{errors.controlCodeId.message}</div>}
          </div>
        </form>
      </DialogContent>
      <DialogFooter>
        <button 
          type="submit" 
          form="certificate-form" 
          className="action-button primary"
          disabled={isSubmitting}
        >
          Create
        </button>
        <button type="button" onClick={onClose} className="action-button secondary">Cancel</button>
      </DialogFooter>
    </Dialog>
  );
};

export default CertificateDialog;
