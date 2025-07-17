"""
AI功能配置模块
"""

from typing import Optional
from pydantic import BaseModel
from app.core.config import settings


class AIConfig(BaseModel):
    """AI配置类"""
    
    enabled: bool = settings.AI_ENABLED
    openai_api_key: str = settings.OPENAI_API_KEY
    openai_base_url: str = settings.OPENAI_BASE_URL
    
    # Langfuse配置
    langfuse_enabled: bool = settings.LANGFUSE_ENABLED
    langfuse_secret_key: str = settings.LANGFUSE_SECRET_KEY
    langfuse_public_key: str = settings.LANGFUSE_PUBLIC_KEY
    langfuse_host: str = settings.LANGFUSE_HOST
    
    @property
    def is_langfuse_configured(self) -> bool:
        """检查Langfuse是否已配置"""
        return bool(
            self.langfuse_secret_key and 
            self.langfuse_public_key and 
            self.langfuse_host
        )
    
    @property
    def should_enable_langfuse(self) -> bool:
        """是否应该启用Langfuse"""
        return self.langfuse_enabled and self.is_langfuse_configured


ai_config = AIConfig()