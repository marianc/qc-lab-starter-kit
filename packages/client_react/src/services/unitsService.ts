import apiClient from './apiClient';
import type { UnitDto, CreateUnitDto, UpdateUnitDto } from '../types/unit';
import type { IdDto } from '../types/models';

const unitsService = {
  async getAllUnits(): Promise<UnitDto[]> {
    const response = await apiClient.get<UnitDto[]>('api/units');
    return response.data;
  },

  async getUnit(id: number): Promise<UnitDto> {
    const response = await apiClient.get<UnitDto>(`api/units/${id}`);
    return response.data;
  },

  async createUnit(dto: CreateUnitDto): Promise<IdDto> {
    const response = await apiClient.post<IdDto>('api/units', dto);
    return response.data;
  },

  async updateUnit(id: number, dto: UpdateUnitDto): Promise<void> {
    await apiClient.put(`api/units/${id}`, dto);
  },

  async validateUniqueness(property: string, value: string, id: number): Promise<boolean> {
    const response = await apiClient.get<{ is_unique: boolean }>(`api/validate/unique?entity=Unit&property=${property}&value=${value}&id=${id}`);
    return response.data.is_unique;
  },
};

export default unitsService;
