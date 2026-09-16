export interface MaterialDto {
  id: number;
  name: string;
  code: string;
  description?: string | null;
  normId?: number | null;
  normName?: string | null;
  isProduct: boolean;
  isRawMaterial: boolean;
  isReagent: boolean;
  isObsolete: boolean;
  dateCreated: string;
  dateObsolete?: string | null;
  commentsObsolete?: string | null;
}

export interface CreateMaterialDto {
  name: string;
  code: string;
  description?: string | null;
  normId?: number | null;
  isProduct: boolean;
  isRawMaterial: boolean;
  isReagent: boolean;
  isObsolete: boolean;
}

export interface UpdateMaterialDto extends CreateMaterialDto {}

export interface MaterialTestDto {
  id: number;
  name: string;
  code: string;
  typeId: number;
  isArray: boolean;
  typeName: string;
  nrOrd: number;
}

export interface UpdateMaterialTestsDto {
  testIds: number[];
}

export interface MaterialControlCodeDto {
  id: number;
  code: string;
}
