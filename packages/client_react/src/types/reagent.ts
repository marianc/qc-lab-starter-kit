export interface ReagentDto {
  id: number;
  name: string;
  code: string;
  description?: string | null;
  casNumber?: string | null;
  normId?: number | null;
  normName?: string | null;
  isObsolete: boolean;
  dateCreated: string;
  dateObsolete?: string | null;
  commentsObsolete?: string | null;
}

export interface CreateReagentDto {
  name: string;
  code: string;
  description?: string | null;
  casNumber?: string | null;
  normId?: number | null;
  isObsolete: boolean;
}

export interface UpdateReagentDto extends CreateReagentDto {}

export interface ReagentLotStatusDto {
  id: number;
  name: string;
}

export interface ReagentLotDto {
  controlCodeId: number;
  materialId: number;
  controlCode: string;
  isProduced: boolean;
  producedByUserId?: number | null;
  producedByUserTag?: string | null;
  statusId: number;
  statusName: string;
  unitId?: number | null;
  unitName?: string | null;
  quantity: number;
  expirationDate: string;
  dateCreated: string;

  // Supplier Lot fields
  supplierLotName?: string | null;
  catalogNumber?: string | null;
  supplier?: string | null;
  manufacturerLotNumber?: string | null;
  certificateOfAnalysisRef?: string | null;

  // Production Lot fields
  ingredientControlCodeIds: number[];
  ingredientControlCodes: string[];
}

export interface CreateSupplierLotDto {
  materialId: number;
  controlCode: string;
  statusId: number;
  unitId?: number | null;
  quantity: number;
  expirationDate: string;
  name: string;
  catalogNumber?: string | null;
  supplier?: string | null;
  manufacturerLotNumber: string;
  certificateOfAnalysisRef?: string | null;
}

export interface UpdateSupplierLotDto {
  statusId: number;
  unitId?: number | null;
  quantity: number;
  expirationDate: string;
  name: string;
  catalogNumber?: string | null;
  supplier?: string | null;
  manufacturerLotNumber: string;
  certificateOfAnalysisRef?: string | null;
}

export interface CreateProductionLotDto {
  materialId: number;
  controlCode: string;
  statusId: number;
  unitId?: number | null;
  quantity: number;
  expirationDate: string;
  producedByUserId?: number | null;
  ingredientControlCodeIds: number[];
}

export interface UpdateProductionLotDto {
  statusId: number;
  unitId?: number | null;
  quantity: number;
  expirationDate: string;
  producedByUserId?: number | null;
  ingredientControlCodeIds: number[];
}
