import apiClient from './apiClient';
import type { 
  SpecDto, 
  CreateSpecDto, 
  UpdateSpecDto, 
  CreateSpecTestDto, 
  UpdateSpecTestDto, 
  SpecTestDto, 
  SpecActionDto 
} from '../types/specification';
import type { IdDto } from '../types/models';

const specificationsService = {
  getAllSpecs: async (userId?: number, isQCPersonnel?: boolean): Promise<SpecDto[]> => {
    const params = new URLSearchParams();
    if (userId !== undefined) params.append('userId', userId.toString());
    if (isQCPersonnel !== undefined) params.append('isQCPersonnel', isQCPersonnel.toString());
    
    const response = await apiClient.get<SpecDto[]>(`/api/specs?${params.toString()}`);
    return response.data;
  },

  getSpec: async (id: number): Promise<SpecDto> => {
    const response = await apiClient.get<SpecDto>(`/api/specs/${id}`);
    return response.data;
  },

  createSpec: async (dto: CreateSpecDto): Promise<IdDto> => {
    const response = await apiClient.post<IdDto>('/api/specs', dto);
    return response.data;
  },

  updateSpec: async (id: number, dto: UpdateSpecDto): Promise<void> => {
    await apiClient.put<void>(`/api/specs/${id}`, dto);
  },

  addSpecTest: async (id: number, dto: CreateSpecTestDto): Promise<SpecTestDto> => {
    const response = await apiClient.post<SpecTestDto>(`/api/specs/${id}/tests`, dto);
    return response.data;
  },

  updateSpecTest: async (id: number, testId: number, dto: UpdateSpecTestDto): Promise<void> => {
    await apiClient.put<void>(`/api/specs/${id}/tests/${testId}`, dto);
  },

  deleteSpecTest: async (id: number, testId: number): Promise<void> => {
    await apiClient.delete<void>(`/api/specs/${id}/tests/${testId}`);
  },

  deleteSpec: async (id: number): Promise<void> => {
    await apiClient.delete<void>(`/api/specs/${id}`);
  },

  submitSpec: async (id: number, dto: SpecActionDto): Promise<SpecDto> => {
    const response = await apiClient.put<SpecDto>(`/api/specs/${id}/submit`, dto);
    return response.data;
  },

  cancelSpec: async (id: number, dto: SpecActionDto): Promise<void> => {
    await apiClient.put<void>(`/api/specs/${id}/cancel`, dto);
  },

  duplicateSpec: async (id: number, dto: SpecActionDto): Promise<IdDto> => {
    const response = await apiClient.post<IdDto>(`/api/specs/${id}/duplicate`, dto);
    return response.data;
  },

  validateCondition: async (condition: string): Promise<void> => {
    await apiClient.post<void>('/api/specs/validate-condition', JSON.stringify(condition));
  },

  downloadPdf: async (id: number): Promise<void> => {
    const response = await apiClient.get(`api/specs/${id}/pdf`, {
      responseType: 'blob'
    });
    const blob = new Blob([response.data], { type: 'application/pdf' });
    const url = window.URL.createObjectURL(blob);

    const newWindow = window.open(url, '_blank');
    if (!newWindow) {
      const link = document.createElement('a');
      link.href = url;
      link.setAttribute('download', `specification_${id}.pdf`);
      document.body.appendChild(link);
      link.click();
      link.remove();
    }
  }
};

export default specificationsService;