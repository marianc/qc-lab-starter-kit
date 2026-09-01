from pydantic import BaseModel, ConfigDict
from typing import List, Optional

class SpecTestItemDto(BaseModel):
    model_config = ConfigDict(extra='allow')
    testName: Optional[str] = ""
    unitName: Optional[str] = None
    condition: Optional[str] = ""
    note: Optional[str] = None
    useUncertainty: Optional[bool] = False
    testFrequency: Optional[int] = 0

class SpecDataDto(BaseModel):
    model_config = ConfigDict(extra='allow')
    id: Optional[int] = None
    materialName: Optional[str] = None
    normName: Optional[str] = None
    status: Optional[str] = None
    userSubmittedTag: Optional[str] = None
    dateSubmitted: Optional[str] = None
    commentsSubmitted: Optional[str] = None
    isSubmitted: Optional[bool] = False
    isCancelled: Optional[bool] = False
    dateCancelled: Optional[str] = None
    userCancelledTag: Optional[str] = None
    commentsCancelled: Optional[str] = None
    tests: List[SpecTestItemDto] = []

class SpecificationRequestDto(BaseModel):
    model_config = ConfigDict(extra='allow')
    report: SpecDataDto
