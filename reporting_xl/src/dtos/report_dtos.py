from pydantic import BaseModel, ConfigDict
from typing import List, Optional

class TestColumnDto(BaseModel):
    model_config = ConfigDict(extra='allow')
    testId: int
    name: str
    nrOrd: int

class ReportTestValueDto(BaseModel):
    model_config = ConfigDict(extra='allow')
    testId: int
    values: List[str] = []

class ReportExportRowDto(BaseModel):
    model_config = ConfigDict(extra='allow')
    reportId: int
    dateSubmitted: str
    controlCode: Optional[str] = None
    materialName: Optional[str] = None
    measurementId: int
    hasForm: bool
    testValues: List[ReportTestValueDto] = []

class SheetExportDto(BaseModel):
    model_config = ConfigDict(extra='allow')
    sheetLabel: str
    sheetTitle: str
    isCategory: bool = False
    tests: List[TestColumnDto] = []
    rows: List[ReportExportRowDto] = []

class TestingReportsExportRequestDto(BaseModel):
    model_config = ConfigDict(extra='allow')
    sheets: List[SheetExportDto] = []
