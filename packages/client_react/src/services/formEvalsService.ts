import apiClient from './apiClient';
import type { 
  FormEvalDto, 
  CreateFormEvalDto, 
  UpdateFormEvalDto 
} from '../types/formEval';
import type { IdDto } from '../types/models';

const formEvalsService = {
  async getFormEvals(formId: number): Promise<FormEvalDto[]> {
    const response = await apiClient.get<FormEvalDto[]>(`api/forms/${formId}/evals`);
    return response.data;
  },

  async getFormEval(id: number): Promise<FormEvalDto> {
    const response = await apiClient.get<FormEvalDto>(`api/form-evals/${id}`);
    return response.data;
  },

  async createFormEval(dto: CreateFormEvalDto): Promise<IdDto> {
    const response = await apiClient.post<IdDto>('api/form-evals', dto);
    return response.data;
  },

  async updateFormEval(id: number, dto: UpdateFormEvalDto): Promise<void> {
    await apiClient.put(`api/form-evals/${id}`, dto);
  },

  async deleteFormEval(id: number): Promise<void> {
    await apiClient.delete(`api/form-evals/${id}`);
  },

  async calculateFormEval(id: number): Promise<FormEvalDto> {
    const response = await apiClient.post<FormEvalDto>(`api/form-evals/${id}/calculate`, null);
    return response.data;
  }
};

export default formEvalsService;
