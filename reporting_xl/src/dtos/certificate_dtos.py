from pydantic import BaseModel, ConfigDict
from typing import List, Optional

class CertTestColumnDto(BaseModel):
    model_config = ConfigDict(extra='allow')
    testId: int
    name: str
    nrOrd: int

class CertReportTestValueDto(BaseModel):
    model_config = ConfigDict(extra='allow')
    testId: int
    values: List[str] = []

class CertExportRowDto(BaseModel):
    model_config = ConfigDict(extra='allow')
    certificateId: int
    controlCode: str
    isConforming: str # "Yes" / "No"
    dateSubmitted: str
    status: str
    measurementId: int
    hasForm: bool
    testValues: List[CertReportTestValueDto] = []

class CertSheetExportDto(BaseModel):
    model_config = ConfigDict(extra='allow')
    sheetLabel: str
    sheetTitle: str
    tests: List[CertTestColumnDto] = []
    rows: List[CertExportRowDto] = []

class QualityCertificatesExportRequestDto(BaseModel):
    model_config = ConfigDict(extra='allow')
    sheets: List[CertSheetExportDto] = []
