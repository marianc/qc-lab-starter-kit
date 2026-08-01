export interface CategoryDto {
  id: number;
  name: string;
  code: string;
  description: string | null;
  isObsolete: boolean;
  dateCreated: string;
  dateObsolete: string | null;
  commentsObsolete: string | null;
}

export interface CreateCategoryDto {
  name: string;
  code: string;
  description?: string | null;
}

export interface UpdateCategoryDto {
  name: string;
  code: string;
  description?: string | null;
}

export interface CategoryTestDto {
  id: number;
  name: string;
  code: string;
  typeId: number;
  isArray: boolean;
  typeName: string;
}

export interface UpdateCategoryTestsDto {
  testIds: number[];
}
