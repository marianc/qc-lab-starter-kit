import React, { useEffect, useState } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { Dialog, DialogHeader, DialogContent, DialogFooter } from '@/components/common/ui';
import type { ReagentLotDto, ReagentLotStatusDto } from '@/types/reagent';
import type { UnitDto } from '@/types/unit';
import type { UserDto } from '@/types/user';
import unitsService from '@/services/unitsService';
import usersService from '@/services/usersService';
import reagentsService from '@/services/reagentsService';
import { productionLotSchema } from '@/lib/schemas/reagent';
import styles from './ProductionLotDialog.module.css';

interface ProductionLotDialogProps {
  open: boolean;
  reagentId: number;
  lot?: ReagentLotDto | null;
  onClose: (saved?: boolean) => void;
}

type ProductionLotFormValues = {
  controlCode: string;
  producedByUserId: any;
  statusId: number;
  quantity: number;
  unitId: any;
  expirationDate: string;
  ingredientControlCodeIds: number[];
};

const ProductionLotDialog: React.FC<ProductionLotDialogProps> = ({ open, reagentId, lot, onClose }) => {
  const [units, setUnits] = useState<UnitDto[]>([]);
  const [statuses, setStatuses] = useState<ReagentLotStatusDto[]>([]);
  const [users, setUsers] = useState<UserDto[]>([]);
  const [availableLots, setAvailableLots] = useState<ReagentLotDto[]>([]);
  const isEdit = !!lot;

  const {
    register,
    handleSubmit,
    reset,
    watch,
    setValue,
    setError,
    formState: { errors }
  } = useForm<ProductionLotFormValues>({
    resolver: zodResolver(productionLotSchema) as any,
    defaultValues: {
      controlCode: '',
      producedByUserId: null,
      statusId: 1,
      quantity: 0,
      unitId: null,
      expirationDate: '',
      ingredientControlCodeIds: []
    }
  });

  const selectedIngredients = watch('ingredientControlCodeIds') || [];

  useEffect(() => {
    if (open) {
      Promise.all([
        unitsService.getAllUnits(),
        reagentsService.getReagentLotStatuses(),
        usersService.getAllUsers(),
        reagentsService.getAllActiveReagentLots()
      ]).then(([unitsData, statusesData, usersData, activeLotsData]) => {
        setUnits(unitsData);
        setStatuses(statusesData);
        setUsers(usersData);
        // Exclude current lot if in edit mode to prevent circular dependency
        const filtered = lot 
          ? activeLotsData.filter(l => l.controlCodeId !== lot.controlCodeId) 
          : activeLotsData;
        setAvailableLots(filtered);

        if (lot) {
          reset({
            controlCode: lot.controlCode,
            producedByUserId: lot.producedByUserId !== undefined && lot.producedByUserId !== null ? String(lot.producedByUserId) : '',
            statusId: lot.statusId,
            quantity: lot.quantity,
            unitId: lot.unitId !== undefined && lot.unitId !== null ? String(lot.unitId) : '',
            expirationDate: lot.expirationDate ? lot.expirationDate.split('T')[0] : '',
            ingredientControlCodeIds: lot.ingredientControlCodeIds || []
          });
        } else {
          reset({
            controlCode: '',
            producedByUserId: '',
            statusId: 1,
            quantity: 0,
            unitId: '',
            expirationDate: '',
            ingredientControlCodeIds: []
          });
        }
      });
    }
  }, [open, lot, reset]);

  const toggleIngredient = (id: number) => {
    const current = [...selectedIngredients];
    const index = current.indexOf(id);
    if (index > -1) {
      current.splice(index, 1);
    } else {
      current.push(id);
    }
    setValue('ingredientControlCodeIds', current);
  };

  const onSubmit = async (values: ProductionLotFormValues) => {
    try {
      const parsedUnitId = values.unitId ? Number(values.unitId) : null;
      const parsedUserId = values.producedByUserId ? Number(values.producedByUserId) : null;
      const parsedStatusId = Number(values.statusId);
      const parsedQuantity = Number(values.quantity);

      if (isEdit && lot) {
        await reagentsService.updateProductionLot(lot.controlCodeId, {
          statusId: parsedStatusId,
          quantity: parsedQuantity,
          unitId: parsedUnitId,
          expirationDate: values.expirationDate,
          producedByUserId: parsedUserId,
          ingredientControlCodeIds: values.ingredientControlCodeIds
        });
      } else {
        await reagentsService.createProductionLot({
          materialId: reagentId,
          controlCode: values.controlCode,
          statusId: parsedStatusId,
          quantity: parsedQuantity,
          unitId: parsedUnitId,
          expirationDate: values.expirationDate,
          producedByUserId: parsedUserId,
          ingredientControlCodeIds: values.ingredientControlCodeIds
        });
      }
      onClose(true);
    } catch (err: any) {
      console.error('Failed to save production lot', err);
      if (err.response?.data?.msg) {
        setError('root', { message: err.response.data.msg });
      }
    }
  };

  return (
    <Dialog open={open} onClose={() => onClose(false)}>
      <DialogHeader>
        {isEdit ? `Edit Production Lot (${lot?.controlCode})` : "Add New Production Lot"}
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
              placeholder="e.g. SOL-2026-001"
            />
            {errors.controlCode && <span className="text-danger">{errors.controlCode.message}</span>}
          </div>

          <div className="form-group">
            <label>Produced By (Technician / Chemist)</label>
            <select {...register('producedByUserId')} className="form-control">
              <option value="">-- Select User --</option>
              {users.map(u => (
                <option key={u.id} value={u.id}>{u.tag}</option>
              ))}
            </select>
            {errors.producedByUserId && <span className="text-danger">{errors.producedByUserId.message as string}</span>}
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
            <label>Constituent Ingredients (Reagent Lots Used)</label>
            {availableLots.length === 0 ? (
              <p className="text-muted font-italic">No other active reagent lots available.</p>
            ) : (
              <div className={styles.ingredientsContainer}>
                {availableLots.map(ing => (
                  <div key={ing.controlCodeId} className={styles.ingredientItem}>
                    <input 
                      type="checkbox" 
                      id={`ing-${ing.controlCodeId}`}
                      checked={selectedIngredients.includes(ing.controlCodeId)}
                      onChange={() => toggleIngredient(ing.controlCodeId)}
                    />
                    <label htmlFor={`ing-${ing.controlCodeId}`} className={styles.ingredientLabel} style={{ fontWeight: 'normal' }}>
                      {ing.materialName} ({ing.controlCode})
                    </label>
                  </div>
                ))}
              </div>
            )}
            {errors.ingredientControlCodeIds && <span className="text-danger d-block mt-1">{errors.ingredientControlCodeIds.message as string}</span>}
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

export default ProductionLotDialog;