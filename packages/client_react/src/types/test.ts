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
  unitId?: number | null;
  unitName?: string | null;
  normId?: number | null;
  normRef?: string | null;
  isParam: boolean;
  isArray: boolean;
  forCertification: boolean;
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
  description?: string | null;
  code: string;
  typeId: number;
  isParam: boolean;
  unitId?: number | null;
  normId?: number | null;
  normRef?: string | null;
  nrOrd: number;
  isObsolete: boolean;
  isArray: boolean;
  forCertification: boolean;
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
