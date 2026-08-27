export interface MeasurementDto {
  id: number;
  receptionId: number;
  formId: number | null;
  comments: string | null;
  isReported: boolean;
  isReadonly: boolean;
  userUpdateId: number;
  userUpdateTag: string | null;
  userReportedTag: string | null;
  dateUpdate: string;
  tests: MeasurementTestDto[];
  formParamsSchema: MeasurementFormParamSchemaDto[];
  formDataValues?: Record<string, any>;
}

export interface MeasurementTestDetailDto {
  id: number;
  receptionId: number;
  comments: string | null;
  useDefaultEquipment: boolean;
  isReported: boolean;
  isReadonly: boolean;
  userUpdateId: number;
  userUpdateTag: string | null;
  userReportedTag: string | null;
  dateUpdate: string;
  tests: MeasurementTestDto[];
}

export interface MeasurementParamDetailDto {
  id: number;
  receptionId: number;
  formId: number;
  comments: string | null;
  useDefaultEquipment: boolean;
  isReported: boolean;
  isReadonly: boolean;
  userUpdateId: number;
  userUpdateTag: string | null;
  userReportedTag: string | null;
  dateUpdate: string;
  formParamsSchema?: MeasurementFormParamSchemaDto[];
  measurementData: Record<string, any>;
  calculatedResults: Record<string, any>;
  conditionPass: Record<string, any>;
}

export interface MeasurementTestDto {
  testId: number;
  value: any;
  note: string | null;
}

export interface CreateMeasurementDto {
  receptionId: number;
  comments: string | null;
  isReported: boolean;
  formId: number | null;
  userUpdateId: number;
}

export interface UpdateMeasurementTestBulkDto {
  comments: string | null;
  useDefaultEquipment: boolean;
  isReported: boolean;
  userUpdateId: number;
  tests?: MeasurementTestDto[];
}

export interface UpdateMeasurementParamDto {
  comments: string | null;
  useDefaultEquipment: boolean;
  isReported: boolean;
  userUpdateId: number;
  measurementData: Record<string, any>;
}

export interface MeasurementFormParamSchemaDto {
  testId: number;
  code: string;
  name: string;
  typeId: number;
  isParam: boolean;
  isArray: boolean;
  isCalculated: boolean;
  formula: string | null;
  defaultValue: number | null;
  nrOrd: number;
  codeRelatedArrays: string | null;
  conditionNote: string | null;
}

export interface AddMeasurementTestDto {
  testId: number;
  value: any;
  note: string | null;
}
