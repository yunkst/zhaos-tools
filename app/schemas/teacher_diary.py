from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel, Field


class TeacherDiaryBase(BaseModel):
    """教师日记基础模型"""
    title: str = Field(..., description="日记标题")
    content: str = Field(..., description="日记内容")
    markdown_content: Optional[str] = Field(None, description="Markdown格式内容")
    images: Optional[str] = Field(None, description="图片信息，JSON字符串")
    tags: Optional[str] = Field(None, description="标签，逗号分隔")


class TeacherDiaryCreate(TeacherDiaryBase):
    """创建教师日记模型"""
    pass


class TeacherDiaryUpdate(BaseModel):
    """更新教师日记模型"""
    title: Optional[str] = Field(None, description="日记标题")
    content: Optional[str] = Field(None, description="日记内容")
    markdown_content: Optional[str] = Field(None, description="Markdown格式内容")
    images: Optional[str] = Field(None, description="图片信息，JSON字符串")
    tags: Optional[str] = Field(None, description="标签，逗号分隔")


class TeacherDiaryResponse(TeacherDiaryBase):
    """教师日记响应模型"""
    id: int
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class TeacherDiaryListResponse(BaseModel):
    """教师日记列表响应模型"""
    diaries: List[TeacherDiaryResponse]
    total: int
    page: int
    page_size: int
    total_pages: int