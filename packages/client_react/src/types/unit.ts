export interface UnitDto {
  id: number;
  name: string;
  description?: string | null;
}

export interface CreateUnitDto {
  name: string;
  description?: string | null;
}

export interface UpdateUnitDto {
  name: string;
  description?: string | null;
}
