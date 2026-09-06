import apiClient from '@/services/apiClient';
import type { SopDto, CreateSopWithVersionDto, UpdateSopVersionDto } from '@/types/sop';
import type { IdDto } from '@/types/models';

const sopsService = {
  async getSopsByNorm(normId: number): Promise<SopDto[]> {
    const response = await apiClient.get<SopDto[]>(`api/norms/${normId}/sops`);
    return response.data;
  },

  async getAllSops(): Promise<SopDto[]> {
    const response = await apiClient.get<SopDto[]>('api/sops');
    return response.data;
  },

  async getSop(id: number): Promise<SopDto> {
    const response = await apiClient.get<SopDto>(`api/sops/${id}`);
    return response.data;
  },

  async createSop(dto: CreateSopWithVersionDto): Promise<IdDto> {
    const response = await apiClient.post<IdDto>('api/sops', dto);
    return response.data;
  },

  async createSopVersion(sopId: number, dto: UpdateSopVersionDto): Promise<IdDto> {
    const response = await apiClient.post<IdDto>(`api/sops/${sopId}/versions`, dto);
    return response.data;
  },

  async updateSopVersion(versionId: number, dto: UpdateSopVersionDto): Promise<void> {
    await apiClient.put(`api/sop-versions/${versionId}`, dto);
  },

  async activateSopVersion(versionId: number): Promise<void> {
    await apiClient.put(`api/sop-versions/${versionId}/activate`);
  },

  async validateUniqueness(property: string, value: string, id: number = 0): Promise<boolean> {
    const response = await apiClient.get<{ is_unique: boolean }>(`api/validate/unique?entity=Sop&property=${property}&value=${encodeURIComponent(value)}&id=${id}`);
    return response.data.is_unique;
  },

  async validateVersionUniqueness(property: string, value: string, versionId: number = 0, sopId: number): Promise<boolean> {
    const response = await apiClient.get<{ is_unique: boolean }>(`api/validate/unique?entity=SopVersion&property=${property}&value=${encodeURIComponent(value)}&id=${versionId}&scope_id=${sopId}`);
    return response.data.is_unique;
  }
};

export default sopsService;
