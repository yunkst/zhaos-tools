"""
学生相关的Pydantic模型
"""

from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field, validator


class StudentBase(BaseModel):
    """学生基础模型"""
    name: str = Field(..., min_length=1, max_length=100, description="学生姓名")
    student_id: str = Field(..., min_length=1, max_length=50, description="学号")
    class_name: Optional[str] = Field(None, max_length=100, description="班级名称")
    contact_info: Optional[str] = Field(None, max_length=200, description="联系方式")
    notes: Optional[str] = Field(None, max_length=500, description="备注")
    
    @validator('student_id')
    def validate_student_id(cls, v):
        if not v.strip():
            raise ValueError('学号不能为空')
        return v.strip()
    
    @validator('name')
    def validate_name(cls, v):
        if not v.strip():
            raise ValueError('姓名不能为空')
        return v.strip()


class StudentCreate(StudentBase):
    """创建学生模型"""
    pass


class StudentUpdate(BaseModel):
    """更新学生模型"""
    name: Optional[str] = Field(None, min_length=1, max_length=100, description="学生姓名")
    student_id: Optional[str] = Field(None, min_length=1, max_length=50, description="学号")
    class_name: Optional[str] = Field(None, max_length=100, description="班级名称")
    contact_info: Optional[str] = Field(None, max_length=200, description="联系方式")
    notes: Optional[str] = Field(None, max_length=500, description="备注")
    
    @validator('student_id')
    def validate_student_id(cls, v):
        if v is not None and not v.strip():
            raise ValueError('学号不能为空')
        return v.strip() if v else v
    
    @validator('name')
    def validate_name(cls, v):
        if v is not None and not v.strip():
            raise ValueError('姓名不能为空')
        return v.strip() if v else v


class StudentResponse(StudentBase):
    """学生响应模型"""
    id: int
    created_at: datetime
    updated_at: datetime
    
    class Config:
        orm_mode = True


class StudentListResponse(BaseModel):
    """学生列表响应模型"""
    students: list[StudentResponse]
    total: int 