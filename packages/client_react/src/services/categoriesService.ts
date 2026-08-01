import apiClient from './apiClient';
import type { 
  CategoryDto, 
  CreateCategoryDto, 
  UpdateCategoryDto, 
  CategoryTestDto, 
  UpdateCategoryTestsDto
} from '../types/category';
import type { ToggleObsoleteDto } from '../types/models';

const categoriesService = {
  async getAllCategories(): Promise<CategoryDto[]> {
    const response = await apiClient.get<CategoryDto[]>('api/categories');
    return response.data;
  },

  async getCategory(id: number): Promise<CategoryDto> {
    const response = await apiClient.get<CategoryDto>(`api/categories/${id}`);
    return response.data;
  },

  async createCategory(dto: CreateCategoryDto): Promise<{ id: number }> {
    const response = await apiClient.post<{ id: number }>('api/categories', dto);
    return response.data;
  },

  async updateCategory(id: number, dto: UpdateCategoryDto): Promise<void> {
    await apiClient.put(`api/categories/${id}`, dto);
  },

  async toggleObsolete(id: number, dto: ToggleObsoleteDto): Promise<void> {
    await apiClient.put(`api/categories/${id}/toggle_obsolete`, dto);
  },

  async getCategoryTests(id: number): Promise<CategoryTestDto[]> {
    const response = await apiClient.get<CategoryTestDto[]>(`api/categories/${id}/tests`);
    return response.data;
  },

  async updateCategoryTests(id: number, dto: UpdateCategoryTestsDto): Promise<void> {
    await apiClient.put(`api/categories/${id}/tests`, dto);
  },

  async validateUniqueness(property: string, value: string, id?: number | null): Promise<boolean> {
    let url = `api/validate/unique?entity=Category&property=${property}&value=${encodeURIComponent(value)}`;
    if (id !== undefined && id !== null) {
      url += `&id=${id}`;
    }
    const response = await apiClient.get<{ is_unique: boolean }>(url);
    return response.data.is_unique;
  }
};

export default categoriesService;
