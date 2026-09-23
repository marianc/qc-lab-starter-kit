import React, { useEffect, useState } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { Dialog, DialogHeader, DialogContent, DialogFooter } from '@/components/common/ui';
import type { ReagentLotDto, ReagentLotStatusDto, ReagentSupplierDto } from '@/types/reagent';
import type { UnitDto } from '@/types/unit';
import unitsService from '@/services/unitsService';
import reagentsService from '@/services/reagentsService';
import apiClient from '@/services/apiClient';
import { supplierLotSchema } from '@/lib/schemas/reagent';
import styles from './SupplierLotDialog.module.css';

interface SupplierLotDialogProps {
  open: boolean;
  reagentId: number;
  lot?: ReagentLotDto | null;
  onClose: (saved?: boolean) => void;
}

type SupplierLotFormValues = {
  controlCode: string;
  catalogNumber?: string | null;
  supplierId: any;
  supplierName?: string | null;
  manufacturerLotNumber: string;
  certificateOfAnalysisRef?: string | null;
  comments?: string | null;
  statusId: number;
  quantity: number;
  unitId: any;
  expirationDate: string;
};

const SupplierLotDialog: React.FC<SupplierLotDialogProps> = ({ open, reagentId, lot, onClose }) => {
  const [units, setUnits] = useState<UnitDto[]>([]);
  const [statuses, setStatuses] = useState<ReagentLotStatusDto[]>([]);
  const [suppliers, setSuppliers] = useState<ReagentSupplierDto[]>([]);
  const isEdit = !!lot;

  const {
    register,
    handleSubmit,
    reset,
    watch,
    setValue,
    setError,
    clearErrors,
    formState: { errors }
  } = useForm<SupplierLotFormValues>({
    resolver: zodResolver(supplierLotSchema) as any,
    defaultValues: {
      controlCode: '',
      catalogNumber: '',
      supplierId: '',
      supplierName: '',
      manufacturerLotNumber: '',
      certificateOfAnalysisRef: '',
      comments: '',
      statusId: 1,
      quantity: 0,
      unitId: null,
      expirationDate: ''
    }
  });

  const watchSupplierId = watch('supplierId');

  useEffect(() => {
    if (open) {
      Promise.all([
        unitsService.getAllUnits(),
        reagentsService.getReagentLotStatuses(),
        reagentsService.getSuppliers()
      ]).then(([unitsData, statusesData, suppliersData]) => {
        setUnits(unitsData);
        setStatuses(statusesData);
        setSuppliers(suppliersData);

        if (lot) {
          reset({
            controlCode: lot.controlCode,
            catalogNumber: lot.catalogNumber || '',
            supplierId: lot.supplierId !== undefined && lot.supplierId !== null ? String(lot.supplierId) : '',
            supplierName: '',
            manufacturerLotNumber: lot.manufacturerLotNumber || '',
            certificateOfAnalysisRef: lot.certificateOfAnalysisRef || '',
            comments: lot.comments || '',
            statusId: lot.statusId,
            quantity: lot.quantity,
            unitId: lot.unitId || null,
            expirationDate: lot.expirationDate
          });
        } else {
          reset({
            controlCode: '',
            catalogNumber: '',
            supplierId: '',
            supplierName: '',
            manufacturerLotNumber: '',
            certificateOfAnalysisRef: '',
            comments: '',
            statusId: 1,
            quantity: 0,
            unitId: null,
            expirationDate: ''
          });
        }
      });
    }
  }, [open, lot, reset]);

  const validateSupplierUniqueness = async (name: string): Promise<boolean> => {
    if (!name.trim()) return true;
    try {
      return await reagentsService.validateSupplierUniqueness(name.trim());
    } catch (err) {
      console.error('Supplier uniqueness check failed:', err);
      return true;
    }
  };

  const handleSupplierNameBlur = async (e: React.FocusEvent<HTMLInputElement>) => {
    const val = e.target.value;
    if (val && val.trim()) {
      const isUnique = await validateSupplierUniqueness(val);
      if (!isUnique) {
        setError('supplierName', { message: 'This supplier already exists.' });
      } else {
        clearErrors('supplierName');
        setValue('supplierName', val);
      }
    } else {
      clearErrors('supplierName');
    }
  };

  const onSupplierInputFocus = () => {
    setValue('supplierId', '');
    clearErrors('supplierId');
  };

  const onSupplierSelectChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
    const val = e.target.value ? e.target.value : '';
    setValue('supplierId', val);
    if (val) {
      setValue('supplierName', '');
      clearErrors('supplierName');
      clearErrors('supplierId');
    }
  };

  const onSubmit = async (values: SupplierLotFormValues) => {
    try {
      if (values.supplierName?.trim()) {
        const isUnique = await validateSupplierUniqueness(values.supplierName.trim());
        if (!isUnique) {
          setError('supplierName', { message: 'This supplier already exists.' });
          return;
        }
      }

      let finalSupplierId = values.supplierId ? Number(values.supplierId) : null;
      if (values.supplierName?.trim()) {
        const res = await reagentsService.createSupplier({ name: values.supplierName.trim() });
        finalSupplierId = res.id;
      }

      const parsedUnitId = values.unitId ? Number(values.unitId) : null;
      const parsedStatusId = Number(values.statusId);
      const parsedQuantity = Number(values.quantity);

      if (isEdit && lot) {
        await reagentsService.updateSupplierLot(lot.controlCodeId, {
          statusId: parsedStatusId,
          quantity: parsedQuantity,
          unitId: parsedUnitId,
          expirationDate: values.expirationDate,
          supplierId: finalSupplierId!,
          catalogNumber: values.catalogNumber || null,
          manufacturerLotNumber: values.manufacturerLotNumber,
          certificateOfAnalysisRef: values.certificateOfAnalysisRef || null,
          comments: values.comments || null
        });
      } else {
        await reagentsService.createSupplierLot({
          materialId: reagentId,
          controlCode: values.controlCode,
          statusId: parsedStatusId,
          quantity: parsedQuantity,
          unitId: parsedUnitId,
          expirationDate: values.expirationDate,
          supplierId: finalSupplierId!,
          catalogNumber: values.catalogNumber || null,
          manufacturerLotNumber: values.manufacturerLotNumber,
          certificateOfAnalysisRef: values.certificateOfAnalysisRef || null,
          comments: values.comments || null
        });
      }
      onClose(true);
    } catch (err: any) {
      console.error('Failed to save supplier lot', err);
      if (err.response?.data?.msg) {
        setError('root', { message: err.response.data.msg });
      } else if (err.message) {
        setError('root', { message: err.message });
      }
    }
  };

  return (
    <Dialog open={open} onClose={() => onClose(false)}>
      <DialogHeader>
        {isEdit ? `Edit Supplier Lot (${lot?.controlCode})` : "Add New Supplier Lot"}
      </DialogHeader>
      <form onSubmit={handleSubmit(onSubmit)}>
        <DialogContent>
          {errors.root && <div className="text-danger mb-3">{errors.root.message}</div>}

          <div className="form-group">
            <label>Control Code (Internal Identifier)</label>
            <input 
              {...register('controlCode')} 
              className="form-control"
              disabled={isEdit}
              placeholder="e.g. LOT-REG-001"
            />
            {errors.controlCode && <span className="text-danger">{errors.controlCode.message}</span>}
          </div>

          <div className="form-group">
            <label>Supplier</label>
            <div className={styles.supplierSelectionRow}>
              <input 
                type="text"
                placeholder="Enter new supplier"
                className={`form-control ${styles.flex1} ${isEdit ? styles.dNone : ''} ${errors.supplierName ? 'is-invalid' : ''}`}
                {...register('supplierName')}
                onFocus={onSupplierInputFocus}
                onBlur={handleSupplierNameBlur}
                disabled={isEdit}
              />
              <select 
                className={`form-control ${styles.flex1} ${errors.supplierId ? 'is-invalid' : ''}`}
                value={watchSupplierId || ''}
                onChange={onSupplierSelectChange}
                disabled={isEdit}
              >
                <option value="">-- {isEdit ? 'Select Supplier' : 'Or Select Supplier'} --</option>
                {suppliers.map(s => (
                  <option key={s.id} value={s.id}>{s.name}</option>
                ))}
              </select>
            </div>
            {errors.supplierId && <span className="text-danger d-block mt-1">{errors.supplierId.message as string}</span>}
            {errors.supplierName && <span className="text-danger d-block mt-1">{errors.supplierName.message as string}</span>}
          </div>

          <div className="form-group">
            <label>Manufacturer Lot Number</label>
            <input 
              {...register('manufacturerLotNumber')} 
              className="form-control"
              placeholder="e.g. MFR-2026-X1"
            />
            {errors.manufacturerLotNumber && <span className="text-danger">{errors.manufacturerLotNumber.message}</span>}
          </div>

          <div className="form-group">
            <label>Catalog Number</label>
            <input 
              {...register('catalogNumber')} 
              className="form-control"
              placeholder="e.g. 320331"
            />
            {errors.catalogNumber && <span className="text-danger">{errors.catalogNumber.message}</span>}
          </div>

          <div className="form-group">
            <label>Certificate of Analysis (CoA) Reference</label>
            <input 
              {...register('certificateOfAnalysisRef')} 
              className="form-control"
              placeholder="e.g. CoA-2026-0909"
            />
            {errors.certificateOfAnalysisRef && <span className="text-danger">{errors.certificateOfAnalysisRef.message}</span>}
          </div>

          <div className="form-group">
            <label>Status</label>
            <select {...register('statusId', { valueAsNumber: true })} className="form-control">
              {statuses.map(st => (
                <option key={st.id} value={st.id}>{st.name}</option>
              ))}
            </select>
            {errors.statusId && <span className="text-danger">{errors.statusId.message}</span>}
          </div>

          <div className="form-group">
            <label>Quantity</label>
            <input 
              type="number"
              step="any"
              {...register('quantity', { valueAsNumber: true })} 
              className="form-control"
            />
            {errors.quantity && <span className="text-danger">{errors.quantity.message}</span>}
          </div>

          <div className="form-group">
            <label>Unit of Measurement</label>
            <select {...register('unitId')} className="form-control">
              <option value="">-- Select Unit --</option>
              {units.map(u => (
                <option key={u.id} value={u.id}>{u.name}</option>
              ))}
            </select>
            {errors.unitId && <span className="text-danger">{errors.unitId.message as string}</span>}
          </div>

          <div className="form-group">
            <label>Expiration Date</label>
            <input 
              type="date"
              {...register('expirationDate')} 
              className="form-control"
            />
            {errors.expirationDate && <span className="text-danger">{errors.expirationDate.message}</span>}
          </div>

          <div className="form-group">
            <label>Comments</label>
            <textarea 
              {...register('comments')} 
              className="form-control"
              rows={3}
              placeholder="e.g. Additional notes"
            />
            {errors.comments && <span className="text-danger">{errors.comments.message}</span>}
          </div>
        </DialogContent>
        <DialogFooter>
          <button type="submit" className="action-button primary">Save</button>
          <button type="button" className="action-button secondary" onClick={() => onClose(false)}>Cancel</button>
        </DialogFooter>
      </form>
    </Dialog>
  );
};

export default SupplierLotDialog;
