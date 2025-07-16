"""
打卡相关的Pydantic模型
"""

from datetime import datetime, date
from typing import Optional
from pydantic import BaseModel, Field, validator


class CheckInBase(BaseModel):
    """打卡基础模型"""
    student_id: str = Field(..., min_length=1, max_length=50, description="学生学号")
    check_in_date: date = Field(..., description="打卡日期")
    content: str = Field(..., min_length=1, max_length=1000, description="打卡内容")
    
    @validator('student_id')
    def validate_student_id(cls, v):
        if not v.strip():
            raise ValueError('学生学号不能为空')
        return v.strip()
    
    @validator('content')
    def validate_content(cls, v):
        if not v.strip():
            raise ValueError('打卡内容不能为空')
        return v.strip()


class CheckInCreate(CheckInBase):
    """创建打卡记录模型"""
    pass


class CheckInUpdate(BaseModel):
    """更新打卡记录模型"""
    student_id: Optional[str] = Field(None, min_length=1, max_length=50, description="学生学号")
    check_in_date: Optional[date] = Field(None, description="打卡日期")
    content: Optional[str] = Field(None, min_length=1, max_length=1000, description="打卡内容")
    auto_reply: Optional[str] = Field(None, max_length=500, description="自动回复")
    
    @validator('student_id')
    def validate_student_id(cls, v):
        if v is not None and not v.strip():
            raise ValueError('学生学号不能为空')
        return v.strip() if v else v
    
    @validator('content')
    def validate_content(cls, v):
        if v is not None and not v.strip():
            raise ValueError('打卡内容不能为空')
        return v.strip() if v else v


class CheckInResponse(CheckInBase):
    """打卡记录响应模型"""
    id: int
    auto_reply: Optional[str] = None
    created_at: datetime
    
    class Config:
        orm_mode = True


class CheckInWithStudentResponse(CheckInResponse):
    """包含学生信息的打卡记录响应模型"""
    student_name: Optional[str] = None


class CheckInListResponse(BaseModel):
    """打卡记录列表响应模型"""
    records: list[CheckInWithStudentResponse]
    total: int


class AutoReplyRequest(BaseModel):
    """自动回复请求模型"""
    content: str = Field(..., min_length=1, max_length=1000, description="打卡内容")
    
    @validator('content')
    def validate_content(cls, v):
        if not v.strip():
            raise ValueError('内容不能为空')
        return v.strip()


class AutoReplyResponse(BaseModel):
    """自动回复响应模型"""
    reply: str 