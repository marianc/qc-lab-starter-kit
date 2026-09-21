export interface TestEnumDto {
  testId: number;
  value: number;
  name: string;
  nrOrd: number;
  originalValue?: number | null;
}

export interface TestDto {
  id: number;
  name: string;
  code: string;
  description?: string | null;
  typeId: number;
  typeName: string;
  isArray: boolean;
  isParam: boolean;
  forEnvironmentalControl: boolean;
  forCertification: boolean;
  relativeUncertaintyPct?: number | null;
  defaultCoverageFactorK?: number | null;
  unitId?: number | null;
  unitName?: string | null;
  normId?: number | null;
  normRef?: string | null;
  sopId?: number | null;
  isFormValidated: boolean;
  nrOrd: number;
  isObsolete: boolean;
  dateCreated?: string | null;
  dateObsolete?: string | null;
  commentsObsolete?: string | null;
  enums?: TestEnumDto[] | null;
  enumListString?: string | null;
}

export interface CreateTestEnumDto {
  value: number;
  name: string;
  nrOrd: number;
}

export interface CreateTestDto {
  name: string;
  code: string;
  description?: string | null;
  typeId: number;
  isArray: boolean;
  isParam: boolean;
  forEnvironmentalControl: boolean;
  forCertification: boolean;
  relativeUncertaintyPct?: number | null;
  defaultCoverageFactorK?: number | null;
  unitId?: number | null;
  normId?: number | null;
  normRef?: string | null;
  sopId?: number | null;
  nrOrd: number;
  isObsolete: boolean;
  enums?: CreateTestEnumDto[] | null;
}

export interface UpdateTestDto extends CreateTestDto {}

export interface ReorderTestDto {
  id: number;
  nrOrd: number;
}

export interface ReorderTestEnumDto {
  value: number;
  nrOrd: number;
}

export interface UpdateTestEnumDto {
  value: number;
  name: string;
  nrOrd: number;
}

export interface TestEquipmentDto {
  id: number;
  equipmentCode: string;
  name: string;
  serialNumber?: string | null;
  status?: string | null;
}

export interface UpdateTestEquipmentsDto {
  equipmentIds: number[];
}

export interface TestReagentDto {
  id: number;
  code: string;
  name: string;
  casNumber?: string | null;
}

export interface UpdateTestReagentsDto {
  materialIds: number[];
}


