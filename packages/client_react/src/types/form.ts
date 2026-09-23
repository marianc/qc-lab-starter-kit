export interface FormDto {
  id: number;
  name: string;
  customNav: string | null;
  isCustomized: boolean;
  isCancelled: boolean;
  isSubmitted: boolean;
  isValidated: boolean;
  formParams: FormParamSimpleDto[];
}

export interface FormParamSimpleDto {
  testId: number;
  isCalculated: boolean;
  codeRelatedArrays: string | null;
  isRequired: boolean;
  defaultValue: number | null;
  nrOrd: number;
  conditionNote: string | null;
}

export interface FormDetailDto {
  id: number;
  formGroupId: number;
  version: string | null;
  daysActiveForEditing: number;
  customNav: string | null;
  isCustomized: boolean;
  isSubmitted: boolean;
  userSubmittedId: number | null;
  userSubmittedTag: string | null;
  dateSubmitted: string | null;
  commentsSubmitted: string | null;
  isValidated: boolean;
  userValidatedTag: string | null;
  dateValidated: string | null;
  commentsValidated: string | null;
  isCancelled: boolean;
  userCancelledTag: string | null;
  dateCancelled: string | null;
  commentsCancelled: string | null;
  name: string;
}

export interface CreateFormDto {
  formGroupId: number;
  version: string;
  daysActiveForEditing?: number;
  customNav: string | null;
  isCustomized: boolean;
  submittedUserId: number;
  submittedDate: string | null;
}

export interface UpdateFormDto {
  formGroupId: number;
  version: string;
  daysActiveForEditing?: number;
  customNav: string | null;
  isCustomized: boolean;
  userId: number;
}

export interface FormConditionEvalDto {
  id: number;
  formId: number;
  testId: number;
  value: number;
  result: number | null;
  expectedResult: number;
  isMatch: boolean;
  note: string | null;
}

export interface FormParamDto {
  formId: number;
  testId: number;
  isCalculated: boolean;
  formula: string | null;
  codeRelatedArrays: string | null;
  isRequired: boolean;
  defaultValue: number | null;
  nrOrd: number;
  nrOrdCalc: number;
  code: string;
  name: string;
  typeId: number;
  isArray: boolean;
  unitName?: string | null;
  dependencies: string;
  isFormSubmitted: boolean;
  hasCondition: boolean;
  condition: string | null;
  conditionNote: string | null;
  evals: FormConditionEvalDto[];
}

export interface ReorderFormParamDto {
  testId: number;
  nrOrd: number;
}

export interface BatchUpdateFormParamDto {
  testId: number;
  isCalculated: boolean;
  formula: string | null;
  codeRelatedArrays: string | null;
  isRequired: boolean;
  defaultValue: number | null;
  nrOrd: number;
  nrOrdCalc: number;
  hasCondition: boolean;
  condition: string | null;
  conditionNote: string | null;
  evals: FormConditionEvalDto[];
}

export interface CreateFormParamDto extends BatchUpdateFormParamDto { }

export interface UpdateFormParamDto extends BatchUpdateFormParamDto { }

export interface FormActionDto {
  userId: number;
  commentsValidated?: string | null;
  commentsCancelled?: string | null;
}
