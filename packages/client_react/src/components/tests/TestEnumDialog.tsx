import React, { useEffect } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import * as z from 'zod';
import { Dialog, DialogHeader, DialogContent, DialogFooter } from '../common/ui';
import type { TestEnumDto } from '@/types/test';
import testsService from '@/services/testsService';
import { testEnumSchema } from '@/lib/schemas/test';

interface TestEnumDialogProps {
  open: boolean;
  enumData?: TestEnumDto | null;
  isEdit: boolean;
  onSave: (data: TestEnumDto) => void;
  onClose: () => void;
}

type EnumFormValues = z.infer<typeof testEnumSchema>;

const TestEnumDialog: React.FC<TestEnumDialogProps> = ({ open, enumData, isEdit, onSave, onClose }) => {
  const [isValidating, setIsValidating] = React.useState(false);
  const {
    register,
    handleSubmit,
    reset,
    setError,
    clearErrors,
    getValues,
    formState: { errors }
  } = useForm<EnumFormValues>({
    resolver: zodResolver(testEnumSchema),
    defaultValues: {
      testId: 0,
      value: 0,
      name: '',
      nrOrd: 0,
      originalValue: null
    }
  });

  useEffect(() => {
    if (open) {
      reset({
        testId: enumData?.testId ?? 0,
        value: enumData?.value ?? 0,
        name: enumData?.name ?? '',
        nrOrd: enumData?.nrOrd ?? 0,
        originalValue: isEdit ? (enumData?.value ?? null) : null
      });
    }
  }, [open, enumData, isEdit, reset]);

  const validateUniqueness = async (property: "Value" | "Name"): Promise<boolean> => {
    const values = getValues();
    const valueStr = property === "Value" ? values.value?.toString() : values.name;
    
    if (valueStr === undefined || (property === "Name" && !valueStr)) return true;

    setIsValidating(true);
    try {
      const idParam = values.originalValue;
      const isUnique = await testsService.validateUniqueness(property, valueStr!, idParam, "TestEnum", values.testId);
      
      const field = property.toLowerCase() as "value" | "name";
      if (!isUnique) {
        setError(field, {
          type: 'manual',
          message: `${property} must be unique for this test.`
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

  const onSubmit = async (values: EnumFormValues) => {
    const isValueUnique = await validateUniqueness('Value');
    const isNameUnique = await validateUniqueness('Name');
    
    if (isValueUnique && isNameUnique) {
      onSave(values as TestEnumDto);
    }
  };

  const valueRegister = register('value', { valueAsNumber: true });
  const nameRegister = register('name');

  return (
    <Dialog open={open} onClose={onClose}>
      <DialogHeader>
        {isEdit ? "Edit" : "Add"} Enum Value
      </DialogHeader>
      <form onSubmit={handleSubmit(onSubmit)}>
        <DialogContent>
          <div className="form-group">
            <label>Value</label>
            <input 
              type="number"
              {...valueRegister}
              className="form-control" 
              disabled={isEdit}
              onBlur={(e) => {
                valueRegister.onBlur(e);
                validateUniqueness('Value');
              }}
            />
            {errors.value && <span className="text-danger">{errors.value.message}</span>}
          </div>

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
            <label>Order</label>
            <input 
              type="number"
              {...register('nrOrd', { valueAsNumber: true })} 
              className="form-control" 
            />
            {errors.nrOrd && <span className="text-danger">{errors.nrOrd.message}</span>}
          </div>
        </DialogContent>
        <DialogFooter>
          <button type="submit" className="action-button primary" disabled={isValidating}>Save</button>
          <button type="button" className="action-button secondary" onClick={onClose}>Cancel</button>
        </DialogFooter>
      </form>
    </Dialog>
  );
};

export default TestEnumDialog;
