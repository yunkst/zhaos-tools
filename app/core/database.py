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
                        gender TEXT,
                        age INTEGER,
                        class_id INTEGER,
                        class_name TEXT,
                        phone TEXT,
                        email TEXT,
                        qq TEXT,
                        wechat TEXT,
                        address TEXT,
                        father_job TEXT,
                        mother_job TEXT,
                        contact_info TEXT,
                        notes TEXT,
                        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                        FOREIGN KEY (class_id) REFERENCES classes (id)
                    )
                ''')
                
                # 创建班级表
                cursor.execute('''
                    CREATE TABLE IF NOT EXISTS classes (
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        name TEXT NOT NULL UNIQUE,
                        description TEXT,
                        grade TEXT,
                        teacher_name TEXT,
                        student_count INTEGER DEFAULT 0,
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
                
                # 创建回复模板表
                cursor.execute('''
                    CREATE TABLE IF NOT EXISTS reply_templates (
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        template TEXT NOT NULL UNIQUE,
                        is_custom INTEGER DEFAULT 1,
                        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                    )
                ''')
                
                # 检查是否需要迁移现有数据
                self._migrate_database(cursor)
                
                conn.commit()
                database_logger.info("数据库初始化完成")
                
        except sqlite3.Error as e:
            database_logger.error(f"数据库初始化失败: {e}")
            raise DatabaseException(f"数据库初始化失败: {e}")
    
    def _migrate_database(self, cursor):
        """数据库迁移"""
        try:
            # 检查students表是否需要添加新字段
            cursor.execute("PRAGMA table_info(students)")
            columns = [column[1] for column in cursor.fetchall()]
            
            new_columns = [
                ('gender', 'TEXT'),
                ('age', 'INTEGER'),
                ('class_id', 'INTEGER'),
                ('phone', 'TEXT'),
                ('email', 'TEXT'),
                ('qq', 'TEXT'),
                ('wechat', 'TEXT'),
                ('address', 'TEXT'),
                ('father_job', 'TEXT'),
                ('mother_job', 'TEXT'),
                ('contact_info', 'TEXT'),
                ('notes', 'TEXT'),
                # Excel表格中的新字段
                ('chinese_score', 'REAL'),
                ('math_score', 'REAL'),
                ('english_score', 'REAL'),
                ('science_score', 'REAL'),
                ('total_score', 'REAL'),
                ('id_card', 'TEXT'),
                ('primary_school', 'TEXT'),
                ('height', 'REAL'),
                ('vision', 'TEXT'),
                ('class_position_intention', 'TEXT'),
                ('visit_time', 'TEXT'),
                ('good_subjects', 'TEXT')
            ]
            
            for column_name, column_type in new_columns:
                if column_name not in columns:
                    cursor.execute(f"ALTER TABLE students ADD COLUMN {column_name} {column_type}")
                    database_logger.info(f"添加字段 {column_name} 到 students 表")
            
        except sqlite3.Error as e:
            database_logger.warning(f"数据库迁移警告: {e}")
    
    @contextmanager
    def get_connection(self):
        """获取数据库连接"""
        conn = None
        try:
            conn = sqlite3.connect(self.db_path)
            conn.row_factory = sqlite3.Row  # 使结果可以通过列名访问
            yield conn
        except sqlite3.Error as e:
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
                
                # 将结果转换为字典列表
                columns = [description[0] for description in cursor.description]
                results = []
                for row in cursor.fetchall():
                    results.append(dict(zip(columns, row)))
                
                return results
                
        except sqlite3.Error as e:
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
                
        except sqlite3.Error as e:
            database_logger.error(f"更新执行失败: {e}")
            raise DatabaseException(f"更新执行失败: {e}")
    
    def execute_insert(self, query: str, params: tuple = ()) -> int:
        """执行插入操作并返回新插入记录的ID"""
        try:
            with self.get_connection() as conn:
                cursor = conn.cursor()
                cursor.execute(query, params)
                conn.commit()
                return cursor.lastrowid
                
        except sqlite3.Error as e:
            database_logger.error(f"插入执行失败: {e}")
            raise DatabaseException(f"插入执行失败: {e}")
    
    def backup_database(self, backup_path: str) -> bool:
        """备份数据库"""
        try:
            import shutil
            shutil.copy2(self.db_path, backup_path)
            database_logger.info(f"数据库备份成功: {backup_path}")
            return True
        except Exception as e:
            database_logger.error(f"数据库备份失败: {e}")
            return False
    
    def get_table_info(self, table_name: str) -> List[Dict[str, Any]]:
        """获取表结构信息"""
        try:
            with self.get_connection() as conn:
                cursor = conn.cursor()
                cursor.execute(f"PRAGMA table_info({table_name})")
                columns = [description[0] for description in cursor.description]
                results = []
                for row in cursor.fetchall():
                    results.append(dict(zip(columns, row)))
                return results
        except sqlite3.Error as e:
            database_logger.error(f"获取表信息失败: {e}")
            raise DatabaseException(f"获取表信息失败: {e}")


# 创建全局数据库管理器实例
db_manager = DatabaseManager() 