import apiClient from './apiClient';
import type { 
  MaterialDto, 
  CreateMaterialDto, 
  UpdateMaterialDto, 
  MaterialTestDto, 
  UpdateMaterialTestsDto,
  MaterialControlCodeDto
} from '../types/material';
import type { IdDto, ToggleObsoleteDto } from '../types/models';

const materialsService = {
  async getAllMaterials(): Promise<MaterialDto[]> {
    const response = await apiClient.get<MaterialDto[]>('api/materials');
    return response.data;
  },

  async getMaterialsWithValidSpec(): Promise<MaterialDto[]> {
    const response = await apiClient.get<MaterialDto[]>('api/materials/with_valid_spec');
    return response.data;
  },

  async getMaterial(id: number): Promise<MaterialDto> {
    const response = await apiClient.get<MaterialDto>(`api/materials/${id}`);
    return response.data;
  },

  async createMaterial(dto: CreateMaterialDto): Promise<IdDto> {
    const response = await apiClient.post<IdDto>('api/materials', dto);
    return response.data;
  },

  async updateMaterial(id: number, dto: UpdateMaterialDto): Promise<void> {
    await apiClient.put(`api/materials/${id}`, dto);
  },

  async toggleObsolete(id: number, dto: ToggleObsoleteDto): Promise<void> {
    await apiClient.put(`api/materials/${id}/toggle_obsolete`, dto);
  },

  async getMaterialTests(id: number): Promise<MaterialTestDto[]> {
    const response = await apiClient.get<MaterialTestDto[]>(`api/materials/${id}/tests`);
    return response.data;
  },

  async updateMaterialTests(id: number, dto: UpdateMaterialTestsDto): Promise<void> {
    await apiClient.put(`api/materials/${id}/tests`, dto);
  },

  async getControlCodes(id: number): Promise<MaterialControlCodeDto[]> {
    const response = await apiClient.get<MaterialControlCodeDto[]>(`api/materials/${id}/control_codes`);
    return response.data;
  },

  async getControlCodesForCertificate(id: number): Promise<MaterialControlCodeDto[]> {
    const response = await apiClient.get<MaterialControlCodeDto[]>(`api/materials/${id}/control_codes_for_certificate`);
    return response.data;
  },

  async validateUniqueness(property: string, value: string, id: number): Promise<boolean> {
    const response = await apiClient.get<{ is_unique: boolean }>(`api/validate/unique?entity=Material&property=${property}&value=${value}&id=${id}`);
    return response.data.is_unique;
  },
};

export default materialsService;
