"""
学生批量操作服务 - 处理学生的批量操作
"""

from typing import List, Dict, Any, Optional
from datetime import datetime

from app.core.database import db_manager
from app.core.logger import service_logger
from app.schemas.student import StudentUpdate
from app.utils.exceptions import ServiceException, StudentNotFoundException
from app.utils.age_calculator import get_current_age


class StudentBatchService:
    """学生批量操作服务类"""
    
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
    
    def batch_update_students(self, updates: List[Dict[str, Any]]) -> Dict[str, Any]:
        """批量更新学生信息
        
        Args:
            updates: 更新数据列表，每个元素包含 {'id': student_id, 'data': update_data}
        
        Returns:
            Dict: 包含成功和失败统计的结果
        """
        try:
            success_count = 0
            failed_count = 0
            failed_items = []
            
            for update_item in updates:
                try:
                    student_id = update_item.get('id')
                    update_data = update_item.get('data', {})
                    
                    if not student_id:
                        failed_count += 1
                        failed_items.append({
                            'item': update_item,
                            'error': '缺少学生ID'
                        })
                        continue
                    
                    # 检查学生是否存在
                    check_query = "SELECT id, name FROM students WHERE id = ?"
                    existing_student = self.db.execute_query(check_query, (student_id,))
                    
                    if not existing_student:
                        failed_count += 1
                        failed_items.append({
                            'item': update_item,
                            'error': f'未找到ID为 {student_id} 的学生'
                        })
                        continue
                    
                    # 构建更新字段
                    update_fields = []
                    update_values = []
                    
                    for field, value in update_data.items():
                        if field in ['id', 'created_at']:  # 跳过不允许更新的字段
                            continue
                        update_fields.append(f"{field} = ?")
                        update_values.append(value)
                    
                    if not update_fields:
                        success_count += 1  # 没有需要更新的字段，视为成功
                        continue
                    
                    # 添加更新时间
                    update_fields.append("updated_at = ?")
                    update_values.append(datetime.now())
                    
                    # 添加WHERE条件的参数
                    update_values.append(student_id)
                    
                    query = f"UPDATE students SET {', '.join(update_fields)} WHERE id = ?"
                    affected_rows = self.db.execute_update(query, tuple(update_values))
                    
                    if affected_rows > 0:
                        success_count += 1
                    else:
                        failed_count += 1
                        failed_items.append({
                            'item': update_item,
                            'error': '更新失败，可能学生已被删除'
                        })
                        
                except Exception as e:
                    failed_count += 1
                    failed_items.append({
                        'item': update_item,
                        'error': str(e)
                    })
            
            result = {
                'success_count': success_count,
                'failed_count': failed_count,
                'total_count': len(updates),
                'failed_items': failed_items
            }
            
            service_logger.info(f"批量更新学生完成: 成功 {success_count}, 失败 {failed_count}")
            return result
            
        except Exception as e:
            service_logger.error(f"批量更新学生失败: {e}")
            raise ServiceException(f"批量更新学生失败: {e}")
    
    def batch_delete_students(self, student_ids: List[int]) -> Dict[str, Any]:
        """批量删除学生
        
        Args:
            student_ids: 要删除的学生ID列表
        
        Returns:
            Dict: 包含成功和失败统计的结果
        """
        try:
            success_count = 0
            failed_count = 0
            failed_items = []
            
            for student_id in student_ids:
                try:
                    # 检查学生是否存在
                    check_query = "SELECT id, name FROM students WHERE id = ?"
                    existing_student = self.db.execute_query(check_query, (student_id,))
                    
                    if not existing_student:
                        failed_count += 1
                        failed_items.append({
                            'id': student_id,
                            'error': f'未找到ID为 {student_id} 的学生'
                        })
                        continue
                    
                    # 删除学生
                    delete_query = "DELETE FROM students WHERE id = ?"
                    affected_rows = self.db.execute_update(delete_query, (student_id,))
                    
                    if affected_rows > 0:
                        success_count += 1
                        service_logger.info(f"删除学生成功: {existing_student[0]['name']}")
                    else:
                        failed_count += 1
                        failed_items.append({
                            'id': student_id,
                            'error': '删除失败'
                        })
                        
                except Exception as e:
                    failed_count += 1
                    failed_items.append({
                        'id': student_id,
                        'error': str(e)
                    })
            
            result = {
                'success_count': success_count,
                'failed_count': failed_count,
                'total_count': len(student_ids),
                'failed_items': failed_items
            }
            
            service_logger.info(f"批量删除学生完成: 成功 {success_count}, 失败 {failed_count}")
            return result
            
        except Exception as e:
            service_logger.error(f"批量删除学生失败: {e}")
            raise ServiceException(f"批量删除学生失败: {e}")
    
    def get_students_by_class(self, class_name: str, page: int = 1, page_size: int = 20) -> Dict[str, Any]:
        """根据班级获取学生列表
        
        Args:
            class_name: 班级名称
            page: 页码
            page_size: 每页数量
        
        Returns:
            Dict: 包含学生列表和分页信息的结果
        """
        try:
            offset = (page - 1) * page_size
            
            # 获取总数
            count_query = "SELECT COUNT(*) as total FROM students WHERE class_name = ?"
            count_result = self.db.execute_query(count_query, (class_name,))
            total = count_result[0]['total'] if count_result else 0
            
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
                WHERE s.class_name = ?
                ORDER BY s.student_id
                LIMIT ? OFFSET ?
            """
            
            students = self.db.execute_query(query, (class_name, page_size, offset))
            
            # 添加动态年龄
            students_with_age = self._add_dynamic_age_to_list(students)
            
            result = {
                'students': students_with_age,
                'total': total,
                'page': page,
                'page_size': page_size,
                'total_pages': (total + page_size - 1) // page_size
            }
            
            service_logger.info(f"获取班级 {class_name} 学生列表成功，共 {len(students)} 条记录")
            return result
            
        except Exception as e:
            service_logger.error(f"获取班级学生列表失败: {e}")
            raise ServiceException(f"获取班级学生列表失败: {e}")
    
    def get_students_by_class_id(self, class_id: int, page: int = 1, page_size: int = 20) -> Dict[str, Any]:
        """根据班级ID获取学生列表
        
        Args:
            class_id: 班级ID
            page: 页码
            page_size: 每页数量
        
        Returns:
            Dict: 包含学生列表和分页信息的结果
        """
        try:
            offset = (page - 1) * page_size
            
            # 获取总数
            count_query = "SELECT COUNT(*) as total FROM students WHERE class_id = ?"
            count_result = self.db.execute_query(count_query, (class_id,))
            total = count_result[0]['total'] if count_result else 0
            
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
                WHERE s.class_id = ?
                ORDER BY s.student_id
                LIMIT ? OFFSET ?
            """
            
            students = self.db.execute_query(query, (class_id, page_size, offset))
            
            # 添加动态年龄
            students_with_age = self._add_dynamic_age_to_list(students)
            
            result = {
                'students': students_with_age,
                'total': total,
                'page': page,
                'page_size': page_size,
                'total_pages': (total + page_size - 1) // page_size
            }
            
            service_logger.info(f"获取班级ID {class_id} 学生列表成功，共 {len(students)} 条记录")
            return result
            
        except Exception as e:
            service_logger.error(f"获取班级学生列表失败: {e}")
            raise ServiceException(f"获取班级学生列表失败: {e}")
    
    def get_students_by_ids(self, student_ids: List[int]) -> List[Dict[str, Any]]:
        """根据ID列表批量获取学生信息
        
        Args:
            student_ids: 学生ID列表
        
        Returns:
            List: 学生信息列表
        """
        try:
            if not student_ids:
                return []
            
            # 构建IN查询
            placeholders = ','.join(['?' for _ in student_ids])
            query = f"""
                SELECT s.id, s.name, s.student_id, s.gender, s.age, s.class_id, c.name as class_name, 
                       s.phone, s.email, s.qq, s.wechat, s.address, s.father_job, s.mother_job, 
                       s.contact_info, s.notes, s.chinese_score, s.math_score, s.english_score, 
                       s.science_score, s.total_score, s.id_card, s.primary_school, s.height, 
                       s.vision, s.class_position_intention, s.visit_time, s.good_subjects,
                       s.created_at, s.updated_at 
                FROM students s
                LEFT JOIN classes c ON s.class_id = c.id
                WHERE s.id IN ({placeholders})
                ORDER BY s.student_id
            """
            
            students = self.db.execute_query(query, tuple(student_ids))
            
            # 添加动态年龄
            students_with_age = self._add_dynamic_age_to_list(students)
            
            service_logger.info(f"批量获取学生信息成功，共 {len(students)} 条记录")
            return students_with_age
            
        except Exception as e:
            service_logger.error(f"批量获取学生信息失败: {e}")
            raise ServiceException(f"批量获取学生信息失败: {e}")