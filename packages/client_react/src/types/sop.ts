export interface SopVersionDto {
  id: number;
  sopId: number;
  versionNumber: string;
  externalEdmsId: string | null;
  isActive: boolean;
  dateActivated: string;
  comments: string | null;
}

export interface SopDto {
  id: number;
  docCode: string;
  title: string;
  normId: number | null;
  dateCreated: string;
  versions: SopVersionDto[];
}

export interface CreateSopWithVersionDto {
  docCode: string;
  title: string;
  normId: number | null;
  versionNumber: string;
  externalEdmsId: string | null;
  comments: string | null;
}

export interface UpdateSopVersionDto {
  versionNumber: string;
  externalEdmsId: string | null;
  comments: string | null;
}

export interface MeasurementSopVersionDto {
  id: number;
  sopId: number;
  docCode: string;
  title: string;
  versionNumber: string;
  externalEdmsId: string | null;
  isActive: boolean;
  dateActivated: string;
  comments: string | null;
}

export interface UpdateMeasurementSopVersionsDto {
  sopVersionIds: number[];
}
