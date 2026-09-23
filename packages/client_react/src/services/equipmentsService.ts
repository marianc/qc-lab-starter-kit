import apiClient from './apiClient';
import type { 
  EquipmentDto, 
  CreateEquipmentDto, 
  UpdateEquipmentDto, 
  EquipmentCalibrationDto, 
  CreateEquipmentCalibrationDto,
  EquipmentStatusDto,
  EquipmentCalibrationStatusDto
} from '@/types/equipment';
import type { IdDto } from '@/types/models';

const equipmentsService = {
  async getAllEquipments(): Promise<EquipmentDto[]> {
    const response = await apiClient.get<EquipmentDto[]>('/api/equipments');
    return response.data;
  },

  async getEquipmentStatuses(): Promise<EquipmentStatusDto[]> {
    const response = await apiClient.get<EquipmentStatusDto[]>('/api/equipments/statuses');
    return response.data;
  },

  async getEquipmentCalibrationStatuses(): Promise<EquipmentCalibrationStatusDto[]> {
    const response = await apiClient.get<EquipmentCalibrationStatusDto[]>('/api/equipment_calibration_statuses');
    return response.data;
  },

  async getEquipment(id: number): Promise<EquipmentDto | null> {
    const response = await apiClient.get<EquipmentDto>(`/api/equipments/${id}`);
    return response.data;
  },

  async createEquipment(dto: CreateEquipmentDto): Promise<IdDto> {
    const response = await apiClient.post<IdDto>('/api/equipments', dto);
    return response.data;
  },

  async updateEquipment(id: number, dto: UpdateEquipmentDto): Promise<void> {
    await apiClient.put(`/api/equipments/${id}`, dto);
  },

  async getEquipmentCalibrations(equipmentId: number): Promise<EquipmentCalibrationDto[]> {
    const response = await apiClient.get<EquipmentCalibrationDto[]>(`/api/equipments/${equipmentId}/calibrations`);
    return response.data;
  },

  async addEquipmentCalibration(equipmentId: number, dto: CreateEquipmentCalibrationDto): Promise<IdDto> {
    const response = await apiClient.post<IdDto>(`/api/equipments/${equipmentId}/calibrations`, dto);
    return response.data;
  },

  async updateEquipmentCalibration(calibrationId: number, dto: CreateEquipmentCalibrationDto): Promise<void> {
    await apiClient.put(`/api/equipment-calibrations/${calibrationId}`, dto);
  },

  async validateUniqueness(property: string, value: string, id: number): Promise<boolean> {
    const response = await apiClient.get<{ is_unique: boolean }>(`api/validate/unique?entity=Equipment&property=${property}&value=${encodeURIComponent(value)}&id=${id}`);
    return response.data.is_unique;
  }
};

export default equipmentsService;
