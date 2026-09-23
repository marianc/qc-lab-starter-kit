export interface EquipmentStatusDto {
  id: number;
  name: string;
}

export interface EquipmentCalibrationStatusDto {
  id: number;
  name: string;
}

export interface EquipmentDto {
  id: number;
  equipmentCode: string;
  name: string;
  manufacturer?: string | null;
  model?: string | null;
  serialNumber: string;
  location?: string | null;
  statusId: number;
  status: string;
  calibrationIntervalDays?: number | null;
  nextCalibrationDue?: string | null;
  dateCreated: string;
}

export interface CreateEquipmentDto {
  equipmentCode: string;
  name: string;
  manufacturer?: string | null;
  model?: string | null;
  serialNumber: string;
  location?: string | null;
  statusId: number;
  calibrationIntervalDays?: number | null;
}

export interface UpdateEquipmentDto extends CreateEquipmentDto {}

export interface EquipmentCalibrationDto {
  id: number;
  equipmentId: number;
  calibrationDate: string;
  expirationDate: string;
  certificateNumber: string;
  calibratedBy: string;
  statusId: number;
  resultStatus: string;
  referenceStandardsUsed?: string | null;
  expandedUncertainty?: number | null;
  dateCreated: string;
}

export interface CreateEquipmentCalibrationDto {
  calibrationDate: string;
  expirationDate: string;
  certificateNumber: string;
  calibratedBy: string;
  statusId: number;
  referenceStandardsUsed?: string | null;
  expandedUncertainty?: number | null;
}
