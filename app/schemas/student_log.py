"""学生日志数据模型"""

from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field


class StudentLogBase(BaseModel):
    """学生日志基础模型"""
    student_id: str = Field(..., description="学生ID")
    title: str = Field(..., min_length=1, max_length=200, description="日志标题")
    content: str = Field(..., min_length=1, description="日志内容")


class StudentLogCreate(StudentLogBase):
    """创建学生日志模型"""
    pass


class StudentLogUpdate(BaseModel):
    """更新学生日志模型"""
    title: Optional[str] = Field(None, min_length=1, max_length=200, description="日志标题")
    content: Optional[str] = Field(None, min_length=1, description="日志内容")


class StudentLogResponse(StudentLogBase):
    """学生日志响应模型"""
    id: int = Field(..., description="日志ID")
    created_at: datetime = Field(..., description="创建时间")
    updated_at: datetime = Field(..., description="更新时间")
    
    class Config:
        from_attributes = True


class StudentLogListResponse(BaseModel):
    """学生日志列表响应模型"""
    logs: list[StudentLogResponse] = Field(..., description="日志列表")
    total: int = Field(..., description="总数量")
    page: int = Field(..., description="当前页码")
    page_size: int = Field(..., description="每页数量")