import apiClient from './apiClient';
import type { 
  PaginatedReportsDto, 
  ReportDetailDto, 
  CancelReportDto 
} from '../types/report';

const reportsService = {
  async getAllReports(params: {
    page: number;
    pageSize: number;
    userId: number;
    receptionTypeId?: number | null;
    materialId?: number | null;
    submissionYear?: number | null;
    submissionMonth?: number | null;
  }): Promise<PaginatedReportsDto> {
    const response = await apiClient.get<PaginatedReportsDto>('api/reports', { params });
    return response.data;
  },

  async getReport(id: number): Promise<ReportDetailDto> {
    const response = await apiClient.get<ReportDetailDto>(`api/reports/${id}`);
    return response.data;
  },

  async cancelReport(id: number, dto: CancelReportDto): Promise<void> {
    await apiClient.put(`api/reports/${id}/cancel`, dto);
  },

  async checkReportConflict(id: number): Promise<boolean> {
    const response = await apiClient.get<{ conflict: boolean }>(`api/reports/${id}/check_conflict`);
    return response.data.conflict;
  },

  async downloadPdf(id: number): Promise<void> {
    const response = await apiClient.get(`api/reports/${id}/pdf`, {
      responseType: 'blob'
    });
    const blob = new Blob([response.data], { type: 'application/pdf' });
    const url = window.URL.createObjectURL(blob);
    
    // Open in new tab or trigger download
    const newWindow = window.open(url, '_blank');
    if (!newWindow) {
      // Fallback to download if popup blocked
      const link = document.createElement('a');
      link.href = url;
      link.setAttribute('download', `testing_report_${id}.pdf`);
      document.body.appendChild(link);
      link.click();
      link.remove();
    }
  },

  async exportExcel(params: {
    receptionTypeId?: number | null;
    materialId?: number | null;
    submissionYear?: number | null;
    submissionMonth?: number | null;
    loadedPages?: number;
  }): Promise<void> {
    const response = await apiClient.get('api/reports/export-excel', {
      params,
      responseType: 'blob'
    });
    const blob = new Blob([response.data], { type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' });
    const url = window.URL.createObjectURL(blob);
    
    const link = document.createElement('a');
    link.href = url;
    link.setAttribute('download', 'testing_reports.xlsx');
    document.body.appendChild(link);
    link.click();
    link.remove();
    window.URL.revokeObjectURL(url);
  }
};

export default reportsService;
