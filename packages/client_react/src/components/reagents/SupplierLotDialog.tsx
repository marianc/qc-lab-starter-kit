import React, { useEffect, useState } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { Dialog, DialogHeader, DialogContent, DialogFooter } from '@/components/common/ui';
import type { ReagentLotDto, ReagentLotStatusDto } from '@/types/reagent';
import type { UnitDto } from '@/types/unit';
import unitsService from '@/services/unitsService';
import reagentsService from '@/services/reagentsService';
import { supplierLotSchema } from '@/lib/schemas/reagent';

interface SupplierLotDialogProps {
  open: boolean;
  reagentId: number;
  lot?: ReagentLotDto | null;
  onClose: (saved?: boolean) => void;
}

type SupplierLotFormValues = {
  controlCode: string;
  name: string;
  catalogNumber?: string | null;
  supplier?: string | null;
  manufacturerLotNumber: string;
  certificateOfAnalysisRef?: string | null;
  statusId: number;
  unitId: any;
  quantity: number;
  expirationDate: string;
};

const SupplierLotDialog: React.FC<SupplierLotDialogProps> = ({ open, reagentId, lot, onClose }) => {
  const [units, setUnits] = useState<UnitDto[]>([]);
  const [statuses, setStatuses] = useState<ReagentLotStatusDto[]>([]);
  const isEdit = !!lot;

  const {
    register,
    handleSubmit,
    reset,
    setError,
    formState: { errors }
  } = useForm<SupplierLotFormValues>({
    resolver: zodResolver(supplierLotSchema) as any,
    defaultValues: {
      controlCode: '',
      name: '',
      catalogNumber: '',
      supplier: '',
      manufacturerLotNumber: '',
      certificateOfAnalysisRef: '',
      statusId: 1,
      unitId: null,
      quantity: 0,
      expirationDate: ''
    }
  });

  useEffect(() => {
    if (open) {
      Promise.all([
        unitsService.getAllUnits(),
        reagentsService.getReagentLotStatuses()
      ]).then(([unitsData, statusesData]) => {
        setUnits(unitsData);
        setStatuses(statusesData);
      });

      if (lot) {
        reset({
          controlCode: lot.controlCode,
          name: lot.supplierLotName || '',
          catalogNumber: lot.catalogNumber || '',
          supplier: lot.supplier || '',
          manufacturerLotNumber: lot.manufacturerLotNumber || '',
          certificateOfAnalysisRef: lot.certificateOfAnalysisRef || '',
          statusId: lot.statusId,
          unitId: lot.unitId || null,
          quantity: lot.quantity,
          expirationDate: lot.expirationDate
        });
      } else {
        reset({
          controlCode: '',
          name: '',
          catalogNumber: '',
          supplier: '',
          manufacturerLotNumber: '',
          certificateOfAnalysisRef: '',
          statusId: 1,
          unitId: null,
          quantity: 0,
          expirationDate: ''
        });
      }
    }
  }, [open, lot, reset]);

  const onSubmit = async (values: SupplierLotFormValues) => {
    try {
      const parsedUnitId = values.unitId ? Number(values.unitId) : null;
      const parsedStatusId = Number(values.statusId);
      const parsedQuantity = Number(values.quantity);

      if (isEdit && lot) {
        await reagentsService.updateSupplierLot(lot.controlCodeId, {
          statusId: parsedStatusId,
          unitId: parsedUnitId,
          quantity: parsedQuantity,
          expirationDate: values.expirationDate,
          name: values.name,
          catalogNumber: values.catalogNumber || null,
          supplier: values.supplier || null,
          manufacturerLotNumber: values.manufacturerLotNumber,
          certificateOfAnalysisRef: values.certificateOfAnalysisRef || null
        });
      } else {
        await reagentsService.createSupplierLot({
          materialId: reagentId,
          controlCode: values.controlCode,
          statusId: parsedStatusId,
          unitId: parsedUnitId,
          quantity: parsedQuantity,
          expirationDate: values.expirationDate,
          name: values.name,
          catalogNumber: values.catalogNumber || null,
          supplier: values.supplier || null,
          manufacturerLotNumber: values.manufacturerLotNumber,
          certificateOfAnalysisRef: values.certificateOfAnalysisRef || null
        });
      }
      onClose(true);
    } catch (err: any) {
      console.error('Failed to save supplier lot', err);
      if (err.response?.data?.msg) {
        setError('root', { message: err.response.data.msg });
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
            <label>Lot Name / Description</label>
            <input 
              {...register('name')} 
              className="form-control"
              placeholder="e.g. Hydrochloric Acid 37% Lot A"
            />
            {errors.name && <span className="text-danger">{errors.name.message}</span>}
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
            <label>Supplier / Vendor</label>
            <input 
              {...register('supplier')} 
              className="form-control"
              placeholder="e.g. Sigma-Aldrich"
            />
            {errors.supplier && <span className="text-danger">{errors.supplier.message}</span>}
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