"""
数据库管理模块 - SQLite数据库连接和初始化
"""

import sqlite3
from pathlib import Path
from typing import Optional, Dict, Any, List
from contextlib import contextmanager

from app.core.config import settings
from app.core.logger import database_logger
from app.utils.exceptions import DatabaseException


class DatabaseManager:
    """数据库管理器"""
    
    def __init__(self, db_path: Optional[str] = None):
        self.db_path = db_path or str(settings.database_path)
        self.init_database()
    
    def init_database(self):
        """初始化数据库表"""
        try:
            with self.get_connection() as conn:
                cursor = conn.cursor()
                
                # 创建学生档案表
                cursor.execute('''
                    CREATE TABLE IF NOT EXISTS students (
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        name TEXT NOT NULL,
                        student_id TEXT UNIQUE NOT NULL,
                        class_name TEXT,
                        contact_info TEXT,
                        notes TEXT,
                        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                    )
                ''')
                
                # 创建打卡记录表
                cursor.execute('''
                    CREATE TABLE IF NOT EXISTS check_in_records (
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        student_id TEXT NOT NULL,
                        check_in_date DATE NOT NULL,
                        content TEXT NOT NULL,
                        auto_reply TEXT,
                        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                        FOREIGN KEY (student_id) REFERENCES students (student_id)
                    )
                ''')
                
                # 创建系统配置表
                cursor.execute('''
                    CREATE TABLE IF NOT EXISTS system_config (
                        key TEXT PRIMARY KEY,
                        value TEXT NOT NULL,
                        description TEXT,
                        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                    )
                ''')
                
                # 创建索引
                cursor.execute('''
                    CREATE INDEX IF NOT EXISTS idx_students_student_id 
                    ON students(student_id)
                ''')
                
                cursor.execute('''
                    CREATE INDEX IF NOT EXISTS idx_check_in_records_student_id 
                    ON check_in_records(student_id)
                ''')
                
                cursor.execute('''
                    CREATE INDEX IF NOT EXISTS idx_check_in_records_date 
                    ON check_in_records(check_in_date)
                ''')
                
                conn.commit()
                database_logger.info("数据库初始化完成")
                
        except Exception as e:
            database_logger.error(f"数据库初始化失败: {e}")
            raise DatabaseException(f"数据库初始化失败: {e}")
    
    @contextmanager
    def get_connection(self):
        """获取数据库连接的上下文管理器"""
        conn = None
        try:
            conn = sqlite3.connect(self.db_path)
            conn.row_factory = sqlite3.Row  # 使结果可以像字典一样访问
            yield conn
        except Exception as e:
            if conn:
                conn.rollback()
            database_logger.error(f"数据库连接错误: {e}")
            raise DatabaseException(f"数据库连接错误: {e}")
        finally:
            if conn:
                conn.close()
    
    def execute_query(self, query: str, params: tuple = ()) -> List[Dict[str, Any]]:
        """执行查询并返回结果"""
        try:
            with self.get_connection() as conn:
                cursor = conn.cursor()
                cursor.execute(query, params)
                rows = cursor.fetchall()
                return [dict(row) for row in rows]
        except Exception as e:
            database_logger.error(f"查询执行失败: {e}")
            raise DatabaseException(f"查询执行失败: {e}")
    
    def execute_update(self, query: str, params: tuple = ()) -> int:
        """执行更新操作并返回影响的行数"""
        try:
            with self.get_connection() as conn:
                cursor = conn.cursor()
                cursor.execute(query, params)
                conn.commit()
                return cursor.rowcount
        except Exception as e:
            database_logger.error(f"更新执行失败: {e}")
            raise DatabaseException(f"更新执行失败: {e}")
    
    def execute_insert(self, query: str, params: tuple = ()) -> int:
        """执行插入操作并返回新记录的ID"""
        try:
            with self.get_connection() as conn:
                cursor = conn.cursor()
                cursor.execute(query, params)
                conn.commit()
                return cursor.lastrowid
        except Exception as e:
            database_logger.error(f"插入执行失败: {e}")
            raise DatabaseException(f"插入执行失败: {e}")
    
    def backup_database(self, backup_path: Optional[str] = None) -> str:
        """备份数据库"""
        try:
            if not backup_path:
                backup_dir = settings.backup_dir
                backup_path = backup_dir / f"backup_{Path(self.db_path).stem}.db"
            
            # 复制数据库文件
            import shutil
            shutil.copy2(self.db_path, backup_path)
            
            database_logger.info(f"数据库备份完成: {backup_path}")
            return str(backup_path)
            
        except Exception as e:
            database_logger.error(f"数据库备份失败: {e}")
            raise DatabaseException(f"数据库备份失败: {e}")


# 创建全局数据库管理器实例
db_manager = DatabaseManager() 