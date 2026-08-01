export interface FormGroupDto {
  id: number;
  name: string;
  description: string | null;
  nrOrd: number;
  isFormValidated: boolean;
}

export interface CreateFormGroupDto {
  name: string;
  description: string | null;
  nrOrd: number;
}

export interface UpdateFormGroupDto {
  id?: number | null;
  name: string;
  description: string | null;
  nrOrd: number;
}

export interface FormSummaryDto {
  id: number;
  version: string | null;
  isSubmitted: boolean;
  isValidated: boolean;
  isCancelled: boolean;
}
