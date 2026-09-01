export interface CertificateDto {
  id: number;
  materialName: string;
  controlCode: string;
  isConformingSpec: boolean;
  isConformingUncertainty: boolean;
  dateSubmitted: string | null;
  certificateReplacedId?: number | null;
  dateCancelled: string | null;
  isCancelled: boolean;
  isSubmitted: boolean;
  status: string;
  hasTestFromCancelledReport: boolean;
}

export interface PaginatedCertificatesDto {
  certificates: CertificateDto[];
  totalCount: number;
  pageSize: number;
  currentPage: number;
}

export interface CertificateDetailDto extends CertificateDto {
  receptionId: number;
  specId: number;
  materialId: number;
  userSubmittedTag: string | null;
  userCancelledTag: string | null;
  commentsSubmitted: string | null;
  commentsCancelled: string | null;
  tests: CertificateTestDto[];
}

export interface CertificateTestDto {
  certificateId: number;
  reportId: number;
  measurementId: number;
  hasForm: boolean;
  nrOrd: number;
  testId: number;
  typeId: number;
  typeName: string;
  idx: number;
  value: number;
  uncertaintyValue?: number | null;
  coverageFactorK?: number | null;
  displayValue: string;
  formattedValues: string[];
  uncertaintyValues: string[];
  testCount: number;
  testFrequency: number;
  noteSpec: string;
  isConformingSpec: boolean;
  isConformingUncertainty: boolean;
  conformingResults: boolean[];
  conformingUncertaintyResults: boolean[];
  testName: string;
  unitName: string | null;
  reportIsCancelled: boolean;
}

export interface GenerateCertificateDto {
  materialId: number;
  controlCodeId: number;
  userId: number;
}

export interface UpdateCertificateDto {
  isConformingSpec: boolean | null;
  isConformingUncertainty?: boolean | null;
}

export interface CertificateActionDto {
  userId: number;
  commentsSubmitted: string | null;
  commentsCancelled: string | null;
}

export interface CertificateAnalysisDto {
  analysisResult: string;
  isConformingSpec: boolean;
  isConformingUncertainty: boolean;
}
