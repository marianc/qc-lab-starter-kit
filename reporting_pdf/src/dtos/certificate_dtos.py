from pydantic import BaseModel, ConfigDict
from typing import List, Optional

class CertificateTestDto(BaseModel):
    model_config = ConfigDict(extra='allow')
    measurementId: Optional[int] = None
    hasForm: Optional[bool] = False
    nrOrd: Optional[int] = 0
    testName: Optional[str] = ""
    typeName: Optional[str] = ""
    unitName: Optional[str] = None
    value: Optional[str] = ""
    formattedValues: List[str] = []
    uncertaintyValues: List[str] = []
    testCount: Optional[int] = 0
    testFrequency: Optional[int] = 0
    noteSpec: Optional[str] = None
    isConformingSpec: Optional[bool] = True
    conformingResults: List[bool] = []
    conformingUncertaintyResults: List[bool] = []
    reportId: Optional[int] = None
    reportIsCancelled: Optional[bool] = False

class CertificateDataDto(BaseModel):
    model_config = ConfigDict(extra='allow')
    id: Optional[int] = None
    materialName: Optional[str] = None
    controlCode: Optional[str] = None
    specId: Optional[int] = None
    isConformingSpec: Optional[bool] = True
    isConformingUncertainty: Optional[bool] = True
    status: Optional[str] = None
    userSubmittedTag: Optional[str] = None
    dateSubmitted: Optional[str] = None
    commentsSubmitted: Optional[str] = None
    isSubmitted: Optional[bool] = False
    isCancelled: Optional[bool] = False
    dateCancelled: Optional[str] = None
    userCancelledTag: Optional[str] = None
    commentsCancelled: Optional[str] = None
    analysisResultMessage: Optional[str] = None
    tests: List[CertificateTestDto] = []

class QualityCertificateRequestDto(BaseModel):
    model_config = ConfigDict(extra='allow')
    report: CertificateDataDto
