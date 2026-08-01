import apiClient from './apiClient';
import type { NormDto, CreateNormDto, UpdateNormDto } from '../types/norm';
import type { IdDto, ToggleObsoleteDto } from '../types/models';

const normsService = {
  async getAllNorms(): Promise<NormDto[]> {
    const response = await apiClient.get<NormDto[]>('api/norms');
    return response.data;
  },

  async getNorm(id: number): Promise<NormDto> {
    const response = await apiClient.get<NormDto>(`api/norms/${id}`);
    return response.data;
  },

  async createNorm(dto: CreateNormDto): Promise<IdDto> {
    const response = await apiClient.post<IdDto>('api/norms', dto);
    return response.data;
  },

  async updateNorm(id: number, dto: UpdateNormDto): Promise<void> {
    await apiClient.put(`api/norms/${id}`, dto);
  },

  async toggleObsolete(id: number, dto: ToggleObsoleteDto): Promise<void> {
    await apiClient.put(`api/norms/${id}/toggle_obsolete`, dto);
  },

  async validateUniqueness(property: string, value: string, id: number): Promise<boolean> {
    const response = await apiClient.get<{ is_unique: boolean }>(`api/validate/unique?entity=Norm&property=${property}&value=${encodeURIComponent(value)}&id=${id}`);
    return response.data.is_unique;
  }
};

export default normsService;