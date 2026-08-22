export interface AuditLogDto {
  id: number;
  tableName: string;
  recordKeys: Record<string, any>;
  action: string;
  oldData: string | null;
  newData: string | null;
  changedFields: string[] | null;
  userId: number;
  userTag: string;
  reasonForChange: string | null;
  timestamp: string;
  clientIp: string | null;
}

export interface PaginatedAuditLogsDto {
  auditLogs: AuditLogDto[];
  totalCount: number;
  pageSize: number;
  currentPage: number;
}
