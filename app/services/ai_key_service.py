""" 
AI Key管理服务
"""

from typing import List, Optional
from datetime import datetime
from app.schemas.ai_key_schema import (
    AIKeyCreate,
    AIKeyUpdate,
    AIKeyResponse,
    AIKeyDetailResponse,
    AIProviderType
)
from app.core.database import DatabaseManager
from app.utils.exceptions import ServiceException
from app.core.logger import service_logger
import sqlite3


class AIKeyNotFoundException(ServiceException):
    """AI Key未找到异常"""
    pass


class AIKeyService:
    """AI Key管理服务类"""
    
    def __init__(self):
        self._init_table()
    
    def _init_table(self):
        """初始化AI Key表"""
        try:
            db_manager = DatabaseManager()
            with db_manager.get_connection() as conn:
                conn.execute("""
                    CREATE TABLE IF NOT EXISTS ai_keys (
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        name TEXT NOT NULL UNIQUE,
                        provider_type TEXT NOT NULL,
                        api_key TEXT NOT NULL,
                        base_url TEXT,
                        description TEXT,
                        is_active BOOLEAN DEFAULT 1,
                        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                    )
                """)
                conn.commit()
                service_logger.info("AI Key表初始化成功")
        except Exception as e:
            service_logger.error(f"AI Key表初始化失败: {e}")
            raise ServiceException(f"数据库初始化失败: {e}")
    
    def _mask_api_key(self, api_key: str) -> str:
        """脱敏处理API Key"""
        if not api_key or len(api_key) <= 8:
            return "****"
        return api_key[:4] + "*" * (len(api_key) - 8) + api_key[-4:]
    
    def create_ai_key(self, ai_key_data: AIKeyCreate) -> AIKeyResponse:
        """创建AI Key"""
        try:
            db_manager = DatabaseManager()
            with db_manager.get_connection() as conn:
                cursor = conn.execute("""
                    INSERT INTO ai_keys (name, provider_type, api_key, base_url, description, is_active)
                    VALUES (?, ?, ?, ?, ?, ?)
                """, (
                    ai_key_data.name,
                    ai_key_data.provider_type.value,
                    ai_key_data.api_key,
                    ai_key_data.base_url,
                    ai_key_data.description,
                    ai_key_data.is_active
                ))
                
                ai_key_id = cursor.lastrowid
                conn.commit()
                
                service_logger.info(f"创建AI Key成功: {ai_key_data.name}")
                return self.get_ai_key_by_id(ai_key_id)
                
        except sqlite3.IntegrityError as e:
            if "UNIQUE constraint failed" in str(e):
                raise ServiceException(f"AI Key名称 '{ai_key_data.name}' 已存在")
            raise ServiceException(f"数据库约束错误: {e}")
        except Exception as e:
            service_logger.error(f"创建AI Key失败: {e}")
            raise ServiceException(f"创建AI Key失败: {e}")
    
    def get_ai_key_by_id(self, ai_key_id: int) -> AIKeyResponse:
        """根据ID获取AI Key"""
        try:
            db_manager = DatabaseManager()
            with db_manager.get_connection() as conn:
                cursor = conn.execute("""
                    SELECT id, name, provider_type, api_key, base_url, description, 
                           is_active, created_at, updated_at
                    FROM ai_keys WHERE id = ?
                """, (ai_key_id,))
                
                row = cursor.fetchone()
                if not row:
                    raise AIKeyNotFoundException(f"AI Key ID {ai_key_id} 不存在")
                
                return AIKeyResponse(
                    id=row[0],
                    name=row[1],
                    provider_type=AIProviderType(row[2]),
                    api_key_masked=self._mask_api_key(row[3]),
                    base_url=row[4],
                    description=row[5],
                    is_active=bool(row[6]),
                    created_at=datetime.fromisoformat(row[7]),
                    updated_at=datetime.fromisoformat(row[8])
                )
                
        except AIKeyNotFoundException:
            raise
        except Exception as e:
            service_logger.error(f"获取AI Key失败: {e}")
            raise ServiceException(f"获取AI Key失败: {e}")
    
    def get_ai_key_detail_by_id(self, ai_key_id: int) -> AIKeyDetailResponse:
        """根据ID获取AI Key详情（包含完整API Key）"""
        try:
            db_manager = DatabaseManager()
            with db_manager.get_connection() as conn:
                cursor = conn.execute("""
                    SELECT id, name, provider_type, api_key, base_url, description, 
                           is_active, created_at, updated_at
                    FROM ai_keys WHERE id = ?
                """, (ai_key_id,))
                
                row = cursor.fetchone()
                if not row:
                    raise AIKeyNotFoundException(f"AI Key ID {ai_key_id} 不存在")
                
                return AIKeyDetailResponse(
                    id=row[0],
                    name=row[1],
                    provider_type=AIProviderType(row[2]),
                    api_key=row[3],
                    api_key_masked=self._mask_api_key(row[3]),
                    base_url=row[4],
                    description=row[5],
                    is_active=bool(row[6]),
                    created_at=datetime.fromisoformat(row[7]),
                    updated_at=datetime.fromisoformat(row[8])
                )
                
        except AIKeyNotFoundException:
            raise
        except Exception as e:
            service_logger.error(f"获取AI Key详情失败: {e}")
            raise ServiceException(f"获取AI Key详情失败: {e}")
    
    def get_all_ai_keys(self, provider_type: Optional[str] = None, is_active: Optional[bool] = None) -> List[AIKeyResponse]:
        """获取所有AI Key"""
        try:
            db_manager = DatabaseManager()
            with db_manager.get_connection() as conn:
                query = """
                    SELECT id, name, provider_type, api_key, base_url, description, 
                           is_active, created_at, updated_at
                    FROM ai_keys
                """
                params = []
                conditions = []
                
                if provider_type:
                    conditions.append("provider_type = ?")
                    params.append(provider_type)
                
                if is_active is not None:
                    conditions.append("is_active = ?")
                    params.append(is_active)
                
                if conditions:
                    query += " WHERE " + " AND ".join(conditions)
                
                query += " ORDER BY created_at DESC"
                
                cursor = conn.execute(query, params)
                rows = cursor.fetchall()
                
                return [
                    AIKeyResponse(
                        id=row[0],
                        name=row[1],
                        provider_type=AIProviderType(row[2]),
                        api_key_masked=self._mask_api_key(row[3]),
                        base_url=row[4],
                        description=row[5],
                        is_active=bool(row[6]),
                        created_at=datetime.fromisoformat(row[7]),
                        updated_at=datetime.fromisoformat(row[8])
                    )
                    for row in rows
                ]
                
        except Exception as e:
            service_logger.error(f"获取AI Key列表失败: {e}")
            raise ServiceException(f"获取AI Key列表失败: {e}")
    
    def update_ai_key(self, ai_key_id: int, ai_key_data: AIKeyUpdate) -> AIKeyResponse:
        """更新AI Key"""
        try:
            # 先检查AI Key是否存在
            self.get_ai_key_by_id(ai_key_id)
            
            # 构建更新语句
            update_fields = []
            params = []
            
            if ai_key_data.name is not None:
                update_fields.append("name = ?")
                params.append(ai_key_data.name)
            
            if ai_key_data.provider_type is not None:
                update_fields.append("provider_type = ?")
                params.append(ai_key_data.provider_type.value)
            
            if ai_key_data.api_key is not None:
                update_fields.append("api_key = ?")
                params.append(ai_key_data.api_key)
            
            if ai_key_data.base_url is not None:
                update_fields.append("base_url = ?")
                params.append(ai_key_data.base_url)
            
            if ai_key_data.description is not None:
                update_fields.append("description = ?")
                params.append(ai_key_data.description)
            
            if ai_key_data.is_active is not None:
                update_fields.append("is_active = ?")
                params.append(ai_key_data.is_active)
            
            if not update_fields:
                raise ServiceException("没有提供要更新的字段")
            
            update_fields.append("updated_at = CURRENT_TIMESTAMP")
            params.append(ai_key_id)
            
            db_manager = DatabaseManager()
            with db_manager.get_connection() as conn:
                conn.execute(
                    f"UPDATE ai_keys SET {', '.join(update_fields)} WHERE id = ?",
                    params
                )
                conn.commit()
                
                service_logger.info(f"更新AI Key成功: ID {ai_key_id}")
                return self.get_ai_key_by_id(ai_key_id)
                
        except AIKeyNotFoundException:
            raise
        except sqlite3.IntegrityError as e:
            if "UNIQUE constraint failed" in str(e):
                raise ServiceException(f"AI Key名称已存在")
            raise ServiceException(f"数据库约束错误: {e}")
        except Exception as e:
            service_logger.error(f"更新AI Key失败: {e}")
            raise ServiceException(f"更新AI Key失败: {e}")
    
    def delete_ai_key(self, ai_key_id: int) -> bool:
        """删除AI Key"""
        try:
            # 先检查AI Key是否存在
            ai_key = self.get_ai_key_by_id(ai_key_id)
            
            db_manager = DatabaseManager()
            with db_manager.get_connection() as conn:
                cursor = conn.execute("DELETE FROM ai_keys WHERE id = ?", (ai_key_id,))
                conn.commit()
                
                if cursor.rowcount == 0:
                    raise AIKeyNotFoundException(f"AI Key ID {ai_key_id} 不存在")
                
                service_logger.info(f"删除AI Key成功: {ai_key.name}")
                return True
                
        except AIKeyNotFoundException:
            raise
        except Exception as e:
            service_logger.error(f"删除AI Key失败: {e}")
            raise ServiceException(f"删除AI Key失败: {e}")


# 创建服务实例
ai_key_service = AIKeyService()