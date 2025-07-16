"""
班级相关的Pydantic模型
"""

from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field


class ClassBase(BaseModel):
    """班级基础模型"""
    name: str = Field(..., min_length=1, max_length=100, description="班级名称")
    description: Optional[str] = Field(None, max_length=500, description="班级描述")
    grade: Optional[str] = Field(None, max_length=50, description="年级")
    teacher_name: Optional[str] = Field(None, max_length=100, description="班主任姓名")


class ClassCreate(ClassBase):
    """创建班级模型"""
    pass


class ClassUpdate(BaseModel):
    """更新班级模型"""
    name: Optional[str] = Field(None, min_length=1, max_length=100, description="班级名称")
    description: Optional[str] = Field(None, max_length=500, description="班级描述")
    grade: Optional[str] = Field(None, max_length=50, description="年级")
    teacher_name: Optional[str] = Field(None, max_length=100, description="班主任姓名")


class ClassResponse(ClassBase):
    """班级响应模型"""
    id: int
    student_count: int = Field(default=0, description="学生人数")
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True


class ClassListResponse(BaseModel):
    """班级列表响应模型"""
    classes: list[ClassResponse]
    total: int
    page: int
    page_size: int
    total_pages: int 