import apiClient from './apiClient';
import type { 
  MeasurementTestDetailDto, 
  MeasurementParamDetailDto, 
  CreateMeasurementDto, 
  UpdateMeasurementTestBulkDto, 
  UpdateMeasurementParamDto,
  AddMeasurementTestDto
} from '../types/measurement';
import type { IdDto } from '../types/models';

const measurementsService = {
  async getMeasurementTest(id: number): Promise<MeasurementTestDetailDto> {
    const response = await apiClient.get<MeasurementTestDetailDto>(`api/measurement_tests/${id}`);
    return response.data;
  },

  async getMeasurementParam(id: number): Promise<MeasurementParamDetailDto> {
    const response = await apiClient.get<MeasurementParamDetailDto>(`api/measurement_params/${id}`);
    return response.data;
  },

  async createMeasurement(dto: CreateMeasurementDto): Promise<IdDto> {
    const response = await apiClient.post<IdDto>('api/measurements', dto);
    return response.data;
  },

  async updateMeasurementTest(id: number, dto: UpdateMeasurementTestBulkDto): Promise<void> {
    await apiClient.put(`api/measurement_tests/${id}`, dto);
  },

  async updateMeasurementParam(id: number, dto: UpdateMeasurementParamDto): Promise<void> {
    await apiClient.put(`api/measurement_params/${id}`, dto);
  },

  async deleteMeasurement(id: number): Promise<void> {
    await apiClient.delete(`api/measurements/${id}`);
  },

  async toggleReported(id: number, userId: number): Promise<void> {
    await apiClient.put(`api/measurements/${id}/toggle_reported?userId=${userId}`, null);
  },

  async addMeasurementTest(id: number, dto: AddMeasurementTestDto): Promise<IdDto> {
    const response = await apiClient.post<IdDto>(`api/measurements/${id}/tests`, dto);
    return response.data;
  }
};

export default measurementsService;
