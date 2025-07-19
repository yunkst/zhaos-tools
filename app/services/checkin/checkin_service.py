"""打卡服务 - 基础CRUD操作"""

from typing import Dict, Any, Optional, List
from datetime import datetime

from app.core.database import db_manager
from app.core.logger import service_logger
from app.utils.exceptions import (
    NotFoundException,
    StudentNotFoundException,
    ServiceException
)


class CheckInService:
    """打卡服务类 - 处理基础CRUD操作"""
    
    def __init__(self):
        self.db = db_manager
    
    def get_checkin_by_id(self, checkin_id: int) -> Optional[Dict[str, Any]]:
        """
        根据ID获取打卡记录
        
        Args:
            checkin_id: 打卡记录ID
            
        Returns:
            Dict: 打卡记录信息
            
        Raises:
            NotFoundException: 打卡记录不存在
            ServiceException: 服务异常
        """
        try:
            query = """
                SELECT c.*, s.name as student_name, s.student_id
                FROM checkins c
                LEFT JOIN students s ON c.student_id = s.id
                WHERE c.id = ?
            """
            result = self.db.execute_query(query, (checkin_id,))
            
            if not result:
                raise NotFoundException(f"未找到ID为 {checkin_id} 的打卡记录")
            
            service_logger.info(f"获取打卡记录成功: ID {checkin_id}")
            return result[0]
            
        except NotFoundException:
            raise
        except Exception as e:
            service_logger.error(f"获取打卡记录失败: {e}")
            raise ServiceException(f"获取打卡记录失败: {e}")
    
    def create_checkin(self, checkin_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        创建新的打卡记录
        
        Args:
            checkin_data: 打卡数据
            
        Returns:
            Dict: 新创建的打卡记录
            
        Raises:
            StudentNotFoundException: 学生不存在
            ServiceException: 服务异常
        """
        try:
            # 验证学生是否存在
            student_query = "SELECT id FROM students WHERE id = ?"
            student_result = self.db.execute_query(student_query, (checkin_data['student_id'],))
            
            if not student_result:
                raise StudentNotFoundException(f"学生ID {checkin_data['student_id']} 不存在")
            
            # 插入打卡记录
            insert_query = """
                INSERT INTO checkins (
                    student_id, checkin_date, checkin_time, content, 
                    mood, weather, location, photos, reply, 
                    reply_time, teacher_id, status
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """
            
            new_id = self.db.execute_insert(insert_query, (
                checkin_data['student_id'],
                checkin_data.get('checkin_date', datetime.now().date()),
                checkin_data.get('checkin_time', datetime.now().time()),
                checkin_data.get('content', ''),
                checkin_data.get('mood'),
                checkin_data.get('weather'),
                checkin_data.get('location'),
                checkin_data.get('photos'),
                checkin_data.get('reply'),
                checkin_data.get('reply_time'),
                checkin_data.get('teacher_id'),
                checkin_data.get('status', 'active')
            ))
            
            # 获取新创建的打卡记录
            new_checkin = self.get_checkin_by_id(new_id)
            
            service_logger.info(f"创建打卡记录成功: 学生ID {checkin_data['student_id']}")
            return new_checkin
            
        except (StudentNotFoundException, NotFoundException):
            raise
        except Exception as e:
            service_logger.error(f"创建打卡记录失败: {e}")
            raise ServiceException(f"创建打卡记录失败: {e}")
    
    def update_checkin(self, checkin_id: int, checkin_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        更新打卡记录
        
        Args:
            checkin_id: 打卡记录ID
            checkin_data: 更新的数据
            
        Returns:
            Dict: 更新后的打卡记录
            
        Raises:
            NotFoundException: 打卡记录不存在
            ServiceException: 服务异常
        """
        try:
            # 检查打卡记录是否存在
            existing_checkin = self.get_checkin_by_id(checkin_id)
            
            # 构建更新字段
            update_fields = []
            update_values = []
            
            allowed_fields = [
                'content', 'mood', 'weather', 'location', 'photos', 
                'reply', 'reply_time', 'teacher_id', 'status'
            ]
            
            for field in allowed_fields:
                if field in checkin_data:
                    update_fields.append(f"{field} = ?")
                    update_values.append(checkin_data[field])
            
            if not update_fields:
                return existing_checkin
            
            # 添加更新时间
            update_fields.append("updated_at = ?")
            update_values.append(datetime.now())
            
            # 添加WHERE条件的参数
            update_values.append(checkin_id)
            
            query = f"UPDATE checkins SET {', '.join(update_fields)} WHERE id = ?"
            affected_rows = self.db.execute_update(query, tuple(update_values))
            
            if affected_rows == 0:
                raise ServiceException(f"更新打卡记录失败，记录ID {checkin_id} 可能已被删除")
            
            # 获取更新后的打卡记录
            updated_checkin = self.get_checkin_by_id(checkin_id)
            
            service_logger.info(f"更新打卡记录成功: ID {checkin_id}")
            return updated_checkin
            
        except (NotFoundException, ServiceException):
            raise
        except Exception as e:
            service_logger.error(f"更新打卡记录失败: {e}")
            raise ServiceException(f"更新打卡记录失败: {e}")
    
    def delete_checkin(self, checkin_id: int) -> bool:
        """
        删除打卡记录
        
        Args:
            checkin_id: 打卡记录ID
            
        Returns:
            bool: 删除是否成功
            
        Raises:
            NotFoundException: 打卡记录不存在
            ServiceException: 服务异常
        """
        try:
            # 检查打卡记录是否存在
            existing_checkin = self.get_checkin_by_id(checkin_id)
            
            # 软删除：更新状态为deleted
            query = "UPDATE checkins SET status = 'deleted', updated_at = ? WHERE id = ?"
            affected_rows = self.db.execute_update(query, (datetime.now(), checkin_id))
            
            if affected_rows > 0:
                service_logger.info(f"删除打卡记录成功: ID {checkin_id}")
                return True
            else:
                return False
                
        except NotFoundException:
            raise
        except Exception as e:
            service_logger.error(f"删除打卡记录失败: {e}")
            raise ServiceException(f"删除打卡记录失败: {e}")
    
    def get_checkins(self, page: int = 1, page_size: int = 20, **filters) -> Dict[str, Any]:
        """
        获取打卡记录列表
        
        Args:
            page: 页码
            page_size: 每页大小
            **filters: 过滤条件
            
        Returns:
            Dict: 包含打卡记录列表和分页信息
        """
        try:
            # 计算偏移量
            offset = (page - 1) * page_size
            
            # 构建WHERE条件
            where_conditions = ["c.status != 'deleted'"]
            where_params = []
            
            if filters.get('student_id'):
                where_conditions.append("c.student_id = ?")
                where_params.append(filters['student_id'])
            
            if filters.get('date_from'):
                where_conditions.append("c.checkin_date >= ?")
                where_params.append(filters['date_from'])
            
            if filters.get('date_to'):
                where_conditions.append("c.checkin_date <= ?")
                where_params.append(filters['date_to'])
            
            if filters.get('mood'):
                where_conditions.append("c.mood = ?")
                where_params.append(filters['mood'])
            
            where_clause = " AND ".join(where_conditions)
            
            # 获取总数
            total_query = f"""
                SELECT COUNT(*) as total 
                FROM checkins c
                LEFT JOIN students s ON c.student_id = s.id
                WHERE {where_clause}
            """
            total_result = self.db.execute_query(total_query, where_params)
            total = total_result[0]['total'] if total_result else 0
            
            # 获取打卡记录列表
            query = f"""
                SELECT c.*, s.name as student_name, s.student_id as student_number
                FROM checkins c
                LEFT JOIN students s ON c.student_id = s.id
                WHERE {where_clause}
                ORDER BY c.checkin_date DESC, c.checkin_time DESC
                LIMIT ? OFFSET ?
            """
            
            checkins = self.db.execute_query(query, where_params + [page_size, offset])
            
            service_logger.info(f"获取打卡记录列表成功，共 {len(checkins)} 条记录")
            
            return {
                'records': checkins,
                'total': total,
                'page': page,
                'page_size': page_size,
                'total_pages': (total + page_size - 1) // page_size
            }
            
        except Exception as e:
            service_logger.error(f"获取打卡记录列表失败: {e}")
            raise ServiceException(f"获取打卡记录列表失败: {e}")
    
    def get_student_checkins(self, student_id: int, page: int = 1, page_size: int = 20) -> Dict[str, Any]:
        """
        获取指定学生的打卡记录
        
        Args:
            student_id: 学生ID
            page: 页码
            page_size: 每页大小
            
        Returns:
            Dict: 包含打卡记录列表和分页信息
        """
        try:
            # 验证学生是否存在
            student_query = "SELECT id, name FROM students WHERE id = ?"
            student_result = self.db.execute_query(student_query, (student_id,))
            
            if not student_result:
                raise StudentNotFoundException(f"学生ID {student_id} 不存在")
            
            # 获取该学生的打卡记录
            return self.get_checkins(page=page, page_size=page_size, student_id=student_id)
            
        except StudentNotFoundException:
            raise
        except Exception as e:
            service_logger.error(f"获取学生打卡记录失败: {e}")
            raise ServiceException(f"获取学生打卡记录失败: {e}")