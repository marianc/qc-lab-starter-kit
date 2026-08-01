from pydantic import BaseModel, ConfigDict
from typing import List, Optional

class ReportTestDto(BaseModel):
    model_config = ConfigDict(extra='allow')
    measurementId: Optional[int] = None
    hasForm: Optional[bool] = False
    nrOrd: Optional[int] = 0
    testName: Optional[str] = ""
    typeName: Optional[str] = ""
    unitName: Optional[str] = None
    value: Optional[str] = ""
    formattedValues: List[str] = []

class ReportDataDto(BaseModel):
    model_config = ConfigDict(extra='allow')
    id: Optional[int] = None
    receptionTypeName: Optional[str] = None
    materialName: Optional[str] = None
    controlCode: Optional[str] = None
    receptionId: Optional[int] = None
    userSubmittedTag: Optional[str] = None
    dateSubmitted: Optional[str] = None
    commentsSubmitted: Optional[str] = None
    reportReplacedId: Optional[int] = None
    isSubmitted: Optional[bool] = False
    isCancelled: Optional[bool] = False
    dateCancelled: Optional[str] = None
    userCancelledTag: Optional[str] = None
    commentsCancelled: Optional[str] = None
    tests: List[ReportTestDto] = []

class TestingReportRequestDto(BaseModel):
    model_config = ConfigDict(extra='allow')
    report: ReportDataDto
