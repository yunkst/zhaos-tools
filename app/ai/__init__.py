"""
AI功能模块
"""

from .config import ai_config
from .langfuse_client import langfuse_client
from .base import BaseAIFunction
from .langchain_base import LangChainAIFunction
from .functions.example_ai import smart_reply_generator

__all__ = [
    "ai_config",
    "langfuse_client", 
    "BaseAIFunction",
    "LangChainAIFunction",
    "smart_reply_generator"
]


def initialize_ai_module():
    """初始化AI模块"""
    import logging
    logger = logging.getLogger(__name__)
    
    if ai_config.enabled:
        logger.info("🤖 AI功能已启用")
        
        if langfuse_client.enabled:
            logger.info("📊 Langfuse追踪已启用")
        else:
            logger.info("📊 Langfuse追踪未启用")
    else:
        logger.info("🤖 AI功能未启用")