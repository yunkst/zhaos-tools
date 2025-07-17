"""
AI功能基类
"""

from abc import ABC, abstractmethod
from typing import Any, Dict, Optional, Union
from datetime import datetime
import logging

from .langfuse_client import langfuse_client, langfuse_observe
from .config import ai_config

logger = logging.getLogger(__name__)


class BaseAIFunction(ABC):
    """AI功能基类"""
    
    def __init__(self, name: str, description: str = ""):
        self.name = name
        self.description = description
        self.enabled = ai_config.enabled
    
    @abstractmethod
    async def execute(self, input_data: Dict[str, Any]) -> Dict[str, Any]:
        """执行AI功能
        
        Args:
            input_data: 输入数据
            
        Returns:
            执行结果
        """
        pass
    
    @langfuse_observe()
    async def run(self, input_data: Dict[str, Any], **kwargs) -> Dict[str, Any]:
        """运行AI功能（带观察）
        
        Args:
            input_data: 输入数据
            **kwargs: 额外参数
            
        Returns:
            执行结果
        """
        if not self.enabled:
            raise RuntimeError(f"AI功能 {self.name} 未启用")
        
        start_time = datetime.now()
        
        try:
            logger.info(f"开始执行AI功能: {self.name}")
            result = await self.execute(input_data)
            
            end_time = datetime.now()
            duration = (end_time - start_time).total_seconds()
            
            logger.info(f"AI功能 {self.name} 执行成功，耗时: {duration:.2f}秒")
            
            return {
                "success": True,
                "data": result,
                "duration": duration,
                "timestamp": end_time.isoformat()
            }
            
        except Exception as e:
            end_time = datetime.now()
            duration = (end_time - start_time).total_seconds()
            
            logger.error(f"AI功能 {self.name} 执行失败: {e}")
            
            return {
                "success": False,
                "error": str(e),
                "duration": duration,
                "timestamp": end_time.isoformat()
            }
    
    def __str__(self) -> str:
        return f"AIFunction({self.name})"
    
    def __repr__(self) -> str:
        return f"AIFunction(name='{self.name}', description='{self.description}')"