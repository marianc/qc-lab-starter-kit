import axios from 'axios';
import type { PaginatedAuditLogsDto } from '@/types/auditLog';

const API_URL = '/api/audit_logs';

export interface AuditLogFilterParams {
  page?: number;
  pageSize?: number;
  tableName?: string | null;
  action?: string | null;
  userId?: number | null;
  startDate?: string | null;
  endDate?: string | null;
}

const auditLogsService = {
  getAuditLogs: async (params: AuditLogFilterParams): Promise<PaginatedAuditLogsDto> => {
    const response = await axios.get<PaginatedAuditLogsDto>(API_URL, { params });
    return response.data;
  }
};

export default auditLogsService;
