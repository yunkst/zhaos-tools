"""
年龄计算工具类 - 支持缓存的动态年龄计算
"""

from datetime import datetime, date
from typing import Optional, Dict, Tuple
import threading
import time
from functools import lru_cache

from app.utils.id_card_utils import calculate_age_from_id_card
from app.core.logger import service_logger


class AgeCalculator:
    """年龄计算器，支持缓存"""
    
    def __init__(self, cache_ttl: int = 3600):  # 缓存1小时
        self.cache_ttl = cache_ttl
        self._cache: Dict[str, Tuple[int, float]] = {}  # {id_card: (age, timestamp)}
        self._lock = threading.RLock()
    
    def calculate_age(self, id_card: str) -> Optional[int]:
        """
        计算年龄（支持缓存）
        
        Args:
            id_card: 身份证号
            
        Returns:
            年龄（整数），如果无法计算则返回None
        """
        if not id_card:
            return None
            
        # 检查缓存
        with self._lock:
            if id_card in self._cache:
                cached_age, cached_time = self._cache[id_card]
                # 检查缓存是否过期
                if time.time() - cached_time < self.cache_ttl:
                    return cached_age
                else:
                    # 缓存过期，删除
                    del self._cache[id_card]
        
        # 计算年龄
        age = self._calculate_age_from_id_card(id_card)
        
        # 存入缓存
        if age is not None:
            with self._lock:
                self._cache[id_card] = (age, time.time())
        
        return age
    
    def _calculate_age_from_id_card(self, id_card: str) -> Optional[int]:
        """
        从身份证号计算年龄
        
        Args:
            id_card: 身份证号
            
        Returns:
            年龄（整数），如果无法计算则返回None
        """
        try:
            # 直接使用现有的年龄计算函数
            age = calculate_age_from_id_card(id_card)
            return age if age is not None else None
            
        except Exception as e:
            service_logger.warning(f"计算年龄失败，身份证号: {id_card}, 错误: {e}")
            return None
    
    def clear_cache(self):
        """清空缓存"""
        with self._lock:
            self._cache.clear()
    
    def get_cache_info(self) -> Dict:
        """获取缓存信息"""
        with self._lock:
            current_time = time.time()
            valid_count = sum(1 for _, (_, timestamp) in self._cache.items() 
                            if current_time - timestamp < self.cache_ttl)
            
            return {
                'total_cached': len(self._cache),
                'valid_cached': valid_count,
                'expired_cached': len(self._cache) - valid_count,
                'cache_ttl': self.cache_ttl
            }
    
    def cleanup_expired_cache(self):
        """清理过期缓存"""
        with self._lock:
            current_time = time.time()
            expired_keys = [
                id_card for id_card, (_, timestamp) in self._cache.items()
                if current_time - timestamp >= self.cache_ttl
            ]
            
            for key in expired_keys:
                del self._cache[key]
            
            if expired_keys:
                service_logger.info(f"清理过期缓存: {len(expired_keys)} 条")


# 全局年龄计算器实例
age_calculator = AgeCalculator()


@lru_cache(maxsize=1000)
def calculate_age_cached(id_card: str, current_date_str: str) -> Optional[int]:
    """
    使用LRU缓存的年龄计算函数
    
    Args:
        id_card: 身份证号
        current_date_str: 当前日期字符串（用于缓存失效）
        
    Returns:
        年龄（整数），如果无法计算则返回None
    """
    return age_calculator._calculate_age_from_id_card(id_card)


def get_current_age(id_card: str) -> Optional[int]:
    """
    获取当前年龄（便捷函数）
    
    Args:
        id_card: 身份证号
        
    Returns:
        年龄（整数），如果无法计算则返回None
    """
    return age_calculator.calculate_age(id_card) 