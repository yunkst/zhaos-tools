"""
配置管理相关的Pydantic模型
"""

from typing import Optional, List, Any
from pydantic import BaseModel, Field
from datetime import datetime


class ConfigBase(BaseModel):
    """配置基础模型"""
    key: str = Field(..., min_length=1, max_length=100, description="配置键")
    value: str = Field(..., description="配置值")
    description: Optional[str] = Field(None, max_length=500, description="配置描述")


class ConfigCreate(ConfigBase):
    """创建配置请求模型"""
    pass


class ConfigUpdate(BaseModel):
    """更新配置请求模型"""
    value: str = Field(..., description="配置值")
    description: Optional[str] = Field(None, max_length=500, description="配置描述")


class ConfigResponse(ConfigBase):
    """配置响应模型"""
    updated_at: datetime
    
    class Config:
        from_attributes = True


class ConfigListResponse(BaseModel):
    """配置列表响应模型"""
    configs: List[ConfigResponse]
    total: int


class ConfigGroupResponse(BaseModel):
    """配置分组响应模型"""
    group_name: str
    configs: List[ConfigResponse]


class ConfigBatchUpdate(BaseModel):
    """批量更新配置请求模型"""
    configs: List[ConfigCreate] = Field(..., description="配置列表")