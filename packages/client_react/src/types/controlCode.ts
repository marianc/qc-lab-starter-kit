export interface ControlCodeDto {
  id: number;
  materialId: number;
  code: string;
  isReceptionReceived: boolean;
}

export interface ControlCodeSelectionDto {
  id: number;
  code: string;
}

export interface CreateControlCodeDto {
  materialId: number;
  code: string;
}
