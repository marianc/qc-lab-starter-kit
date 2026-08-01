export interface ReceptionDto {
  id: number;
  typeId: number;
  receptionTypeName: string;
  controlCodeId: number | null;
  materialName: string | null;
  controlCodeName: string | null;
  commentsSubmitted: string | null;
  categoryId: number | null;
  categoryName: string | null;
  isSubmitted: boolean;
  userSubmittedId: number | null;
  userSubmittedTag: string | null;
  dateSubmitted: string | null;
  isReceived: boolean;
  userReceivedId: number | null;
  userReceivedTag: string | null;
  dateReceived: string | null;
  commentsReceived: string | null;
  isRejected: boolean;
  userRejectedId: number | null;
  userRejectedTag: string | null;
  dateRejected: string | null;
  commentsRejected: string | null;
  reportSubmitted: boolean;
  status: string;
}

export interface ReceptionDetailDto extends ReceptionDto {
  materialId: number | null;
  applicableForms: number[];
  applicableTests: number[];
  receptionTests?: number[] | null;
}

export interface CreateReceptionDto {
  typeId: number;
  controlCodeId: number | null;
  categoryId: number | null;
  commentsSubmitted: string | null;
  materialName: string | null;
  userId: number;
}

export interface UpdateReceptionDto {
  typeId: number;
  controlCodeId: number | null;
  categoryId: number | null;
  commentsSubmitted: string | null;
  materialName: string | null;
  userId: number;
}

export interface UpdateReceptionTestsDto {
  testIds: number[];
}

export interface SubmitReceptionDto {
  userId: number;
  comments: string | null;
}

export interface ReceiveReceptionDto {
  userId: number;
  comments: string | null;
}

export interface RejectReceptionDto {
  userId: number;
  reason: string;
}

export interface CreateReportDto {
  userId: number;
  comments: string | null;
}

export interface ExpressCertificateDto {
  userId: number;
  comments: string | null;
}

export interface ExpressCertificateResultDto {
  success: boolean;
  errorMessage?: string | null;
  certificateId?: number | null;
}

export interface ReceptionTestDto {
  id: number;
  name: string;
}

export interface ReportSummaryDto {
  id: number;
  dateSubmitted: string | null;
  userSubmittedTag: string | null;
  commentsSubmitted: string | null;
  reportReplacedId: number | null;
  dateCancelled: string | null;
  userCancelledTag: string | null;
  commentsCancelled: string | null;
}

export interface ApplicableFormDto {
  id: number;
  name: string;
  isCustomized: boolean;
  customNav: string | null;
  isCancelled: boolean;
  isSubmitted: boolean;
  isValidated: boolean;
}

export interface CheckReportConflictDto {
  conflict: boolean;
}

export interface PaginatedReceptionsDto {
  receptions: ReceptionDto[];
  totalPages: number;
  currentPage: number;
  totalCount: number;
}
