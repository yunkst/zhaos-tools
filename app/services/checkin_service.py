"""
打卡服务层 - 处理打卡相关的业务逻辑
"""

from typing import List, Optional, Dict, Any
from datetime import datetime, date

from app.core.database import db_manager
from app.core.logger import service_logger
from app.schemas.checkin import CheckInCreate, CheckInUpdate
from app.services.student_service import student_service
from app.utils.exceptions import (
    StudentNotFoundException,
    ServiceException
)


class CheckInService:
    """打卡服务类"""
    
    def __init__(self):
        self.db = db_manager
    
    def get_checkins(
        self,
        page: int = 1,
        page_size: int = 20,
        student_id: Optional[str] = None,
        start_date: Optional[date] = None,
        end_date: Optional[date] = None,
        search: Optional[str] = None
    ) -> Dict[str, Any]:
        """获取打卡记录列表"""
        try:
            # 计算偏移量
            offset = (page - 1) * page_size
            
            # 构建查询条件
            conditions = []
            params = []
            
            if student_id:
                conditions.append("c.student_id = ?")
                params.append(student_id)
            
            if start_date:
                conditions.append("c.check_in_date >= ?")
                params.append(start_date.isoformat())
            
            if end_date:
                conditions.append("c.check_in_date <= ?")
                params.append(end_date.isoformat())
            
            if search:
                conditions.append("(c.content LIKE ? OR c.auto_reply LIKE ? OR s.name LIKE ?)")
                search_param = f"%{search}%"
                params.extend([search_param, search_param, search_param])
            
            where_clause = " AND ".join(conditions) if conditions else "1=1"
            
            # 获取总数
            total_query = f"""
                SELECT COUNT(*) as total 
                FROM check_in_records c
                LEFT JOIN students s ON c.student_id = s.student_id
                WHERE {where_clause}
            """
            total_result = self.db.execute_query(total_query, params)
            total = total_result[0]['total'] if total_result else 0
            
            # 获取记录列表
            query = f"""
                SELECT c.id, c.student_id, c.check_in_date, c.content, c.auto_reply, c.created_at,
                       s.name as student_name
                FROM check_in_records c
                LEFT JOIN students s ON c.student_id = s.student_id
                WHERE {where_clause}
                ORDER BY c.created_at DESC
                LIMIT ? OFFSET ?
            """
            
            records = self.db.execute_query(query, params + [page_size, offset])
            
            service_logger.info(f"获取打卡记录列表成功，共 {len(records)} 条记录")
            
            return {
                'records': records,
                'total': total,
                'page': page,
                'page_size': page_size,
                'total_pages': (total + page_size - 1) // page_size
            }
            
        except Exception as e:
            service_logger.error(f"获取打卡记录列表失败: {e}")
            raise ServiceException(f"获取打卡记录列表失败: {e}")
    
    def get_checkin_by_id(self, checkin_id: int) -> Optional[Dict[str, Any]]:
        """根据ID获取打卡记录"""
        try:
            query = """
                SELECT c.id, c.student_id, c.check_in_date, c.content, c.auto_reply, c.created_at,
                       s.name as student_name
                FROM check_in_records c
                LEFT JOIN students s ON c.student_id = s.student_id
                WHERE c.id = ?
            """
            result = self.db.execute_query(query, (checkin_id,))
            
            if not result:
                return None
            
            service_logger.info(f"获取打卡记录成功: {checkin_id}")
            return result[0]
            
        except Exception as e:
            service_logger.error(f"获取打卡记录失败: {e}")
            raise ServiceException(f"获取打卡记录失败: {e}")
    
    def create_checkin(self, checkin_data: CheckInCreate) -> Dict[str, Any]:
        """创建打卡记录"""
        try:
            # 检查学生是否存在
            student = student_service.get_student_by_student_id(checkin_data.student_id)
            if not student:
                raise StudentNotFoundException(f"学号 {checkin_data.student_id} 不存在")
            
            # 插入打卡记录
            query = """
                INSERT INTO check_in_records (student_id, check_in_date, content)
                VALUES (?, ?, ?)
            """
            
            new_id = self.db.execute_insert(query, (
                checkin_data.student_id,
                checkin_data.check_in_date.isoformat(),
                checkin_data.content
            ))
            
            # 获取新创建的记录
            new_checkin = self.get_checkin_by_id(new_id)
            
            service_logger.info(f"创建打卡记录成功: {checkin_data.student_id} - {checkin_data.check_in_date}")
            return new_checkin
            
        except StudentNotFoundException:
            raise
        except Exception as e:
            service_logger.error(f"创建打卡记录失败: {e}")
            raise ServiceException(f"创建打卡记录失败: {e}")
    
    def update_checkin(self, checkin_id: int, checkin_data: CheckInUpdate) -> Dict[str, Any]:
        """更新打卡记录"""
        try:
            # 检查记录是否存在
            existing_checkin = self.get_checkin_by_id(checkin_id)
            if not existing_checkin:
                raise ServiceException(f"打卡记录 {checkin_id} 不存在")
            
            # 如果更新学号，检查学生是否存在
            if checkin_data.student_id and checkin_data.student_id != existing_checkin['student_id']:
                student = student_service.get_student_by_student_id(checkin_data.student_id)
                if not student:
                    raise StudentNotFoundException(f"学号 {checkin_data.student_id} 不存在")
            
            # 构建更新字段
            update_fields = []
            update_values = []
            
            for field, value in checkin_data.dict(exclude_unset=True).items():
                if field == 'check_in_date' and value:
                    update_fields.append(f"{field} = ?")
                    update_values.append(value.isoformat())
                else:
                    update_fields.append(f"{field} = ?")
                    update_values.append(value)
            
            if not update_fields:
                return existing_checkin
            
            update_values.append(checkin_id)
            
            query = f"UPDATE check_in_records SET {', '.join(update_fields)} WHERE id = ?"
            self.db.execute_update(query, tuple(update_values))
            
            # 获取更新后的记录
            updated_checkin = self.get_checkin_by_id(checkin_id)
            
            service_logger.info(f"更新打卡记录成功: {checkin_id}")
            return updated_checkin
            
        except (StudentNotFoundException, ServiceException):
            raise
        except Exception as e:
            service_logger.error(f"更新打卡记录失败: {e}")
            raise ServiceException(f"更新打卡记录失败: {e}")
    
    def delete_checkin(self, checkin_id: int) -> bool:
        """删除打卡记录"""
        try:
            # 检查记录是否存在
            existing_checkin = self.get_checkin_by_id(checkin_id)
            if not existing_checkin:
                raise ServiceException(f"打卡记录 {checkin_id} 不存在")
            
            # 删除记录
            query = "DELETE FROM check_in_records WHERE id = ?"
            affected_rows = self.db.execute_update(query, (checkin_id,))
            
            if affected_rows > 0:
                service_logger.info(f"删除打卡记录成功: {checkin_id}")
                return True
            else:
                return False
                
        except ServiceException:
            raise
        except Exception as e:
            service_logger.error(f"删除打卡记录失败: {e}")
            raise ServiceException(f"删除打卡记录失败: {e}")
    
    def get_student_checkins(
        self,
        student_id: str,
        page: int = 1,
        page_size: int = 20,
        start_date: Optional[date] = None,
        end_date: Optional[date] = None
    ) -> Dict[str, Any]:
        """获取指定学生的打卡记录"""
        try:
            # 检查学生是否存在
            student = student_service.get_student_by_student_id(student_id)
            if not student:
                raise StudentNotFoundException(f"学号 {student_id} 不存在")
            
            # 计算偏移量
            offset = (page - 1) * page_size
            
            # 构建查询条件
            conditions = ["c.student_id = ?"]
            params = [student_id]
            
            if start_date:
                conditions.append("c.check_in_date >= ?")
                params.append(start_date.isoformat())
            
            if end_date:
                conditions.append("c.check_in_date <= ?")
                params.append(end_date.isoformat())
            
            where_clause = " AND ".join(conditions)
            
            # 获取总数
            total_query = f"""
                SELECT COUNT(*) as total 
                FROM check_in_records c
                WHERE {where_clause}
            """
            total_result = self.db.execute_query(total_query, params)
            total = total_result[0]['total'] if total_result else 0
            
            # 获取记录列表
            query = f"""
                SELECT c.id, c.student_id, c.check_in_date, c.content, c.auto_reply, c.created_at,
                       s.name as student_name
                FROM check_in_records c
                LEFT JOIN students s ON c.student_id = s.student_id
                WHERE {where_clause}
                ORDER BY c.check_in_date DESC, c.created_at DESC
                LIMIT ? OFFSET ?
            """
            
            records = self.db.execute_query(query, params + [page_size, offset])
            
            service_logger.info(f"获取学生打卡记录成功: {student_id}，共 {len(records)} 条记录")
            
            return {
                'records': records,
                'total': total,
                'page': page,
                'page_size': page_size,
                'total_pages': (total + page_size - 1) // page_size,
                'student_info': student
            }
            
        except StudentNotFoundException:
            raise
        except Exception as e:
            service_logger.error(f"获取学生打卡记录失败: {e}")
            raise ServiceException(f"获取学生打卡记录失败: {e}")
    
    def get_checkin_stats(self) -> Dict[str, Any]:
        """获取打卡统计信息"""
        try:
            # 总打卡次数
            total_query = "SELECT COUNT(*) as total FROM check_in_records"
            total_result = self.db.execute_query(total_query)
            total_checkins = total_result[0]['total'] if total_result else 0
            
            # 今日打卡次数
            today = date.today().isoformat()
            today_query = "SELECT COUNT(*) as today FROM check_in_records WHERE check_in_date = ?"
            today_result = self.db.execute_query(today_query, (today,))
            today_checkins = today_result[0]['today'] if today_result else 0
            
            # 有回复的打卡次数
            replied_query = "SELECT COUNT(*) as replied FROM check_in_records WHERE auto_reply IS NOT NULL AND auto_reply != ''"
            replied_result = self.db.execute_query(replied_query)
            replied_checkins = replied_result[0]['replied'] if replied_result else 0
            
            # 参与打卡的学生数
            students_query = "SELECT COUNT(DISTINCT student_id) as students FROM check_in_records"
            students_result = self.db.execute_query(students_query)
            active_students = students_result[0]['students'] if students_result else 0
            
            # 最近7天的打卡趋势
            trend_query = """
                SELECT check_in_date, COUNT(*) as count
                FROM check_in_records
                WHERE check_in_date >= date('now', '-7 days')
                GROUP BY check_in_date
                ORDER BY check_in_date DESC
                LIMIT 7
            """
            trend_result = self.db.execute_query(trend_query)
            
            # 最活跃的学生（前5名）
            top_students_query = """
                SELECT c.student_id, s.name, COUNT(*) as checkin_count
                FROM check_in_records c
                LEFT JOIN students s ON c.student_id = s.student_id
                GROUP BY c.student_id, s.name
                ORDER BY checkin_count DESC
                LIMIT 5
            """
            top_students_result = self.db.execute_query(top_students_query)
            
            stats = {
                'total_checkins': total_checkins,
                'today_checkins': today_checkins,
                'replied_checkins': replied_checkins,
                'reply_rate': round((replied_checkins / total_checkins * 100), 2) if total_checkins > 0 else 0,
                'active_students': active_students,
                'recent_trend': trend_result,
                'top_students': top_students_result
            }
            
            service_logger.info("获取打卡统计信息成功")
            return stats
            
        except Exception as e:
            service_logger.error(f"获取打卡统计信息失败: {e}")
            raise ServiceException(f"获取打卡统计信息失败: {e}")
    
    def get_checkins_by_date_range(
        self,
        start_date: date,
        end_date: date,
        student_id: Optional[str] = None
    ) -> List[Dict[str, Any]]:
        """根据日期范围获取打卡记录"""
        try:
            conditions = ["c.check_in_date >= ?", "c.check_in_date <= ?"]
            params = [start_date.isoformat(), end_date.isoformat()]
            
            if student_id:
                conditions.append("c.student_id = ?")
                params.append(student_id)
            
            where_clause = " AND ".join(conditions)
            
            query = f"""
                SELECT c.id, c.student_id, c.check_in_date, c.content, c.auto_reply, c.created_at,
                       s.name as student_name
                FROM check_in_records c
                LEFT JOIN students s ON c.student_id = s.student_id
                WHERE {where_clause}
                ORDER BY c.check_in_date DESC, c.created_at DESC
            """
            
            records = self.db.execute_query(query, params)
            
            service_logger.info(f"根据日期范围获取打卡记录成功: {start_date} 到 {end_date}，共 {len(records)} 条记录")
            return records
            
        except Exception as e:
            service_logger.error(f"根据日期范围获取打卡记录失败: {e}")
            raise ServiceException(f"根据日期范围获取打卡记录失败: {e}")
    
    def batch_update_replies(self, checkin_ids: List[int], auto_reply: str) -> Dict[str, Any]:
        """批量更新回复"""
        try:
            success_count = 0
            failed_count = 0
            failed_ids = []
            
            for checkin_id in checkin_ids:
                try:
                    update_data = CheckInUpdate(auto_reply=auto_reply)
                    self.update_checkin(checkin_id, update_data)
                    success_count += 1
                except Exception as e:
                    failed_count += 1
                    failed_ids.append({
                        'checkin_id': checkin_id,
                        'error': str(e)
                    })
            
            service_logger.info(f"批量更新回复完成，成功: {success_count}，失败: {failed_count}")
            
            return {
                'success_count': success_count,
                'failed_count': failed_count,
                'failed_ids': failed_ids,
                'total_count': len(checkin_ids)
            }
            
        except Exception as e:
            service_logger.error(f"批量更新回复失败: {e}")
            raise ServiceException(f"批量更新回复失败: {e}")


# 创建全局打卡服务实例
checkin_service = CheckInService() 