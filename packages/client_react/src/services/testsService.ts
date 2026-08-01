import apiClient from './apiClient';
import type { 
  TestDto, 
  CreateTestDto, 
  UpdateTestDto, 
  TestEnumDto, 
  CreateTestEnumDto, 
  UpdateTestEnumDto, 
  ReorderTestDto, 
  ReorderTestEnumDto 
} from '../types/test';
import type { IdDto, ToggleObsoleteDto } from '../types/models';

const testsService = {
  async getAllTests(): Promise<TestDto[]> {
    const response = await apiClient.get<TestDto[]>('api/tests');
    return response.data;
  },

  async getTest(id: number): Promise<TestDto> {
    const response = await apiClient.get<TestDto>(`api/tests/${id}`);
    return response.data;
  },

  async createTest(dto: CreateTestDto): Promise<IdDto> {
    const response = await apiClient.post<IdDto>('api/tests', dto);
    return response.data;
  },

  async updateTest(id: number, dto: UpdateTestDto): Promise<void> {
    await apiClient.put(`api/tests/${id}`, dto);
  },

  async toggleObsolete(id: number, dto: ToggleObsoleteDto): Promise<void> {
    await apiClient.put(`api/tests/${id}/toggle_obsolete`, dto);
  },

  async reorderTests(dto: ReorderTestDto[]): Promise<void> {
    await apiClient.put('api/tests/reorder', dto);
  },

  async getTestEnums(id: number): Promise<TestEnumDto[]> {
    const response = await apiClient.get<TestEnumDto[]>(`api/tests/${id}/enums`);
    return response.data;
  },

  async addTestEnum(id: number, dto: CreateTestEnumDto): Promise<IdDto> {
    const response = await apiClient.post<IdDto>(`api/tests/${id}/enums`, dto);
    return response.data;
  },

  async updateTestEnum(id: number, enumId: number, dto: UpdateTestEnumDto): Promise<void> {
    await apiClient.put(`api/tests/${id}/enums/${enumId}`, dto);
  },

  async deleteTestEnum(id: number, enumId: number): Promise<void> {
    await apiClient.delete(`api/tests/${id}/enums/${enumId}`);
  },

  async reorderTestEnums(id: number, dto: ReorderTestEnumDto[]): Promise<void> {
    await apiClient.put(`api/tests/${id}/enums/reorder`, dto);
  },

  async validateUniqueness(property: string, value: string, id?: number | null, entity: string = "Test", scopeId?: number): Promise<boolean> {
    let url = `api/validate/unique?entity=${entity}&property=${property}&value=${encodeURIComponent(value)}`;
    if (id !== undefined && id !== null) {
      url += `&id=${id}`;
    }
    if (scopeId !== undefined) {
      url += `&scope_id=${scopeId}`;
    }
    const response = await apiClient.get<{ is_unique: boolean }>(url);
    return response.data.is_unique;
  },
};

export default testsService;
