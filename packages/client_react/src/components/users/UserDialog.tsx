import React, { useEffect, useState } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import * as z from 'zod';
import { Dialog, DialogHeader, DialogContent, DialogFooter } from '../common/ui';
import styles from './UserDialog.module.css';
import type { UserDto } from '@/types/user';
import usersService from '@/services/usersService';
import { userSchema } from '@/lib/schemas/user';

type UserFormData = z.infer<typeof userSchema>;

interface Props {
  open: boolean;
  onClose: () => void;
  userData?: UserDto | null;
  onSave: (data: UserDto) => void;
}

const UserDialog: React.FC<Props> = ({ open, onClose, userData, onSave }) => {
  const [error, setError] = useState<string | null>(null);
  const [isValidating, setIsValidating] = useState(false);

  const {
    register,
    handleSubmit,
    reset,
    setError: setFormError,
    clearErrors,
    formState: { errors },
    getValues
  } = useForm<UserFormData>({
    resolver: zodResolver(userSchema),
    defaultValues: {
      id: 0,
      tag: '',
      code: '',
      email: '',
      isAdmin: false,
      isLabPers: false,
      isQcPers: false,
      mustChangePassword: false,
    }
  });

  useEffect(() => {
    if (open) {
      if (userData) {
        reset({
          ...userData,
          password: '',
          confirmPassword: ''
        });
      } else {
        reset({
          id: 0,
          tag: '',
          code: '',
          email: '',
          isAdmin: false,
          isLabPers: false,
          isQcPers: false,
          mustChangePassword: false,
          password: '',
          confirmPassword: ''
        });
      }
      setError(null);
    }
  }, [open, userData, reset]);

  const validateUniqueness = async (propertyName: "Name" | "Code" | "Email"): Promise<boolean> => {
    const fieldMap = {
      Name: "tag",
      Code: "code",
      Email: "email"
    } as const;

    const fieldName = fieldMap[propertyName];
    const value = getValues(fieldName);
    if (!value) return true;

    setIsValidating(true);
    try {
      const isUnique = await usersService.validateUniqueness(propertyName, value, getValues('id'));
      if (!isUnique) {
        setFormError(fieldName, { message: `${propertyName} is already in use.` });
        return false;
      } else {
        clearErrors(fieldName);
        return true;
      }
    } catch (err) {
      console.error(`Uniqueness check failed:`, err);
      return false;
    } finally {
      setIsValidating(false);
    }
  };

  const onSubmit = async (data: UserFormData) => {
    const isNameUnique = await validateUniqueness("Name");
    const isCodeUnique = await validateUniqueness("Code");
    const isEmailUnique = await validateUniqueness("Email");

    if (isNameUnique && isCodeUnique && isEmailUnique) {
      onSave(data as UserDto);
    }
  };

  const tagRegister = register('tag');
  const codeRegister = register('code');
  const emailRegister = register('email');

  return (
    <Dialog open={open} onClose={onClose}>
      <DialogHeader>{userData && userData.id > 0 ? "Edit User" : "Add User"}</DialogHeader>
      <form onSubmit={handleSubmit(onSubmit)} className={styles.userEditForm}>
        <DialogContent>
          {error && <div className={styles.errorMessage}>{error}</div>}
          
          <div className="form-group">
            <label>Name (tag)</label>
            <input 
              {...tagRegister} 
              className="form-control" 
              onBlur={(e) => {
                tagRegister.onBlur(e);
                validateUniqueness("Name");
              }}
            />
            {errors.tag && <span className="text-danger">{errors.tag.message}</span>}
          </div>

          <div className="form-group">
            <label>Code</label>
            <input 
              {...codeRegister} 
              className="form-control" 
              onBlur={(e) => {
                codeRegister.onBlur(e);
                validateUniqueness("Code");
              }}
            />
            {errors.code && <span className="text-danger">{errors.code.message}</span>}
          </div>

          <div className="form-group">
            <label>Email</label>
            <input 
              {...emailRegister} 
              className="form-control" 
              onBlur={(e) => {
                emailRegister.onBlur(e);
                validateUniqueness("Email");
              }}
            />
            {errors.email && <span className="text-danger">{errors.email.message}</span>}
          </div>

          <div className="form-group">
            <label>First Name</label>
            <input {...register('firstName')} className="form-control" />
            {errors.firstName && <span className="text-danger">{errors.firstName.message}</span>}
          </div>

          <div className="form-group">
            <label>Last Name (family name)</label>
            <input {...register('lastName')} className="form-control" />
            {errors.lastName && <span className="text-danger">{errors.lastName.message}</span>}
          </div>

          {getValues('id') === 0 && (
            <>
              <div className="form-group">
                <label>Password</label>
                <input type="password" {...register('password')} className="form-control" />
                {errors.password && <span className="text-danger">{errors.password.message}</span>}
              </div>
              <div className="form-group">
                <label>Confirm Password</label>
                <input type="password" {...register('confirmPassword')} className="form-control" />
                {errors.confirmPassword && <span className="text-danger">{errors.confirmPassword.message}</span>}
              </div>
            </>
          )}

          <div className={`form-group ${styles.checkboxGroup}`}>
            <input type="checkbox" id="is_admin" {...register('isAdmin')} />
            <label htmlFor="is_admin">Admin</label>
          </div>

          <div className={`form-group ${styles.checkboxGroup}`}>
            <input type="checkbox" id="is_lab_pers" {...register('isLabPers')} />
            <label htmlFor="is_lab_pers">Lab Personnel</label>
          </div>

          <div className={`form-group ${styles.checkboxGroup}`}>
            <input type="checkbox" id="is_qc_pers" {...register('isQcPers')} />
            <label htmlFor="is_qc_pers">QC Personnel</label>
          </div>

          {getValues('id') > 0 && (
            <div className={`form-group ${styles.checkboxGroup}`}>
              <input type="checkbox" id="must_change_password" {...register('mustChangePassword')} />
              <label htmlFor="must_change_password">Must Change Password</label>
            </div>
          )}
        </DialogContent>
        <DialogFooter>
          <button type="submit" className="action-button primary" disabled={isValidating}>Save</button>
          <button type="button" onClick={onClose} className="action-button secondary">Cancel</button>
        </DialogFooter>
      </form>
    </Dialog>
  );
};

export default UserDialog;
