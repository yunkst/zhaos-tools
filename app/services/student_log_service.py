"""学生日志服务"""

from datetime import datetime
from typing import List, Optional, Dict, Any

from app.core.database import db_manager
from app.core.logger import get_logger
from app.schemas.student_log import StudentLogCreate, StudentLogUpdate, StudentLogResponse
from app.utils.exceptions import DatabaseException

logger = get_logger(__name__)


class StudentLogService:
    """学生日志服务类"""
    
    def create_log(self, log_data: StudentLogCreate) -> StudentLogResponse:
        """创建学生日志"""
        try:
            query = """
                INSERT INTO student_logs (student_id, title, content)
                VALUES (?, ?, ?)
            """
            log_id = db_manager.execute_insert(
                query, 
                (log_data.student_id, log_data.title, log_data.content)
            )
            
            # 获取创建的日志
            return self.get_log_by_id(log_id)
            
        except Exception as e:
            logger.error(f"创建学生日志失败: {e}")
            raise DatabaseException(f"创建学生日志失败: {e}")
    
    def get_log_by_id(self, log_id: int) -> Optional[StudentLogResponse]:
        """根据ID获取学生日志"""
        try:
            query = """
                SELECT id, student_id, title, content, created_at, updated_at
                FROM student_logs
                WHERE id = ?
            """
            results = db_manager.execute_query(query, (log_id,))
            
            if not results:
                return None
                
            log_data = results[0]
            return StudentLogResponse(**log_data)
            
        except Exception as e:
            logger.error(f"获取学生日志失败: {e}")
            raise DatabaseException(f"获取学生日志失败: {e}")
    
    def get_logs_by_student(self, student_id: str, page: int = 1, page_size: int = 20) -> Dict[str, Any]:
        """获取指定学生的日志列表"""
        try:
            # 获取总数
            count_query = "SELECT COUNT(*) as total FROM student_logs WHERE student_id = ?"
            count_result = db_manager.execute_query(count_query, (student_id,))
            total = count_result[0]['total'] if count_result else 0
            
            # 获取分页数据
            offset = (page - 1) * page_size
            query = """
                SELECT id, student_id, title, content, created_at, updated_at
                FROM student_logs
                WHERE student_id = ?
                ORDER BY created_at DESC
                LIMIT ? OFFSET ?
            """
            results = db_manager.execute_query(query, (student_id, page_size, offset))
            
            logs = [StudentLogResponse(**log) for log in results]
            
            return {
                "logs": logs,
                "total": total,
                "page": page,
                "page_size": page_size
            }
            
        except Exception as e:
            logger.error(f"获取学生日志列表失败: {e}")
            raise DatabaseException(f"获取学生日志列表失败: {e}")
    
    def get_all_logs(self, page: int = 1, page_size: int = 20) -> Dict[str, Any]:
        """获取所有学生日志"""
        try:
            # 获取总数
            count_query = "SELECT COUNT(*) as total FROM student_logs"
            count_result = db_manager.execute_query(count_query)
            total = count_result[0]['total'] if count_result else 0
            
            # 获取分页数据
            offset = (page - 1) * page_size
            query = """
                SELECT sl.id, sl.student_id, sl.title, sl.content, sl.created_at, sl.updated_at,
                       s.name as student_name
                FROM student_logs sl
                LEFT JOIN students s ON sl.student_id = s.student_id
                ORDER BY sl.created_at DESC
                LIMIT ? OFFSET ?
            """
            results = db_manager.execute_query(query, (page_size, offset))
            
            logs = []
            for log in results:
                log_data = dict(log)
                # 添加学生姓名信息
                log_data['student_name'] = log_data.pop('student_name', None)
                logs.append(StudentLogResponse(**{k: v for k, v in log_data.items() if k != 'student_name'}))
            
            return {
                "logs": logs,
                "total": total,
                "page": page,
                "page_size": page_size
            }
            
        except Exception as e:
            logger.error(f"获取所有学生日志失败: {e}")
            raise DatabaseException(f"获取所有学生日志失败: {e}")
    
    def update_log(self, log_id: int, log_data: StudentLogUpdate) -> Optional[StudentLogResponse]:
        """更新学生日志"""
        try:
            # 构建更新字段
            update_fields = []
            params = []
            
            if log_data.title is not None:
                update_fields.append("title = ?")
                params.append(log_data.title)
            
            if log_data.content is not None:
                update_fields.append("content = ?")
                params.append(log_data.content)
            
            if not update_fields:
                return self.get_log_by_id(log_id)
            
            update_fields.append("updated_at = CURRENT_TIMESTAMP")
            params.append(log_id)
            
            query = f"""
                UPDATE student_logs 
                SET {', '.join(update_fields)}
                WHERE id = ?
            """
            
            affected_rows = db_manager.execute_update(query, tuple(params))
            
            if affected_rows == 0:
                return None
                
            return self.get_log_by_id(log_id)
            
        except Exception as e:
            logger.error(f"更新学生日志失败: {e}")
            raise DatabaseException(f"更新学生日志失败: {e}")
    
    def delete_log(self, log_id: int) -> bool:
        """删除学生日志"""
        try:
            query = "DELETE FROM student_logs WHERE id = ?"
            affected_rows = db_manager.execute_update(query, (log_id,))
            return affected_rows > 0
            
        except Exception as e:
            logger.error(f"删除学生日志失败: {e}")
            raise DatabaseException(f"删除学生日志失败: {e}")
    
    def search_logs(self, keyword: str, student_id: Optional[str] = None, page: int = 1, page_size: int = 20) -> Dict[str, Any]:
        """搜索学生日志"""
        try:
            # 构建搜索条件
            where_conditions = ["(title LIKE ? OR content LIKE ?)"]
            params = [f"%{keyword}%", f"%{keyword}%"]
            
            if student_id:
                where_conditions.append("student_id = ?")
                params.append(student_id)
            
            where_clause = " AND ".join(where_conditions)
            
            # 获取总数
            count_query = f"SELECT COUNT(*) as total FROM student_logs WHERE {where_clause}"
            count_result = db_manager.execute_query(count_query, tuple(params))
            total = count_result[0]['total'] if count_result else 0
            
            # 获取分页数据
            offset = (page - 1) * page_size
            query = f"""
                SELECT sl.id, sl.student_id, sl.title, sl.content, sl.created_at, sl.updated_at,
                       s.name as student_name
                FROM student_logs sl
                LEFT JOIN students s ON sl.student_id = s.student_id
                WHERE {where_clause}
                ORDER BY sl.created_at DESC
                LIMIT ? OFFSET ?
            """
            params.extend([page_size, offset])
            results = db_manager.execute_query(query, tuple(params))
            
            logs = []
            for log in results:
                log_data = dict(log)
                log_data['student_name'] = log_data.pop('student_name', None)
                logs.append(StudentLogResponse(**{k: v for k, v in log_data.items() if k != 'student_name'}))
            
            return {
                "logs": logs,
                "total": total,
                "page": page,
                "page_size": page_size
            }
            
        except Exception as e:
            logger.error(f"搜索学生日志失败: {e}")
            raise DatabaseException(f"搜索学生日志失败: {e}")


# 创建全局服务实例
student_log_service = StudentLogService()