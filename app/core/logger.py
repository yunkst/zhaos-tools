"""
日志管理模块 - 统一的日志配置
"""

import logging
import sys
from pathlib import Path
from typing import Optional

from app.core.config import settings


def setup_logger(
    name: str,
    level: Optional[str] = None,
    log_file: Optional[str] = None
) -> logging.Logger:
    """设置日志记录器"""
    
    logger = logging.getLogger(name)
    
    # 如果已经配置过，直接返回
    if logger.handlers:
        return logger
    
    # 设置日志级别
    log_level = level or settings.LOG_LEVEL
    logger.setLevel(getattr(logging, log_level.upper()))
    
    # 创建格式化器
    formatter = logging.Formatter(settings.LOG_FORMAT)
    
    # 控制台处理器
    console_handler = logging.StreamHandler(sys.stdout)
    console_handler.setFormatter(formatter)
    logger.addHandler(console_handler)
    
    # 文件处理器
    if log_file or settings.LOG_FILE:
        file_path = Path(log_file or settings.LOG_FILE)
        file_handler = logging.FileHandler(file_path, encoding='utf-8')
        file_handler.setFormatter(formatter)
        logger.addHandler(file_handler)
    
    return logger


# 创建应用主日志记录器
app_logger = setup_logger("zhaos_tools")

# 创建各模块的日志记录器
database_logger = setup_logger("zhaos_tools.database")
api_logger = setup_logger("zhaos_tools.api")
service_logger = setup_logger("zhaos_tools.service")
utils_logger = setup_logger("zhaos_tools.utils") 