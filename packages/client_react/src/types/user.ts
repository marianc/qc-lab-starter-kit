export interface UserDto {
  id: number;
  tag: string;
  code: string;
  email: string;
  firstName?: string | null;
  lastName?: string | null;
  isAdmin: boolean;
  isLabPers: boolean;
  isQcPers: boolean;
  mustChangePassword: boolean;
  dateCreated?: string | null;
  datePasswordChanged?: string | null;
  isObsolete: boolean;
  dateObsolete?: string | null;
  commentsObsolete?: string | null;
  password?: string | null;
  confirmPassword?: string | null;
}
