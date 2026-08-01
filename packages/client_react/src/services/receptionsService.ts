import apiClient from './apiClient';
import type { 
  ReceptionDto, 
  ReceptionDetailDto, 
  CreateReceptionDto, 
  UpdateReceptionDto, 
  PaginatedReceptionsDto,
  ApplicableFormDto,
  ReceptionTestDto,
  UpdateReceptionTestsDto,
  SubmitReceptionDto,
  ReceiveReceptionDto,
  RejectReceptionDto,
  ReportSummaryDto,
  CreateReportDto,
  ExpressCertificateDto,
  ExpressCertificateResultDto
} from '../types/reception';
import type { PreviewReportDto } from '../types/report';
import type { 
  MeasurementTestDetailDto, 
  MeasurementParamDetailDto 
} from '../types/measurement';
import type { IdDto } from '../types/models';

const receptionsService = {
  async getAllReceptions(params: Record<string, any>): Promise<PaginatedReceptionsDto> {
    const response = await apiClient.get<PaginatedReceptionsDto>('api/receptions', { params });
    return response.data;
  },

  async getReception(id: number): Promise<ReceptionDetailDto> {
    const response = await apiClient.get<ReceptionDetailDto>(`api/receptions/${id}`);
    return response.data;
  },

  async createReception(dto: CreateReceptionDto): Promise<IdDto> {
    const response = await apiClient.post<IdDto>('api/receptions', dto);
    return response.data;
  },

  async updateReception(id: number, dto: UpdateReceptionDto): Promise<void> {
    await apiClient.put(`api/receptions/${id}`, dto);
  },

  async getApplicableForms(id: number): Promise<ApplicableFormDto[]> {
    const response = await apiClient.get<ApplicableFormDto[]>(`api/receptions/${id}/applicable_forms`);
    return response.data;
  },

  async getReceptionTests(id: number): Promise<ReceptionTestDto[]> {
    const response = await apiClient.get<ReceptionTestDto[]>(`api/receptions/${id}/tests`);
    return response.data;
  },

  async updateReceptionTests(id: number, dto: UpdateReceptionTestsDto): Promise<void> {
    await apiClient.put(`api/receptions/${id}/tests`, dto);
  },

  async submitReception(id: number, dto: SubmitReceptionDto): Promise<void> {
    await apiClient.put(`api/receptions/${id}/submit`, dto);
  },

  async cancelSubmission(id: number): Promise<void> {
    await apiClient.put(`api/receptions/${id}/cancel_submission`, {});
  },

  async receiveReception(id: number, dto: ReceiveReceptionDto): Promise<void> {
    await apiClient.put(`api/receptions/${id}/receive`, dto);
  },

  async rejectReception(id: number, dto: RejectReceptionDto): Promise<void> {
    await apiClient.put(`api/receptions/${id}/reject`, dto);
  },

  async getReceptionReports(id: number): Promise<ReportSummaryDto[]> {
    const response = await apiClient.get<ReportSummaryDto[]>(`api/receptions/${id}/reports`);
    return response.data;
  },

  async createReport(id: number, dto: CreateReportDto): Promise<IdDto> {
    const response = await apiClient.post<IdDto>(`api/receptions/${id}/create_report`, dto);
    return response.data;
  },

  async checkReportConflict(id: number): Promise<boolean> {
    const response = await apiClient.get<{ conflict: boolean }>(`api/receptions/${id}/check_report_conflict`);
    return response.data.conflict;
  },

  async getMeasurementTests(id: number): Promise<MeasurementTestDetailDto[]> {
    const response = await apiClient.get<MeasurementTestDetailDto[]>(`api/receptions/${id}/measurement_tests`);
    return response.data;
  },

  async getMeasurementParams(id: number): Promise<MeasurementParamDetailDto[]> {
    const response = await apiClient.get<MeasurementParamDetailDto[]>(`api/receptions/${id}/measurement_params`);
    return response.data;
  },

  async getPreviewReport(id: number): Promise<PreviewReportDto> {
    const response = await apiClient.get<PreviewReportDto>(`api/receptions/${id}/preview`);
    return response.data;
  },

  async submitExpressCertificate(id: number, dto: ExpressCertificateDto): Promise<ExpressCertificateResultDto> {
    const response = await apiClient.post<ExpressCertificateResultDto>(`api/receptions/${id}/submit_express_certificate`, dto);
    return response.data;
  }
};

export default receptionsService;
