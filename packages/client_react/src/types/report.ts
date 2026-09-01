export interface ReportDto {
  id: number;
  userSubmittedTag?: string | null;
  dateSubmitted?: string | null;
  receptionTypeName: string;
  materialName?: string | null;
  controlCodeCategory?: string | null;
}

export interface PaginatedReportsDto {
  reports: ReportDto[];
  totalCount: number;
  pageSize: number;
  currentPage: number;
}

export interface ReportTestDto {
  measurementId: number;
  hasForm: boolean;
  nrOrd: number;
  testName: string;
  typeName: string;
  unitName?: string | null;
  uncertaintyValue?: number | null;
  coverageFactorK?: number | null;
  value: string;
  formattedValues: string[];
  uncertaintyValues: string[];
}

export interface ReportDetailDto {
  id: number;
  receptionId: number;
  isSubmitted: boolean;
  userSubmittedId?: number | null;
  userSubmittedTag?: string | null;
  dateSubmitted?: string | null;
  commentsSubmitted?: string | null;
  reportReplacedId?: number | null;
  isCancelled: boolean;
  userCancelledId?: number | null;
  userCancelledTag?: string | null;
  dateCancelled?: string | null;
  commentsCancelled?: string | null;
  materialName?: string | null;
  controlCode?: string | null;
  receptionTypeName?: string | null;
  isCertification: boolean;
  tests: ReportTestDto[];
}

export interface PreviewTestRowDto {
  measurementId: number;
  hasForm: boolean;
  nrOrd: number;
  testId: number;
  testName: string;
  typeName: string;
  unitName?: string | null;
  formattedValues: string[];
  uncertaintyValues: string[];
  specNote?: string | null;
  conformingResults: (boolean | null)[];
  conformingUncertaintyResults: (boolean | null)[];
}

export interface PreviewReportDto {
  receptionId: number;
  materialName?: string | null;
  controlCodeName?: string | null;
  receptionTypeName?: string | null;
  userSubmittedTag?: string | null;
  dateSubmitted?: string | null;
  commentsSubmitted?: string | null;
  isCertification: boolean;
  activeSpecId?: number | null;
  tests: PreviewTestRowDto[];
}

export interface CancelReportDto {
  userId: number;
  commentsCancelled?: string | null;
}
