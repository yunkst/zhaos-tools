""" 
AI Key管理相关的Pydantic模型
"""

from typing import Optional, List
from pydantic import BaseModel, Field
from datetime import datetime
from enum import Enum


class AIProviderType(str, Enum):
    """AI服务商类型枚举"""
    OPENAI = "openai"
    CLAUDE = "claude"
    QWEN = "qwen"
    BAIDU = "baidu"
    ZHIPU = "zhipu"
    KIMI = "kimi"
    CUSTOM = "custom"


class AIKeyBase(BaseModel):
    """AI Key基础模型"""
    name: str = Field(..., min_length=1, max_length=100, description="Key名称")
    provider_type: AIProviderType = Field(..., description="服务商类型")
    api_key: str = Field(..., min_length=1, description="API Key")
    base_url: Optional[str] = Field(None, max_length=500, description="服务商API地址")
    description: Optional[str] = Field(None, max_length=500, description="描述信息")
    is_active: bool = Field(True, description="是否启用")


class AIKeyCreate(AIKeyBase):
    """创建AI Key请求模型"""
    pass


class AIKeyUpdate(BaseModel):
    """更新AI Key请求模型"""
    name: Optional[str] = Field(None, min_length=1, max_length=100, description="Key名称")
    provider_type: Optional[AIProviderType] = Field(None, description="服务商类型")
    api_key: Optional[str] = Field(None, min_length=1, description="API Key")
    base_url: Optional[str] = Field(None, max_length=500, description="服务商API地址")
    description: Optional[str] = Field(None, max_length=500, description="描述信息")
    is_active: Optional[bool] = Field(None, description="是否启用")


class AIKeyResponse(BaseModel):
    """AI Key响应模型"""
    id: int
    name: str
    provider_type: AIProviderType
    api_key_masked: str = Field(..., description="脱敏后的API Key")
    base_url: Optional[str]
    description: Optional[str]
    is_active: bool
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True


class AIKeyListResponse(BaseModel):
    """AI Key列表响应模型"""
    keys: List[AIKeyResponse]
    total: int


class AIKeyDetailResponse(AIKeyResponse):
    """AI Key详情响应模型（包含完整的API Key）"""
    api_key: str = Field(..., description="完整的API Key")