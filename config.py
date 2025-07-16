"""
应用配置文件
"""

import os
from pathlib import Path
from typing import Dict, Any


class Config:
    """应用配置类"""
    
    # 应用基本信息
    APP_NAME = "赵老师的工具箱"
    APP_VERSION = "0.1.0"
    APP_DESCRIPTION = "为了节约工作量，减少重复劳动的工具箱，同时提升学生的教学体验"
    
    # 数据库配置
    DATABASE_PATH = "zhaos_tools.db"
    DATABASE_BACKUP_DIR = "backups"
    
    # 日志配置
    LOG_LEVEL = "INFO"
    LOG_FILE = "zhaos-tools.log"
    LOG_FORMAT = "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
    
    # 窗口配置
    WINDOW_WIDTH = 1200
    WINDOW_HEIGHT = 800
    WINDOW_MIN_WIDTH = 800
    WINDOW_MIN_HEIGHT = 600
    WINDOW_RESIZABLE = True
    
    # 前端配置
    FRONTEND_DIR = "fronted"
    FRONTEND_DIST_DIR = "fronted/dist"
    FRONTEND_DEV_PORT = 5173
    
    # 自动回复配置
    AUTO_REPLY_TEMPLATES = [
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
    
    # Langflow 配置（待实现）
    LANGFLOW_API_URL = "http://localhost:7860"
    LANGFLOW_FLOW_ID = ""
    LANGFLOW_API_KEY = ""
    
    # PyWinAuto 配置
    AUTOMATION_DELAY = 0.5  # 自动化操作间隔时间（秒）
    AUTOMATION_TIMEOUT = 10  # 自动化操作超时时间（秒）
    
    # 备份配置
    AUTO_BACKUP_ENABLED = True
    BACKUP_INTERVAL_HOURS = 24
    MAX_BACKUP_FILES = 30
    
    @classmethod
    def get_database_path(cls) -> Path:
        """获取数据库文件路径"""
        return Path(cls.DATABASE_PATH).resolve()
    
    @classmethod
    def get_backup_dir(cls) -> Path:
        """获取备份目录路径"""
        backup_dir = Path(cls.DATABASE_BACKUP_DIR)
        backup_dir.mkdir(exist_ok=True)
        return backup_dir
    
    @classmethod
    def get_frontend_path(cls) -> Path:
        """获取前端文件路径"""
        # 优先使用构建后的文件
        dist_path = Path(cls.FRONTEND_DIST_DIR)
        if dist_path.exists() and any(dist_path.iterdir()):
            return dist_path
        
        # 如果没有构建文件，返回源码目录
        frontend_path = Path(cls.FRONTEND_DIR)
        if frontend_path.exists():
            return frontend_path
        
        # 如果都不存在，返回None
        return None
    
    @classmethod
    def get_log_config(cls) -> Dict[str, Any]:
        """获取日志配置"""
        return {
            'level': cls.LOG_LEVEL,
            'format': cls.LOG_FORMAT,
            'handlers': [
                {
                    'type': 'file',
                    'filename': cls.LOG_FILE
                },
                {
                    'type': 'console'
                }
            ]
        }
    
    @classmethod
    def get_window_config(cls) -> Dict[str, Any]:
        """获取窗口配置"""
        return {
            'title': cls.APP_NAME,
            'width': cls.WINDOW_WIDTH,
            'height': cls.WINDOW_HEIGHT,
            'min_size': (cls.WINDOW_MIN_WIDTH, cls.WINDOW_MIN_HEIGHT),
            'resizable': cls.WINDOW_RESIZABLE
        }
    
    @classmethod
    def is_development_mode(cls) -> bool:
        """判断是否为开发模式"""
        return os.getenv('ZHAOS_TOOLS_ENV', 'production') == 'development'
    
    @classmethod
    def get_frontend_url(cls) -> str:
        """获取前端URL"""
        if cls.is_development_mode():
            return f"http://localhost:{cls.FRONTEND_DEV_PORT}"
        
        frontend_path = cls.get_frontend_path()
        if frontend_path:
            return str(frontend_path)
        
        return ""


class DatabaseConfig:
    """数据库配置"""
    
    # 学生表字段
    STUDENT_FIELDS = [
        'id', 'name', 'student_id', 'class_name', 
        'contact_info', 'notes', 'created_at', 'updated_at'
    ]
    
    # 打卡记录表字段
    CHECK_IN_FIELDS = [
        'id', 'student_id', 'check_in_date', 'content', 
        'auto_reply', 'created_at'
    ]
    
    # 系统配置表字段
    SYSTEM_CONFIG_FIELDS = [
        'key', 'value', 'description', 'updated_at'
    ]


class UIConfig:
    """UI配置"""
    
    # 主题色彩
    PRIMARY_COLOR = "#409EFF"
    SUCCESS_COLOR = "#67C23A"
    WARNING_COLOR = "#E6A23C"
    DANGER_COLOR = "#F56C6C"
    INFO_COLOR = "#909399"
    
    # 页面配置
    PAGE_SIZE = 20
    MAX_PAGE_SIZE = 100
    
    # 表格配置
    TABLE_ROW_HEIGHT = 48
    TABLE_HEADER_HEIGHT = 56


# 导出配置实例
config = Config()
db_config = DatabaseConfig()
ui_config = UIConfig() 