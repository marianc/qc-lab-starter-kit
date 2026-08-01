import apiClient from './apiClient';
import type { 
  FormGroupDto, 
  CreateFormGroupDto, 
  UpdateFormGroupDto, 
  FormSummaryDto 
} from '../types/formGroup';
import type { IdDto } from '../types/models';

const formGroupsService = {
  async getAllFormGroups(): Promise<FormGroupDto[]> {
    const response = await apiClient.get<FormGroupDto[]>('api/form_groups');
    return response.data;
  },

  async getFormGroup(id: number): Promise<FormGroupDto> {
    const response = await apiClient.get<FormGroupDto>(`api/form_groups/${id}`);
    return response.data;
  },

  async createFormGroup(dto: CreateFormGroupDto): Promise<IdDto> {
    const response = await apiClient.post<IdDto>('api/form_groups', dto);
    return response.data;
  },

  async updateFormGroup(id: number, dto: UpdateFormGroupDto): Promise<void> {
    await apiClient.put(`api/form_groups/${id}`, dto);
  },

  async bulkUpdateFormGroups(dtos: UpdateFormGroupDto[]): Promise<void> {
    await apiClient.put('api/form_groups', dtos);
  },

  async deleteFormGroup(id: number): Promise<void> {
    await apiClient.delete(`api/form_groups/${id}`);
  },

  async getFormsByGroup(id: number): Promise<FormSummaryDto[]> {
    const response = await apiClient.get<FormSummaryDto[]>(`api/form_groups/${id}/forms`);
    return response.data;
  }
};

export default formGroupsService;
