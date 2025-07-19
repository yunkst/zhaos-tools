"""
学生基础服务 - 处理学生的基础CRUD操作
"""

from typing import List, Optional, Dict, Any
from datetime import datetime

from app.core.database import db_manager
from app.core.logger import service_logger
from app.schemas.student import StudentCreate, StudentUpdate
from app.utils.exceptions import (
    StudentNotFoundException, 
    DuplicateStudentException,
    ServiceException
)
from app.utils.age_calculator import get_current_age


class StudentService:
    """学生基础服务类 - 负责基础CRUD操作"""
    
    def __init__(self):
        self.db = db_manager
    
    def _add_dynamic_age(self, student: Dict[str, Any]) -> Dict[str, Any]:
        """为单个学生添加动态年龄"""
        if student and student.get('id_card'):
            try:
                dynamic_age = get_current_age(student['id_card'])
                student['dynamic_age'] = dynamic_age
            except Exception:
                student['dynamic_age'] = student.get('age')
        else:
            student['dynamic_age'] = student.get('age')
        return student
    
    def _add_dynamic_age_to_list(self, students: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """为学生列表添加动态年龄"""
        return [self._add_dynamic_age(student) for student in students]
    
    def get_student_by_id(self, student_id: int) -> Optional[Dict[str, Any]]:
        """根据ID获取学生信息"""
        try:
            query = """
                SELECT s.id, s.name, s.student_id, s.gender, s.age, s.class_id, c.name as class_name, 
                       s.phone, s.email, s.qq, s.wechat, s.address, s.father_job, s.mother_job, 
                       s.contact_info, s.notes, s.chinese_score, s.math_score, s.english_score, 
                       s.science_score, s.total_score, s.id_card, s.primary_school, s.height, 
                       s.vision, s.class_position_intention, s.visit_time, s.good_subjects,
                       s.created_at, s.updated_at 
                FROM students s
                LEFT JOIN classes c ON s.class_id = c.id
                WHERE s.id = ?
            """
            result = self.db.execute_query(query, (student_id,))
            
            if not result:
                return None
            
            student = result[0]
            # 添加动态年龄
            student_with_age = self._add_dynamic_age(student)
            
            service_logger.info(f"获取学生信息成功: {student['name']}")
            return student_with_age
            
        except Exception as e:
            service_logger.error(f"获取学生信息失败: {e}")
            raise ServiceException(f"获取学生信息失败: {e}")
    
    def get_student_by_student_id(self, student_id: str) -> Optional[Dict[str, Any]]:
        """根据学号获取学生信息"""
        try:
            query = """
                SELECT s.id, s.name, s.student_id, s.gender, s.age, s.class_id, c.name as class_name, 
                       s.phone, s.email, s.qq, s.wechat, s.address, s.father_job, s.mother_job, 
                       s.contact_info, s.notes, s.chinese_score, s.math_score, s.english_score, 
                       s.science_score, s.total_score, s.id_card, s.primary_school, s.height, 
                       s.vision, s.class_position_intention, s.visit_time, s.good_subjects,
                       s.created_at, s.updated_at 
                FROM students s
                LEFT JOIN classes c ON s.class_id = c.id
                WHERE s.student_id = ?
            """
            result = self.db.execute_query(query, (student_id,))
            
            if not result:
                return None
            
            student = result[0]
            # 添加动态年龄
            student_with_age = self._add_dynamic_age(student)
            
            service_logger.info(f"根据学号获取学生信息成功: {student['name']}")
            return student_with_age
            
        except Exception as e:
            service_logger.error(f"根据学号获取学生信息失败: {e}")
            raise ServiceException(f"根据学号获取学生信息失败: {e}")
    
    def create_student(self, student_data: StudentCreate) -> Dict[str, Any]:
        """创建新学生"""
        try:
            # 检查学号是否已存在
            existing_student = self.get_student_by_student_id(student_data.student_id)
            if existing_student:
                raise DuplicateStudentException(f"学号 {student_data.student_id} 已存在")
            
            # 插入新学生
            query = """
                INSERT INTO students (
                    name, student_id, gender, age, class_name, phone, email, qq, wechat, 
                    address, father_job, mother_job, contact_info, notes, chinese_score, 
                    math_score, english_score, science_score, total_score, id_card, 
                    primary_school, height, vision, class_position_intention, visit_time, 
                    good_subjects
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """
            
            new_id = self.db.execute_insert(query, (
                student_data.name,
                student_data.student_id,
                student_data.gender.value if student_data.gender else None,
                student_data.age,
                student_data.class_name,
                student_data.phone,
                student_data.email,
                student_data.qq,
                student_data.wechat,
                student_data.address,
                student_data.father_job,
                student_data.mother_job,
                student_data.contact_info,
                student_data.notes,
                student_data.chinese_score,
                student_data.math_score,
                student_data.english_score,
                student_data.science_score,
                student_data.total_score,
                student_data.id_card,
                student_data.primary_school,
                student_data.height,
                student_data.vision,
                student_data.class_position_intention,
                student_data.visit_time,
                student_data.good_subjects
            ))
            
            # 获取新创建的学生信息
            new_student = self.get_student_by_id(new_id)
            if not new_student:
                raise ServiceException(f"创建学生失败，新学生ID {new_id} 不存在")
            
            service_logger.info(f"创建学生成功: {student_data.name} ({student_data.student_id})")
            return new_student
            
        except DuplicateStudentException:
            raise
        except Exception as e:
            service_logger.error(f"创建学生失败: {e}")
            raise ServiceException(f"创建学生失败: {e}")
    
    def update_student(self, student_id: int, student_data: StudentUpdate) -> Dict[str, Any]:
        """更新学生信息"""
        try:
            # 检查学生是否存在
            existing_student = self.get_student_by_id(student_id)
            if not existing_student:
                raise StudentNotFoundException(f"未找到ID为 {student_id} 的学生")
            
            # 如果更新学号，检查新学号是否已存在
            if student_data.student_id and student_data.student_id != existing_student['student_id']:
                duplicate_student = self.get_student_by_student_id(student_data.student_id)
                if duplicate_student:
                    raise DuplicateStudentException(f"学号 {student_data.student_id} 已存在")
            
            # 构建更新字段
            update_fields = []
            update_values = []
            
            for field, value in student_data.dict(exclude_unset=True).items():
                if field == 'gender' and value:
                    update_fields.append(f"{field} = ?")
                    update_values.append(value.value)
                else:
                    update_fields.append(f"{field} = ?")
                    update_values.append(value)
            
            if not update_fields:
                return existing_student
            
            # 添加更新时间
            update_fields.append("updated_at = ?")
            update_values.append(datetime.now())
            
            # 添加WHERE条件的参数
            update_values.append(student_id)
            
            query = f"UPDATE students SET {', '.join(update_fields)} WHERE id = ?"
            affected_rows = self.db.execute_update(query, tuple(update_values))
            
            if affected_rows == 0:
                raise ServiceException(f"更新学生信息失败，学生ID {student_id} 可能已被删除")
            
            # 获取更新后的学生信息
            updated_student = self.get_student_by_id(student_id)
            if not updated_student:
                raise ServiceException(f"更新学生信息失败，学生ID {student_id} 可能已被删除")
            
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
            existing_student = self.get_student_by_id(student_id)
            if not existing_student:
                raise StudentNotFoundException(f"未找到ID为 {student_id} 的学生")
            
            # 删除学生
            query = "DELETE FROM students WHERE id = ?"
            affected_rows = self.db.execute_update(query, (student_id,))
            
            if affected_rows > 0:
                service_logger.info(f"删除学生成功: {existing_student['name']}")
                return True
            else:
                return False
            
        except StudentNotFoundException:
            raise
        except Exception as e:
            service_logger.error(f"删除学生失败: {e}")
            raise ServiceException(f"删除学生失败: {e}")
    
    def get_class_list(self) -> List[str]:
        """获取所有班级列表"""
        try:
            query = """
                SELECT DISTINCT class_name 
                FROM students 
                WHERE class_name IS NOT NULL AND class_name != ''
                ORDER BY class_name
            """
            result = self.db.execute_query(query)
            
            classes = [row['class_name'] for row in result]
            service_logger.info(f"获取班级列表成功，共 {len(classes)} 个班级")
            return classes
            
        except Exception as e:
            service_logger.error(f"获取班级列表失败: {e}")
            raise ServiceException(f"获取班级列表失败: {e}")
    
    def get_classes(self) -> List[str]:
        """获取所有班级列表 - 兼容性方法"""
        return self.get_class_list()