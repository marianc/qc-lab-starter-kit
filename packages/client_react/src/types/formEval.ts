export interface FormEvalDto {
  id: number;
  formId: number;
  description: string | null;
  measurementData: Record<string, any>;
  calculatedResults: Record<string, any>;
  expectedResults: Record<string, EvalResultDto>;
}

export interface EvalResultDto {
  value: any;
  isMatch: any;
}

export interface CreateFormEvalDto {
  formId: number;
  description: string | null;
}

export interface UpdateFormEvalDto {
  description: string | null;
  measurementData: Record<string, any>;
  expectedResults: Record<string, any>;
}
