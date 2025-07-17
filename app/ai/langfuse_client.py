"""
Langfuse客户端模块
"""

from typing import Optional, Dict, Any
from functools import wraps
import logging

try:
    from langfuse import Langfuse
    from langfuse.decorators import observe
    LANGFUSE_AVAILABLE = True
except ImportError:
    LANGFUSE_AVAILABLE = False
    observe = lambda **kwargs: lambda func: func  # 空装饰器

from .config import ai_config

logger = logging.getLogger(__name__)


class LangfuseClient:
    """Langfuse客户端封装"""
    
    def __init__(self):
        self._client: Optional[Langfuse] = None
        self._enabled = False
        self._initialize()
    
    def _initialize(self):
        """初始化Langfuse客户端"""
        if not LANGFUSE_AVAILABLE:
            logger.warning("Langfuse未安装，跳过初始化")
            return
        
        if not ai_config.should_enable_langfuse:
            logger.info("Langfuse未启用或配置不完整")
            return
        
        try:
            self._client = Langfuse(
                secret_key=ai_config.langfuse_secret_key,
                public_key=ai_config.langfuse_public_key,
                host=ai_config.langfuse_host
            )
            self._enabled = True
            logger.info("✅ Langfuse客户端初始化成功")
        except Exception as e:
            logger.error(f"❌ Langfuse客户端初始化失败: {e}")
    
    @property
    def enabled(self) -> bool:
        """是否启用"""
        return self._enabled
    
    @property
    def client(self) -> Optional[Langfuse]:
        """获取客户端实例"""
        return self._client
    
    def trace(self, name: str, **kwargs):
        """创建trace"""
        if self._enabled and self._client:
            return self._client.trace(name=name, **kwargs)
        return None
    
    def generation(self, trace_id: str, name: str, **kwargs):
        """创建generation"""
        if self._enabled and self._client:
            return self._client.generation(
                trace_id=trace_id, 
                name=name, 
                **kwargs
            )
        return None
    
    def flush(self):
        """刷新数据"""
        if self._enabled and self._client:
            self._client.flush()


# 全局实例
langfuse_client = LangfuseClient()


def langfuse_observe(name: str = None, **kwargs):
    """Langfuse观察装饰器"""
    def decorator(func):
        if langfuse_client.enabled and LANGFUSE_AVAILABLE:
            return observe(name=name or func.__name__, **kwargs)(func)
        else:
            # 如果Langfuse未启用，返回原函数
            @wraps(func)
            def wrapper(*args, **kwargs):
                return func(*args, **kwargs)
            return wrapper
    return decorator