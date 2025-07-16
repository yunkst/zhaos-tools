"""
配置管理模块 - FastAPI应用配置
"""

import os
from pathlib import Path
from typing import Dict, Any, List
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    """应用配置类"""
    
    # 应用基本信息
    APP_NAME: str = "赵老师的工具箱"
    APP_VERSION: str = "0.1.0"
    APP_DESCRIPTION: str = "为了节约工作量，减少重复劳动的工具箱，同时提升学生的教学体验"
    
    # 服务器配置
    HOST: str = "0.0.0.0"
    PORT: int = 8000
    DEBUG: bool = True
    RELOAD: bool = True
    
    # 数据库配置
    DATABASE_URL: str = "sqlite:///./zhaos_tools.db"
    DATABASE_BACKUP_DIR: str = "backups"
    
    # 日志配置
    LOG_LEVEL: str = "INFO"
    LOG_FILE: str = "zhaos-tools.log"
    LOG_FORMAT: str = "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
    
    # 前端配置
    FRONTEND_DIR: str = "fronted"
    FRONTEND_DIST_DIR: str = "fronted/dist"
    FRONTEND_DEV_PORT: int = 5173
    
    # CORS配置
    CORS_ORIGINS: List[str] = [
        "http://localhost:3000",
        "http://localhost:5173",
        "http://127.0.0.1:3000",
        "http://127.0.0.1:5173",
    ]
    
    # 自动回复配置
    AUTO_REPLY_TEMPLATES: List[str] = [
        "很棒的分享！继续保持这种学习态度！👍",
        "看到你的进步真的很开心，加油！💪",
        "学习态度很认真，为你点赞！⭐",
        "持续学习的精神值得表扬！🌟",
        "很好的学习记录，继续努力！📚",
        "学习笔记整理得很好，继续保持！📝",
        "能看到你的思考过程，很棒！🧠",
        "每天的坚持都是进步，加油！🚀",
        "学习态度值得所有同学学习！🌟",
        "继续保持这种学习热情！🔥"
    ]
    
    # Langflow 配置
    LANGFLOW_API_URL: str = "http://localhost:7860"
    LANGFLOW_FLOW_ID: str = ""
    LANGFLOW_API_KEY: str = ""
    
    # PyWinAuto 配置
    AUTOMATION_DELAY: float = 0.5
    AUTOMATION_TIMEOUT: int = 10
    
    # 备份配置
    AUTO_BACKUP_ENABLED: bool = True
    BACKUP_INTERVAL_HOURS: int = 24
    MAX_BACKUP_FILES: int = 30
    
    # 安全配置
    SECRET_KEY: str = "your-secret-key-here"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    
    class Config:
        env_file = ".env"
        case_sensitive = True
    
    @property
    def database_path(self) -> Path:
        """获取数据库文件路径"""
        return Path(self.DATABASE_URL.replace("sqlite:///", "")).resolve()
    
    @property
    def backup_dir(self) -> Path:
        """获取备份目录路径"""
        backup_dir = Path(self.DATABASE_BACKUP_DIR)
        backup_dir.mkdir(exist_ok=True)
        return backup_dir
    
    @property
    def frontend_path(self) -> Path:
        """获取前端文件路径"""
        # 优先使用构建后的文件
        dist_path = Path(self.FRONTEND_DIST_DIR)
        if dist_path.exists() and any(dist_path.iterdir()):
            return dist_path
        
        # 如果没有构建文件，返回源码目录
        frontend_path = Path(self.FRONTEND_DIR)
        if frontend_path.exists():
            return frontend_path
        
        # 如果都不存在，返回None
        return None
    
    @property
    def is_development(self) -> bool:
        """判断是否为开发模式"""
        return os.getenv('ENVIRONMENT', 'development') == 'development'
    
    @property
    def frontend_url(self) -> str:
        """获取前端URL"""
        if self.is_development:
            return f"http://localhost:{self.FRONTEND_DEV_PORT}"
        return f"http://{self.HOST}:{self.PORT}"


# 创建全局配置实例
settings = Settings() 