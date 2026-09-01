export interface SpecTestEvalDto {
  id: number;
  value: number;
  result: number | null;
  expectedResult: number;
  isMatch: boolean;
  note: string | null;
}

export interface SpecTestDto {
  testId: number;
  testName: string;
  unitName: string | null;
  nrOrd: number;
  condition: string;
  note: string;
  useUncertainty: boolean;
  testFrequency: number;
  evals: SpecTestEvalDto[];
}

export interface SpecDto {
  id: number;
  materialId: number;
  materialName: string;
  normName: string | null;
  dateSubmitted: string | null;
  dateCancelled: string | null;
  isSubmitted: boolean;
  specReplacedId: number | null;
  status: string;
  // For detailed view
  userSubmittedTag: string | null;
  userCancelledTag: string | null;
  commentsSubmitted: string | null;
  commentsCancelled: string | null;
  tests?: SpecTestDto[];
  applicableTests: number[] | null;
  certifiedTests: number[] | null;
}

export interface CreateSpecDto {
  materialId: number;
  userId: number;
  commentsSubmitted: string | null;
}

export interface UpdateSpecDto {
  materialId: number;
  userId: number;
  commentsSubmitted: string | null;
}

export interface CreateSpecTestDto {
  testId: number;
  condition: string;
  note: string;
  useUncertainty: boolean;
  testFrequency: number;
  evals: SpecTestEvalDto[];
}

export interface UpdateSpecTestDto {
  condition: string;
  note: string;
  useUncertainty: boolean;
  testFrequency: number;
  evals: SpecTestEvalDto[];
}

export interface SpecActionDto {
  userId: number;
  commentsSubmitted: string | null; // for submit
  commentsCancelled: string | null; // for cancel
}
