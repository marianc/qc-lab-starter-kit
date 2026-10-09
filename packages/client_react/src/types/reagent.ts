export interface ReagentDto {
  id: number;
  name: string;
  code: string;
  description?: string | null;
  normId?: number | null;
  normName?: string | null;
  isCertifiedReference: boolean;
  casNumber?: string | null;
  isObsolete: boolean;
  dateCreated: string;
  dateObsolete?: string | null;
  commentsObsolete?: string | null;
}

export interface CreateReagentDto {
  name: string;
  code: string;
  description?: string | null;
  normId?: number | null;
  isCertifiedReference: boolean;
  casNumber?: string | null;
  isObsolete: boolean;
}

export interface UpdateReagentDto extends CreateReagentDto {}

export interface ReagentLotStatusDto {
  id: number;
  name: string;
}

export interface ReagentSupplierDto {
  id: number;
  name: string;
}

export interface ReagentLotDto {
  controlCodeId: number;
  materialId: number;
  materialName: string;
  controlCode: string;
  isProduced: boolean;
  producedByUserId?: number | null;
  producedByUserTag?: string | null;
  statusId: number;
  statusName: string;
  quantity: number;
  unitId?: number | null;
  unitName?: string | null;
  expirationDate: string;
  dateCreated: string;

  // Supplier Lot fields
  supplierId?: number | null;
  supplierName?: string | null;
  catalogNumber?: string | null;
  manufacturerLotNumber?: string | null;
  certificateOfAnalysisRef?: string | null;
  comments?: string | null;
  isReadonly: boolean;
  dateReadonly?: string | null;
  isCertifiedReference: boolean;

  // Production Lot fields
  ingredientControlCodeIds: number[];
  ingredientControlCodes: string[];
  ingredientMaterialCodes: string[];
}

export interface CreateSupplierLotDto {
  materialId: number;
  controlCode: string;
  statusId: number;
  quantity: number;
  unitId?: number | null;
  expirationDate: string;
  supplierId: number;
  catalogNumber?: string | null;
  manufacturerLotNumber: string;
  certificateOfAnalysisRef?: string | null;
  comments?: string | null;
}

export interface UpdateSupplierLotDto {
  statusId: number;
  quantity: number;
  unitId?: number | null;
  expirationDate: string;
  supplierId: number;
  catalogNumber?: string | null;
  manufacturerLotNumber: string;
  certificateOfAnalysisRef?: string | null;
  comments?: string | null;
}

export interface CreateProductionLotDto {
  materialId: number;
  controlCode: string;
  statusId: number;
  quantity: number;
  unitId?: number | null;
  expirationDate: string;
  producedByUserId?: number | null;
  ingredientControlCodeIds: number[];
}

export interface UpdateProductionLotDto {
  statusId: number;
  quantity: number;
  unitId?: number | null;
  expirationDate: string;
  producedByUserId?: number | null;
  ingredientControlCodeIds: number[];
}

export interface ReagentSupplierLotCertTestDto {
  controlCodeId: number;
  testId: number;
  testName: string;
  testCode: string;
  unitName?: string | null;
  value: number;
  uncertaintyValue?: number | null;
  coverageFactorK?: number | null;
  traceabilityStatement?: string | null;
}

export interface UpsertReagentSupplierLotCertTestDto {
  testId: number;
  value: number;
  uncertaintyValue?: number | null;
  coverageFactorK?: number | null;
  traceabilityStatement?: string | null;
}
