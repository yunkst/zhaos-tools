"""
配置管理服务
"""

from typing import List, Optional, Dict, Any
from datetime import datetime
from app.core.database import DatabaseManager
from app.schemas.config_schema import ConfigCreate, ConfigUpdate, ConfigResponse
from app.utils.exceptions import ServiceException
from app.core.logger import service_logger


class ConfigNotFoundException(ServiceException):
    """配置未找到异常"""
    pass


class ConfigService:
    """配置管理服务"""
    
    def __init__(self):
        self.db = DatabaseManager()
    
    def get_all_configs(self) -> List[ConfigResponse]:
        """获取所有配置"""
        try:
            with self.db.get_connection() as conn:
                cursor = conn.cursor()
                cursor.execute("""
                    SELECT key, value, description, updated_at 
                    FROM system_config 
                    ORDER BY key
                """)
                
                configs = []
                for row in cursor.fetchall():
                    configs.append(ConfigResponse(
                        key=row['key'],
                        value=row['value'],
                        description=row['description'],
                        updated_at=row['updated_at']
                    ))
                
                return configs
                
        except Exception as e:
            service_logger.error(f"获取配置列表失败: {e}")
            raise ServiceException(f"获取配置列表失败: {e}")
    
    def get_config_by_key(self, key: str) -> ConfigResponse:
        """根据键获取配置"""
        try:
            with self.db.get_connection() as conn:
                cursor = conn.cursor()
                cursor.execute("""
                    SELECT key, value, description, updated_at 
                    FROM system_config 
                    WHERE key = ?
                """, (key,))
                
                row = cursor.fetchone()
                if not row:
                    raise ConfigNotFoundException(f"配置 {key} 不存在")
                
                return ConfigResponse(
                    key=row['key'],
                    value=row['value'],
                    description=row['description'],
                    updated_at=row['updated_at']
                )
                
        except ConfigNotFoundException:
            raise
        except Exception as e:
            service_logger.error(f"获取配置失败: {e}")
            raise ServiceException(f"获取配置失败: {e}")
    
    def create_config(self, config: ConfigCreate) -> ConfigResponse:
        """创建配置"""
        try:
            with self.db.get_connection() as conn:
                cursor = conn.cursor()
                
                # 检查配置是否已存在
                cursor.execute("SELECT key FROM system_config WHERE key = ?", (config.key,))
                if cursor.fetchone():
                    raise ServiceException(f"配置 {config.key} 已存在")
                
                # 插入新配置
                cursor.execute("""
                    INSERT INTO system_config (key, value, description, updated_at)
                    VALUES (?, ?, ?, ?)
                """, (config.key, config.value, config.description, datetime.now()))
                
                conn.commit()
                service_logger.info(f"创建配置成功: {config.key}")
                
                return self.get_config_by_key(config.key)
                
        except ServiceException:
            raise
        except Exception as e:
            service_logger.error(f"创建配置失败: {e}")
            raise ServiceException(f"创建配置失败: {e}")
    
    def update_config(self, key: str, config: ConfigUpdate) -> ConfigResponse:
        """更新配置"""
        try:
            with self.db.get_connection() as conn:
                cursor = conn.cursor()
                
                # 检查配置是否存在
                cursor.execute("SELECT key FROM system_config WHERE key = ?", (key,))
                if not cursor.fetchone():
                    raise ConfigNotFoundException(f"配置 {key} 不存在")
                
                # 更新配置
                cursor.execute("""
                    UPDATE system_config 
                    SET value = ?, description = ?, updated_at = ?
                    WHERE key = ?
                """, (config.value, config.description, datetime.now(), key))
                
                conn.commit()
                service_logger.info(f"更新配置成功: {key}")
                
                return self.get_config_by_key(key)
                
        except ConfigNotFoundException:
            raise
        except Exception as e:
            service_logger.error(f"更新配置失败: {e}")
            raise ServiceException(f"更新配置失败: {e}")
    
    def delete_config(self, key: str) -> bool:
        """删除配置"""
        try:
            with self.db.get_connection() as conn:
                cursor = conn.cursor()
                
                # 检查配置是否存在
                cursor.execute("SELECT key FROM system_config WHERE key = ?", (key,))
                if not cursor.fetchone():
                    raise ConfigNotFoundException(f"配置 {key} 不存在")
                
                # 删除配置
                cursor.execute("DELETE FROM system_config WHERE key = ?", (key,))
                conn.commit()
                
                service_logger.info(f"删除配置成功: {key}")
                return True
                
        except ConfigNotFoundException:
            raise
        except Exception as e:
            service_logger.error(f"删除配置失败: {e}")
            raise ServiceException(f"删除配置失败: {e}")
    
    def batch_update_configs(self, configs: List[ConfigCreate]) -> List[ConfigResponse]:
        """批量更新配置"""
        try:
            results = []
            for config in configs:
                try:
                    # 尝试获取现有配置
                    existing = self.get_config_by_key(config.key)
                    # 如果存在，则更新
                    result = self.update_config(config.key, ConfigUpdate(
                        value=config.value,
                        description=config.description
                    ))
                except ConfigNotFoundException:
                    # 如果不存在，则创建
                    result = self.create_config(config)
                
                results.append(result)
            
            return results
            
        except Exception as e:
            service_logger.error(f"批量更新配置失败: {e}")
            raise ServiceException(f"批量更新配置失败: {e}")
    
    def get_configs_by_group(self, group_prefix: str) -> List[ConfigResponse]:
        """根据前缀获取配置组"""
        try:
            with self.db.get_connection() as conn:
                cursor = conn.cursor()
                cursor.execute("""
                    SELECT key, value, description, updated_at 
                    FROM system_config 
                    WHERE key LIKE ?
                    ORDER BY key
                """, (f"{group_prefix}%",))
                
                configs = []
                for row in cursor.fetchall():
                    configs.append(ConfigResponse(
                        key=row['key'],
                        value=row['value'],
                        description=row['description'],
                        updated_at=row['updated_at']
                    ))
                
                return configs
                
        except Exception as e:
            service_logger.error(f"获取配置组失败: {e}")
            raise ServiceException(f"获取配置组失败: {e}")


# 创建服务实例
config_service = ConfigService()