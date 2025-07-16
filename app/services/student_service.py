"""
学生服务层 - 处理学生相关的业务逻辑
"""

from typing import List, Optional, Dict, Any
from datetime import datetime

from app.core.database import db_manager
from app.core.logger import service_logger
from app.schemas.student import StudentCreate, StudentUpdate, StudentResponse, StudentBatchImport, ExcelImportResult, BatchOperationResult
from app.utils.exceptions import (
    StudentNotFoundException, 
    DuplicateStudentException,
    ServiceException
)
from app.utils.age_calculator import get_current_age


class StudentService:
    """学生服务类"""
    
    def __init__(self):
        self.db = db_manager
    
    def _add_dynamic_age(self, student_data: Dict[str, Any]) -> Dict[str, Any]:
        """为学生数据添加动态计算的年龄"""
        if student_data and student_data.get('id_card'):
            age = get_current_age(student_data['id_card'])
            student_data['age'] = age
        else:
            student_data['age'] = None
        return student_data
    
    def _add_dynamic_age_to_list(self, students_list: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """为学生列表添加动态计算的年龄"""
        return [self._add_dynamic_age(student) for student in students_list]
    
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
                SELECT s.id, s.name, s.student_id, s.gender, s.age, s.class_id, c.name as class_name, 
                       s.phone, s.email, s.qq, s.wechat, s.address, s.father_job, s.mother_job, 
                       s.contact_info, s.notes, s.chinese_score, s.math_score, s.english_score, 
                       s.science_score, s.total_score, s.id_card, s.primary_school, s.height, 
                       s.vision, s.class_position_intention, s.visit_time, s.good_subjects,
                       s.created_at, s.updated_at 
                FROM students s
                LEFT JOIN classes c ON s.class_id = c.id
                ORDER BY s.created_at DESC 
                LIMIT ? OFFSET ?
            """
            students = self.db.execute_query(query, (page_size, offset))
            
            # 为学生列表添加动态年龄
            students_with_age = self._add_dynamic_age_to_list(students)
            
            service_logger.info(f"获取学生列表成功，共 {len(students)} 条记录")
            
            return {
                'students': students_with_age,
                'total': total,
                'page': page,
                'page_size': page_size,
                'total_pages': (total + page_size - 1) // page_size
            }
            
        except Exception as e:
            service_logger.error(f"获取学生列表失败: {e}")
            raise ServiceException(f"获取学生列表失败: {e}")
    
    def get_students_by_class_id(self, class_id: int, page: int = 1, page_size: int = 20) -> Dict[str, Any]:
        """根据班级ID获取学生列表"""
        try:
            # 计算偏移量
            offset = (page - 1) * page_size
            
            # 查询学生列表
            query = """
                SELECT s.*, c.name as class_name
                FROM students s
                LEFT JOIN classes c ON s.class_id = c.id
                WHERE s.class_id = ?
                ORDER BY s.created_at DESC
                LIMIT ? OFFSET ?
            """
            students_data = self.db.execute_query(query, (class_id, page_size, offset))
            
            # 查询总数
            count_query = "SELECT COUNT(*) as total FROM students WHERE class_id = ?"
            count_result = self.db.execute_query(count_query, (class_id,))
            total = count_result[0]['total'] if count_result else 0
            
            # 为学生数据添加动态年龄
            students_data_with_age = self._add_dynamic_age_to_list(students_data)
            
            # 转换为学生对象
            students = []
            for student_data in students_data_with_age:
                student = StudentResponse(**student_data)
                students.append(student)
            
            service_logger.info(f"获取班级学生列表成功: class_id={class_id}, 共{total}名学生")
            return {
                'students': students,
                'total': total,
                'page': page,
                'page_size': page_size,
                'total_pages': (total + page_size - 1) // page_size
            }
            
        except Exception as e:
            service_logger.error(f"获取班级学生列表失败: {e}")
            raise ServiceException(f"获取班级学生列表失败: {e}")
    
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
                raise StudentNotFoundException(f"未找到ID为 {student_id} 的学生")
            
            # 为学生数据添加动态年龄
            student_with_age = self._add_dynamic_age(result[0])
            
            service_logger.info(f"获取学生信息成功: {result[0]['name']}")
            return student_with_age
            
        except StudentNotFoundException:
            raise
        except Exception as e:
            service_logger.error(f"获取学生信息失败: {e}")
            raise ServiceException(f"获取学生信息失败: {e}")
    
    def get_student_by_student_id(self, student_id: str) -> Optional[Dict[str, Any]]:
        """根据学号获取学生信息"""
        try:
            query = """
                SELECT id, name, student_id, gender, age, class_name, phone, email, 
                       qq, wechat, address, father_job, mother_job, contact_info, notes, 
                       created_at, updated_at 
                FROM students 
                WHERE student_id = ?
            """
            result = self.db.execute_query(query, (student_id,))
            
            if not result:
                return None
            
                service_logger.info(f"根据学号获取学生信息成功: {result[0]['name']}")
                return result[0]
            
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
                    name, student_id, gender, age, class_name, phone, email, 
                    qq, wechat, address, father_job, mother_job, contact_info, notes,
                    chinese_score, math_score, english_score, science_score, total_score,
                    id_card, primary_school, height, vision, class_position_intention,
                    visit_time, good_subjects
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
    
    def search_students(self, keyword: str, page: int = 1, page_size: int = 20) -> Dict[str, Any]:
        """搜索学生"""
        try:
            # 计算偏移量
            offset = (page - 1) * page_size
            
            # 搜索条件
            search_condition = """
                WHERE name LIKE ? OR student_id LIKE ? OR class_name LIKE ? 
                OR phone LIKE ? OR email LIKE ?
            """
            search_params = [f"%{keyword}%"] * 5
            
            # 获取总数
            total_query = f"SELECT COUNT(*) as total FROM students {search_condition}"
            total_result = self.db.execute_query(total_query, search_params)
            total = total_result[0]['total'] if total_result else 0
            
            # 获取搜索结果
            query = f"""
                SELECT id, name, student_id, gender, age, class_name, phone, email, 
                       qq, wechat, address, father_job, mother_job, contact_info, notes, 
                       created_at, updated_at 
                FROM students 
                {search_condition}
                ORDER BY created_at DESC 
                LIMIT ? OFFSET ?
            """
            
            students = self.db.execute_query(query, search_params + [page_size, offset])
            
            service_logger.info(f"搜索学生成功，关键词: {keyword}，结果: {len(students)} 条")
            
            return {
                'students': students,
                'total': total,
                'page': page,
                'page_size': page_size,
                'total_pages': (total + page_size - 1) // page_size
            }
            
        except Exception as e:
            service_logger.error(f"搜索学生失败: {e}")
            raise ServiceException(f"搜索学生失败: {e}")
    
    def batch_import_students(self, batch_data: StudentBatchImport) -> Dict[str, Any]:
        """批量导入学生"""
        try:
            success_count = 0
            failed_count = 0
            failed_records = []
            
            for student_data in batch_data.students:
                try:
                    self.create_student(student_data)
                    success_count += 1
                except (DuplicateStudentException, ServiceException) as e:
                    failed_count += 1
                    failed_records.append({
                        'student_id': student_data.student_id,
                        'name': student_data.name,
                        'error': str(e)
                    })
            
            service_logger.info(f"批量导入学生完成，成功: {success_count}，失败: {failed_count}")
            
            return {
                'success_count': success_count,
                'failed_count': failed_count,
                'failed_records': failed_records,
                'total_count': len(batch_data.students)
            }
            
        except Exception as e:
            service_logger.error(f"批量导入学生失败: {e}")
            raise ServiceException(f"批量导入学生失败: {e}")
    
    def get_students_by_class(self, class_name: str) -> List[Dict[str, Any]]:
        """根据班级获取学生列表"""
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
                WHERE c.name = ?
                ORDER BY s.student_id
            """
            students = self.db.execute_query(query, (class_name,))
            
            # 为学生列表添加动态年龄
            students_with_age = self._add_dynamic_age_to_list(students)
            
            service_logger.info(f"根据班级获取学生列表成功: {class_name}，共 {len(students)} 人")
            return students_with_age
            
        except Exception as e:
            service_logger.error(f"根据班级获取学生列表失败: {e}")
            raise ServiceException(f"根据班级获取学生列表失败: {e}")
    
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
    
    def import_students_from_excel(self, students: List[StudentCreate]) -> ExcelImportResult:
        """从Excel导入学生数据"""
        try:
            result = ExcelImportResult(
                success_count=0,
                failed_count=0,
                total_count=len(students),
                errors=[],
                success_students=[],
                failed_students=[]
            )
            
            for student_data in students:
                try:
                    # 检查学号是否已存在
                    existing_student = self.get_student_by_student_id(student_data.student_id)
                    if existing_student:
                        # 更新现有学生信息
                        self.update_student(existing_student['id'], StudentUpdate(**student_data.dict()))
                        result.success_count += 1
                        result.success_students.append(f"{student_data.name}(更新)")
                    else:
                        # 创建新学生
                        self.create_student(student_data)
                        result.success_count += 1
                        result.success_students.append(f"{student_data.name}(新增)")
                        
                except Exception as e:
                    result.failed_count += 1
                    error_msg = f"导入学生 {student_data.name}({student_data.student_id}) 失败: {str(e)}"
                    result.errors.append(error_msg)
                    result.failed_students.append({
                        'name': student_data.name,
                        'student_id': student_data.student_id,
                        'error': str(e)
                    })
                    service_logger.warning(error_msg)
            
            service_logger.info(f"Excel导入完成，成功: {result.success_count}, 失败: {result.failed_count}")
            return result
            
        except Exception as e:
            service_logger.error(f"Excel导入失败: {e}")
            raise ServiceException(f"Excel导入失败: {e}")

    def batch_update_students(self, student_ids: List[int], update_data: Dict[str, Any]) -> BatchOperationResult:
        """批量更新学生信息"""
        try:
            result = BatchOperationResult(
                success_count=0,
                failed_count=0,
                total_count=len(student_ids),
                errors=[],
                success_ids=[],
                failed_ids=[]
            )
            
            for student_id in student_ids:
                try:
                    # 检查学生是否存在
                    try:
                        existing_student = self.get_student_by_id(student_id)
                    except StudentNotFoundException:
                        result.failed_count += 1
                        error_msg = f"学生ID {student_id} 不存在"
                        result.errors.append(error_msg)
                        result.failed_ids.append(student_id)
                        continue
                    
                    # 构建更新SQL
                    set_clauses = []
                    params = []
                    
                    for key, value in update_data.items():
                        set_clauses.append(f"{key} = ?")
                        params.append(value)
                    
                    # 添加更新时间
                    set_clauses.append("updated_at = ?")
                    params.append(datetime.now())
                    
                    # 添加WHERE条件
                    params.append(student_id)
                    
                    # 执行更新
                    update_query = f"""
                        UPDATE students 
                        SET {', '.join(set_clauses)}
                        WHERE id = ?
                    """
                    
                    affected_rows = self.db.execute_update(update_query, tuple(params))
                    
                    if affected_rows == 0:
                        result.failed_count += 1
                        error_msg = f"学生ID {student_id} 更新失败，可能已被删除"
                        result.errors.append(error_msg)
                        result.failed_ids.append(student_id)
                        continue
                    
                    result.success_count += 1
                    result.success_ids.append(student_id)
                    
                except Exception as e:
                    result.failed_count += 1
                    error_msg = f"更新学生ID {student_id} 失败: {str(e)}"
                    result.errors.append(error_msg)
                    result.failed_ids.append(student_id)
                    service_logger.warning(error_msg)
            
            service_logger.info(f"批量更新完成，成功: {result.success_count}, 失败: {result.failed_count}")
            return result
            
        except Exception as e:
            service_logger.error(f"批量更新失败: {e}")
            raise ServiceException(f"批量更新失败: {e}")

    def batch_delete_students(self, student_ids: List[int]) -> BatchOperationResult:
        """批量删除学生"""
        try:
            result = BatchOperationResult(
                success_count=0,
                failed_count=0,
                total_count=len(student_ids),
                errors=[],
                success_ids=[],
                failed_ids=[]
            )
            
            for student_id in student_ids:
                try:
                    # 检查学生是否存在
                    try:
                        existing_student = self.get_student_by_id(student_id)
                    except StudentNotFoundException:
                        result.failed_count += 1
                        error_msg = f"学生ID {student_id} 不存在"
                        result.errors.append(error_msg)
                        result.failed_ids.append(student_id)
                        continue
                    
                    # 执行删除
                    delete_query = "DELETE FROM students WHERE id = ?"
                    affected_rows = self.db.execute_update(delete_query, (student_id,))
                    
                    if affected_rows == 0:
                        result.failed_count += 1
                        error_msg = f"学生ID {student_id} 删除失败，可能已被删除"
                        result.errors.append(error_msg)
                        result.failed_ids.append(student_id)
                        continue
                    
                    result.success_count += 1
                    result.success_ids.append(student_id)
                    
                except Exception as e:
                    result.failed_count += 1
                    error_msg = f"删除学生ID {student_id} 失败: {str(e)}"
                    result.errors.append(error_msg)
                    result.failed_ids.append(student_id)
                    service_logger.warning(error_msg)
            
            service_logger.info(f"批量删除完成，成功: {result.success_count}, 失败: {result.failed_count}")
            return result
            
        except Exception as e:
            service_logger.error(f"批量删除失败: {e}")
            raise ServiceException(f"批量删除失败: {e}")


# 创建全局学生服务实例
student_service = StudentService() 