"""
通用Pydantic模型 - 共用的请求和响应模型
"""

from typing import Any, Dict, Optional, List, Generic, TypeVar
from pydantic import BaseModel


T = TypeVar('T')


class ResponseModel(BaseModel, Generic[T]):
    """标准API响应模型"""
    success: bool
    message: Optional[str] = None
    data: Optional[T] = None
    error: Optional[str] = None


class PaginationModel(BaseModel):
    """分页模型"""
    page: int = 1
    page_size: int = 20
    total: int = 0
    total_pages: int = 0


class PaginatedResponse(BaseModel, Generic[T]):
    """分页响应模型"""
    success: bool
    data: Optional[T] = None
    pagination: Optional[PaginationModel] = None
    message: Optional[str] = None
    error: Optional[str] = None


class SystemInfo(BaseModel):
    """系统信息模型"""
    app_name: str
    version: str
    description: str
    python_version: str
    platform: str
    database_path: str 