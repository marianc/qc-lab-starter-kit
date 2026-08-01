import type { CertificateActionDto, CertificateAnalysisDto, CertificateDetailDto, GenerateCertificateDto, PaginatedCertificatesDto, UpdateCertificateDto } from '@/types/certificate';
import apiClient from './apiClient';

const certificatesService = {
  getAllCertificates: async (
    page: number,
    pageSize: number,
    isQCPersonnel: boolean,
    materialId?: number,
    submissionYear?: number,
    submissionMonth?: number
  ): Promise<PaginatedCertificatesDto> => {
    const params: any = {
      page,
      pageSize,
      isQCPersonnel: isQCPersonnel.toString()
    };
    if (materialId) params.materialId = materialId.toString();
    if (submissionYear) params.submissionYear = submissionYear.toString();
    if (submissionMonth) params.submissionMonth = submissionMonth.toString();

    const response = await apiClient.get<PaginatedCertificatesDto>('/api/certificates', { params });
    return response.data;
  },

  getCertificate: async (id: number): Promise<CertificateDetailDto> => {
    const response = await apiClient.get<CertificateDetailDto>(`/api/certificates/${id}`);
    return response.data;
  },

  generateCertificate: async (dto: GenerateCertificateDto): Promise<CertificateDetailDto> => {
    const response = await apiClient.post<CertificateDetailDto>('/api/certificates/generate', dto);
    return response.data;
  },

  updateCertificate: async (id: number, dto: UpdateCertificateDto): Promise<void> => {
    await apiClient.put(`/api/certificates/${id}`, dto);
  },

  hasExistingValidCertificates: async (id: number): Promise<boolean> => {
    const response = await apiClient.get<{ hasExisting: boolean }>(`/api/certificates/${id}/has_existing`);
    return response.data.hasExisting;
  },

  refreshTests: async (id: number): Promise<void> => {
    await apiClient.put(`/api/certificates/${id}/refresh_tests`);
  },

  analyzeResults: async (id: number): Promise<CertificateAnalysisDto> => {
    const response = await apiClient.get<CertificateAnalysisDto>(`/api/certificates/${id}/analyze_results`);
    return response.data;
  },

  submitCertificate: async (id: number, dto: CertificateActionDto): Promise<void> => {
    await apiClient.put(`/api/certificates/${id}/submit`, dto);
  },

  cancelCertificate: async (id: number, dto: CertificateActionDto): Promise<void> => {
    await apiClient.put(`/api/certificates/${id}/cancel`, dto);
  },

  deleteCertificate: async (id: number): Promise<void> => {
    await apiClient.delete(`/api/certificates/${id}`);
  },

  async downloadPdf(id: number): Promise<void> {
    const response = await apiClient.get(`api/certificates/${id}/pdf`, {
      responseType: 'blob'
    });
    const blob = new Blob([response.data], { type: 'application/pdf' });
    const url = window.URL.createObjectURL(blob);

    const newWindow = window.open(url, '_blank');
    if (!newWindow) {
      const link = document.createElement('a');
      link.href = url;
      link.setAttribute('download', `quality_certificate_${id}.pdf`);
      document.body.appendChild(link);
      link.click();
      link.remove();
    }
  },

  async exportExcel(params: {
    isQCPersonnel: boolean;
    materialId?: number | null;
    submissionYear?: number | null;
    submissionMonth?: number | null;
    loadedPages?: number;
  }): Promise<void> {
    const response = await apiClient.get('api/certificates/export-excel', {
      params,
      responseType: 'blob'
    });
    const blob = new Blob([response.data], { type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' });
    const url = window.URL.createObjectURL(blob);

    const link = document.createElement('a');
    link.href = url;
    link.setAttribute('download', 'quality_certificates.xlsx');
    document.body.appendChild(link);
    link.click();
    link.remove();
    window.URL.revokeObjectURL(url);
  }
  };

export default certificatesService;
