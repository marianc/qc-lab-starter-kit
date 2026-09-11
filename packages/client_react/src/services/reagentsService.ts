import apiClient from './apiClient';
import type { 
  ReagentDto, 
  CreateReagentDto, 
  UpdateReagentDto, 
  ReagentLotDto, 
  ReagentLotStatusDto, 
  ReagentSupplierDto,
  CreateSupplierLotDto, 
  UpdateSupplierLotDto, 
  CreateProductionLotDto, 
  UpdateProductionLotDto 
} from '@/types/reagent';
import type { IdDto } from '@/types/models';

const reagentsService = {
  getAllReagents: async (): Promise<ReagentDto[]> => {
    const response = await apiClient.get<ReagentDto[]>('/api/reagents');
    return response.data;
  },

  getReagent: async (id: number): Promise<ReagentDto> => {
    const response = await apiClient.get<ReagentDto>(`/api/reagents/${id}`);
    return response.data;
  },

  createReagent: async (dto: CreateReagentDto): Promise<IdDto> => {
    const response = await apiClient.post<IdDto>('/api/reagents', dto);
    return response.data;
  },

  updateReagent: async (id: number, dto: UpdateReagentDto): Promise<void> => {
    await apiClient.put(`/api/reagents/${id}`, dto);
  },

  toggleObsolete: async (id: number, data: { isObsolete: boolean; comments?: string }): Promise<void> => {
    await apiClient.put(`/api/reagents/${id}/toggle_obsolete`, data);
  },

  getReagentLotStatuses: async (): Promise<ReagentLotStatusDto[]> => {
    const response = await apiClient.get<ReagentLotStatusDto[]>('/api/reagents/statuses');
    return response.data;
  },

  getSuppliers: async (): Promise<ReagentSupplierDto[]> => {
    const response = await apiClient.get<ReagentSupplierDto[]>('/api/reagent_suppliers');
    return response.data;
  },

  getReagentLots: async (reagentId: number): Promise<ReagentLotDto[]> => {
    const response = await apiClient.get<ReagentLotDto[]>(`/api/reagents/${reagentId}/lots`);
    return response.data;
  },

  getAllActiveReagentLots: async (): Promise<ReagentLotDto[]> => {
    const response = await apiClient.get<ReagentLotDto[]>('/api/reagent_lots/active');
    return response.data;
  },

  getReagentLot: async (controlCodeId: number): Promise<ReagentLotDto> => {
    const response = await apiClient.get<ReagentLotDto>(`/api/reagent_lots/${controlCodeId}`);
    return response.data;
  },

  createSupplierLot: async (dto: CreateSupplierLotDto): Promise<IdDto> => {
    const response = await apiClient.post<IdDto>('/api/reagents/supplier_lots', dto);
    return response.data;
  },

  updateSupplierLot: async (controlCodeId: number, dto: UpdateSupplierLotDto): Promise<void> => {
    await apiClient.put(`/api/reagents/supplier_lots/${controlCodeId}`, dto);
  },

  createProductionLot: async (dto: CreateProductionLotDto): Promise<IdDto> => {
    const response = await apiClient.post<IdDto>('/api/reagents/production_lots', dto);
    return response.data;
  },

  updateProductionLot: async (controlCodeId: number, dto: UpdateProductionLotDto): Promise<void> => {
    await apiClient.put(`/api/reagents/production_lots/${controlCodeId}`, dto);
  },

  validateUniqueness: async (property: "Name" | "Code", value: string, id?: number): Promise<boolean> => {
    const response = await apiClient.get<{ is_unique: boolean }>('/api/validate/unique', {
      params: {
        entity: 'Material',
        property,
        value,
        id: id || undefined
      }
    });
    return response.data.is_unique;
  }
};

export default reagentsService;