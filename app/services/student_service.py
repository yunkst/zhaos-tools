"""
学生服务层 - 处理学生相关的业务逻辑
"""

from typing import List, Optional, Dict, Any
from datetime import datetime

from app.core.database import db_manager
from app.core.logger import service_logger
from app.schemas.student import StudentCreate, StudentUpdate, StudentResponse
from app.utils.exceptions import (
    StudentNotFoundException, 
    DuplicateStudentException,
    ServiceException
)


class StudentService:
    """学生服务类"""
    
    def __init__(self):
        self.db = db_manager
    
    def get_all_students(self, page: int = 1, page_size: int = 20) -> Dict[str, Any]:
        """获取所有学生列表"""
        try:
            # 计算偏移量
            offset = (page - 1) * page_size
            
            # 获取总数
            total_query = "SELECT COUNT(*) as total FROM students"
            total_result = self.db.execute_query(total_query)
            total = total_result[0]['total'] if total_result else 0
            
            # 获取学生列表
            query = """
                SELECT id, name, student_id, class_name, contact_info, notes, 
                       created_at, updated_at 
                FROM students 
                ORDER BY created_at DESC 
                LIMIT ? OFFSET ?
            """
            students = self.db.execute_query(query, (page_size, offset))
            
            service_logger.info(f"获取学生列表成功，共 {len(students)} 条记录")
            
            return {
                'students': students,
                'total': total,
                'page': page,
                'page_size': page_size,
                'total_pages': (total + page_size - 1) // page_size
            }
            
        except Exception as e:
            service_logger.error(f"获取学生列表失败: {e}")
            raise ServiceException(f"获取学生列表失败: {e}")
    
    def get_student_by_id(self, student_id: int) -> Dict[str, Any]:
        """根据ID获取学生信息"""
        try:
            query = """
                SELECT id, name, student_id, class_name, contact_info, notes, 
                       created_at, updated_at 
                FROM students 
                WHERE id = ?
            """
            result = self.db.execute_query(query, (student_id,))
            
            if not result:
                raise StudentNotFoundException(str(student_id))
            
            student = result[0]
            service_logger.info(f"获取学生信息成功: {student['name']}")
            
            return student
            
        except StudentNotFoundException:
            raise
        except Exception as e:
            service_logger.error(f"获取学生信息失败: {e}")
            raise ServiceException(f"获取学生信息失败: {e}")
    
    def get_student_by_student_id(self, student_id: str) -> Optional[Dict[str, Any]]:
        """根据学号获取学生信息"""
        try:
            query = """
                SELECT id, name, student_id, class_name, contact_info, notes, 
                       created_at, updated_at 
                FROM students 
                WHERE student_id = ?
            """
            result = self.db.execute_query(query, (student_id,))
            
            if result:
                service_logger.info(f"根据学号获取学生信息成功: {result[0]['name']}")
                return result[0]
            
            return None
            
        except Exception as e:
            service_logger.error(f"根据学号获取学生信息失败: {e}")
            raise ServiceException(f"根据学号获取学生信息失败: {e}")
    
    def create_student(self, student_data: StudentCreate) -> Dict[str, Any]:
        """创建新学生"""
        try:
            # 检查学号是否已存在
            existing_student = self.get_student_by_student_id(student_data.student_id)
            if existing_student:
                raise DuplicateStudentException(student_data.student_id)
            
            # 插入新学生
            query = """
                INSERT INTO students (name, student_id, class_name, contact_info, notes)
                VALUES (?, ?, ?, ?, ?)
            """
            new_id = self.db.execute_insert(
                query, 
                (
                    student_data.name,
                    student_data.student_id,
                    student_data.class_name,
                    student_data.contact_info,
                    student_data.notes
                )
            )
            
            # 获取新创建的学生信息
            new_student = self.get_student_by_id(new_id)
            
            service_logger.info(f"创建学生成功: {student_data.name}")
            
            return new_student
            
        except (DuplicateStudentException, StudentNotFoundException):
            raise
        except Exception as e:
            service_logger.error(f"创建学生失败: {e}")
            raise ServiceException(f"创建学生失败: {e}")
    
    def update_student(self, student_id: int, student_data: StudentUpdate) -> Dict[str, Any]:
        """更新学生信息"""
        try:
            # 检查学生是否存在
            existing_student = self.get_student_by_id(student_id)
            
            # 如果要更新学号，检查新学号是否已被其他学生使用
            if student_data.student_id and student_data.student_id != existing_student['student_id']:
                other_student = self.get_student_by_student_id(student_data.student_id)
                if other_student and other_student['id'] != student_id:
                    raise DuplicateStudentException(student_data.student_id)
            
            # 构建更新字段
            update_fields = []
            params = []
            
            if student_data.name is not None:
                update_fields.append("name = ?")
                params.append(student_data.name)
            
            if student_data.student_id is not None:
                update_fields.append("student_id = ?")
                params.append(student_data.student_id)
            
            if student_data.class_name is not None:
                update_fields.append("class_name = ?")
                params.append(student_data.class_name)
            
            if student_data.contact_info is not None:
                update_fields.append("contact_info = ?")
                params.append(student_data.contact_info)
            
            if student_data.notes is not None:
                update_fields.append("notes = ?")
                params.append(student_data.notes)
            
            if not update_fields:
                return existing_student
            
            # 添加更新时间
            update_fields.append("updated_at = CURRENT_TIMESTAMP")
            params.append(student_id)
            
            # 执行更新
            query = f"UPDATE students SET {', '.join(update_fields)} WHERE id = ?"
            self.db.execute_update(query, tuple(params))
            
            # 获取更新后的学生信息
            updated_student = self.get_student_by_id(student_id)
            
            service_logger.info(f"更新学生信息成功: {updated_student['name']}")
            
            return updated_student
            
        except (StudentNotFoundException, DuplicateStudentException):
            raise
        except Exception as e:
            service_logger.error(f"更新学生信息失败: {e}")
            raise ServiceException(f"更新学生信息失败: {e}")
    
    def delete_student(self, student_id: int) -> bool:
        """删除学生"""
        try:
            # 检查学生是否存在
            student = self.get_student_by_id(student_id)
            
            # 删除学生
            query = "DELETE FROM students WHERE id = ?"
            affected_rows = self.db.execute_update(query, (student_id,))
            
            if affected_rows > 0:
                service_logger.info(f"删除学生成功: {student['name']}")
                return True
            
            return False
            
        except StudentNotFoundException:
            raise
        except Exception as e:
            service_logger.error(f"删除学生失败: {e}")
            raise ServiceException(f"删除学生失败: {e}")
    
    def search_students(self, keyword: str, page: int = 1, page_size: int = 20) -> Dict[str, Any]:
        """搜索学生"""
        try:
            # 计算偏移量
            offset = (page - 1) * page_size
            
            # 搜索条件
            search_pattern = f"%{keyword}%"
            
            # 获取总数
            total_query = """
                SELECT COUNT(*) as total FROM students 
                WHERE name LIKE ? OR student_id LIKE ? OR class_name LIKE ?
            """
            total_result = self.db.execute_query(total_query, (search_pattern, search_pattern, search_pattern))
            total = total_result[0]['total'] if total_result else 0
            
            # 搜索学生
            query = """
                SELECT id, name, student_id, class_name, contact_info, notes, 
                       created_at, updated_at 
                FROM students 
                WHERE name LIKE ? OR student_id LIKE ? OR class_name LIKE ?
                ORDER BY created_at DESC 
                LIMIT ? OFFSET ?
            """
            students = self.db.execute_query(
                query, 
                (search_pattern, search_pattern, search_pattern, page_size, offset)
            )
            
            service_logger.info(f"搜索学生成功，关键词: {keyword}，找到 {len(students)} 条记录")
            
            return {
                'students': students,
                'total': total,
                'page': page,
                'page_size': page_size,
                'total_pages': (total + page_size - 1) // page_size,
                'keyword': keyword
            }
            
        except Exception as e:
            service_logger.error(f"搜索学生失败: {e}")
            raise ServiceException(f"搜索学生失败: {e}")


# 创建全局学生服务实例
student_service = StudentService() 