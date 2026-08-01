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
import type { SpecDto } from '@/types/specification';
import type { MaterialDto } from '@/types/material';
import materialsService from '@/services/materialsService';
import { specSchema } from '@/lib/schemas/specification';

type FormData = z.infer<typeof specSchema>;

interface Props {
  open: boolean;
  specData?: SpecDto | null;
  onSave: (data: SpecDto) => void;
  onClose: () => void;
}

const SpecificationDialog: React.FC<Props> = ({ open, specData, onSave, onClose }) => {
  const [materials, setMaterials] = useState<MaterialDto[]>([]);
  const { register, handleSubmit, reset, formState: { errors } } = useForm<FormData>({
    resolver: zodResolver(specSchema),
    defaultValues: {
      materialId: specData?.materialId || 0
    }
  });

  useEffect(() => {
    if (open) {
      materialsService.getAllMaterials().then(setMaterials);
      reset({
        materialId: specData?.materialId || 0
      });
    }
  }, [open, specData, reset]);

  const onSubmit = (data: FormData) => {
    const result: SpecDto = {
      id: specData?.id || 0,
      materialId: data.materialId,
      materialName: materials.find(m => m.id === data.materialId)?.name || '',
      isSubmitted: specData?.isSubmitted || false,
      specReplacedId: specData?.specReplacedId || null,
      status: specData?.status || 'Draft',
      normName: specData?.normName || null,
      dateSubmitted: specData?.dateSubmitted || null,
      dateCancelled: specData?.dateCancelled || null,
      userSubmittedTag: specData?.userSubmittedTag || null,
      userCancelledTag: specData?.userCancelledTag || null,
      commentsSubmitted: specData?.commentsSubmitted || null,
      commentsCancelled: specData?.commentsCancelled || null,
      applicableTests: specData?.applicableTests || null,
      certifiedTests: specData?.certifiedTests || null,
      tests: specData?.tests || []
    };
    onSave(result);
  };

  if (!open) return null;

  return (
    <Dialog open={open} onClose={onClose}>
      <DialogHeader>
        {specData && specData.id > 0 ? 'Edit Specification' : 'Add New Specification'}
      </DialogHeader>
      <DialogContent>
        <form id="spec-form" onSubmit={handleSubmit(onSubmit)}>
          <div className="form-group">
            <label htmlFor="material">Material</label>
            <select 
              id="material" 
              className={`form-control ${errors.materialId ? 'invalid' : ''}`}
              {...register('materialId', { valueAsNumber: true })}
            >
              <option value="0">-- Select Material --</option>
              {materials.map(m => (
                <option key={m.id} value={m.id}>{m.name}</option>
              ))}
            </select>
            {errors.materialId && <div className="validation-message">{errors.materialId.message}</div>}
          </div>
        </form>
      </DialogContent>
      <DialogFooter>
        <button type="submit" form="spec-form" className="action-button primary">Save</button>
        <button type="button" onClick={onClose} className="action-button secondary">Cancel</button>
      </DialogFooter>
    </Dialog>
  );
};

export default SpecificationDialog;
