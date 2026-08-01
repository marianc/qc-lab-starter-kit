import apiClient from './apiClient';
import type { 
  FormDto, 
  FormDetailDto, 
  CreateFormDto, 
  UpdateFormDto, 
  FormParamDto, 
  ReorderFormParamDto, 
  BatchUpdateFormParamDto, 
  CreateFormParamDto, 
  UpdateFormParamDto, 
  FormActionDto 
} from '../types/form';
import type { IdDto } from '../types/models';

const formsService = {
  async getAllForms(): Promise<FormDto[]> {
    const response = await apiClient.get<FormDto[]>('api/forms');
    return response.data;
  },

  async getForm(id: number): Promise<FormDetailDto> {
    const response = await apiClient.get<FormDetailDto>(`api/forms/${id}`);
    return response.data;
  },

  async createForm(dto: CreateFormDto): Promise<IdDto> {
    const response = await apiClient.post<IdDto>('api/forms', dto);
    return response.data;
  },

  async updateForm(id: number, dto: UpdateFormDto): Promise<void> {
    await apiClient.put(`api/forms/${id}`, dto);
  },

  async getFormParams(id: number): Promise<FormParamDto[]> {
    const response = await apiClient.get<FormParamDto[]>(`api/forms/${id}/params`);
    return response.data;
  },

  async reorderFormParams(id: number, reorderedParams: ReorderFormParamDto[]): Promise<void> {
    await apiClient.put(`api/forms/${id}/params/reorder`, reorderedParams);
  },

  async batchUpdateFormParams(id: number, paramsData: BatchUpdateFormParamDto[]): Promise<void> {
    await apiClient.put(`api/forms/${id}/params/batch-update`, paramsData);
  },

  async addFormParam(id: number, dto: CreateFormParamDto): Promise<IdDto> {
    const response = await apiClient.post<IdDto>(`api/forms/${id}/params`, dto);
    return response.data;
  },

  async updateFormParam(id: number, testId: number, dto: UpdateFormParamDto): Promise<void> {
    await apiClient.put(`api/forms/${id}/params/${testId}`, dto);
  },

  async deleteFormParam(id: number, testId: number): Promise<void> {
    await apiClient.delete(`api/forms/${id}/params/${testId}`);
  },

  async submitForm(id: number, dto: FormActionDto): Promise<void> {
    await apiClient.put(`api/forms/${id}/submit`, dto);
  },

  async validateForm(id: number, dto: FormActionDto): Promise<void> {
    await apiClient.put(`api/forms/${id}/validate`, dto);
  },

  async cancelForm(id: number, dto: FormActionDto): Promise<void> {
    await apiClient.put(`api/forms/${id}/cancel`, dto);
  },

  async reactivateForm(id: number): Promise<void> {
    await apiClient.put(`api/forms/${id}/reactivate`, {});
  },

  async duplicateForm(id: number, dto: FormActionDto): Promise<IdDto> {
    const response = await apiClient.post<IdDto>(`api/forms/${id}/duplicate`, dto);
    return response.data;
  },

  async validateFormula(formId: number, testId: number, isCalculated: boolean, formula: string | null): Promise<void> {
    const url = `api/validate/formula?formId=${formId}&testId=${testId}&isCalculated=${isCalculated}&formula=${encodeURIComponent(formula ?? "")}`;
    const response = await apiClient.get<{ valid: boolean; msg?: string }>(url);
    if (!response.data.valid) {
      throw new Error(response.data.msg ?? "Invalid formula.");
    }
  },

  async validateCondition(condition: string): Promise<void> {
    await apiClient.post<void>('api/forms/validate-condition', JSON.stringify(condition));
  }
};

export default formsService;
