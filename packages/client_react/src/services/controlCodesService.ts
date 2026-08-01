import apiClient from './apiClient';
import type { 
  ControlCodeDto, 
  ControlCodeSelectionDto, 
  CreateControlCodeDto 
} from '../types/controlCode';
import type { IdDto } from '../types/models';

const controlCodesService = {
  async getAllControlCodes(): Promise<ControlCodeDto[]> {
    const response = await apiClient.get<ControlCodeDto[]>('api/control_codes');
    return response.data;
  },

  async getControlCodesByMaterial(materialId: number): Promise<ControlCodeSelectionDto[]> {
    const response = await apiClient.get<ControlCodeSelectionDto[]>(`api/control_codes/by_material/${materialId}`);
    return response.data;
  },

  async createControlCode(dto: CreateControlCodeDto): Promise<IdDto> {
    const response = await apiClient.post<IdDto>('api/control_codes', dto);
    return response.data;
  }
};

export default controlCodesService;
