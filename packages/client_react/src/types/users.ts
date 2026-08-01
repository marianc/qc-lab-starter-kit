export interface CreateUserDto {
  tag: string;
  code?: string | null;
  email: string;
  firstName?: string | null;
  lastName?: string | null;
  isAdmin: boolean;
  isLabPers: boolean;
  isQcPers: boolean;
  password: string;
}

export interface UpdateUserDto {
  tag: string;
  code?: string | null;
  email: string;
  firstName?: string | null;
  lastName?: string | null;
  isAdmin: boolean;
  isLabPers: boolean;
  isQcPers: boolean;
  mustChangePassword: boolean;
}

export interface ResetPasswordDto {
  newPassword: string;
  confirmPassword: string;
}
