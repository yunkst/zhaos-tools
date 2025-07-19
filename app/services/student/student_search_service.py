"""
学生搜索服务 - 处理学生的搜索和查询功能
"""

from typing import List, Dict, Any, Optional
from datetime import datetime

from app.core.database import db_manager
from app.core.logger import service_logger
from app.utils.exceptions import ServiceException
from app.utils.age_calculator import get_current_age


class StudentSearchService:
    """学生搜索服务类"""
    
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
    
    def get_students(self, 
                    page: int = 1, 
                    page_size: int = 20, 
                    class_name: Optional[str] = None,
                    search_term: Optional[str] = None,
                    sort_by: str = 'student_id',
                    sort_order: str = 'asc') -> Dict[str, Any]:
        """获取学生列表（支持分页、搜索、排序）
        
        Args:
            page: 页码
            page_size: 每页数量
            class_name: 班级名称过滤
            search_term: 搜索关键词（姓名、学号）
            sort_by: 排序字段
            sort_order: 排序方向（asc/desc）
        
        Returns:
            Dict: 包含学生列表和分页信息的结果
        """
        try:
            offset = (page - 1) * page_size
            
            # 构建WHERE条件
            where_conditions = []
            params = []
            
            if class_name:
                where_conditions.append("s.class_name = ?")
                params.append(class_name)
            
            if search_term:
                where_conditions.append("(s.name LIKE ? OR s.student_id LIKE ?)")
                search_pattern = f"%{search_term}%"
                params.extend([search_pattern, search_pattern])
            
            where_clause = ""
            if where_conditions:
                where_clause = "WHERE " + " AND ".join(where_conditions)
            
            # 构建ORDER BY子句
            valid_sort_fields = {
                'student_id': 's.student_id',
                'name': 's.name',
                'class_name': 's.class_name',
                'age': 's.age',
                'created_at': 's.created_at'
            }
            
            sort_field = valid_sort_fields.get(sort_by, 's.student_id')
            sort_direction = 'DESC' if sort_order.lower() == 'desc' else 'ASC'
            order_clause = f"ORDER BY {sort_field} {sort_direction}"
            
            # 获取总数
            count_query = f"""
                SELECT COUNT(*) as total 
                FROM students s
                LEFT JOIN classes c ON s.class_id = c.id
                {where_clause}
            """
            count_result = self.db.execute_query(count_query, tuple(params))
            total = count_result[0]['total'] if count_result else 0
            
            # 获取学生列表
            query = f"""
                SELECT s.id, s.name, s.student_id, s.gender, s.age, s.class_id, c.name as class_name, 
                       s.phone, s.email, s.qq, s.wechat, s.address, s.father_job, s.mother_job, 
                       s.contact_info, s.notes, s.chinese_score, s.math_score, s.english_score, 
                       s.science_score, s.total_score, s.id_card, s.primary_school, s.height, 
                       s.vision, s.class_position_intention, s.visit_time, s.good_subjects,
                       s.created_at, s.updated_at 
                FROM students s
                LEFT JOIN classes c ON s.class_id = c.id
                {where_clause}
                {order_clause}
                LIMIT ? OFFSET ?
            """
            
            query_params = params + [page_size, offset]
            students = self.db.execute_query(query, tuple(query_params))
            
            # 添加动态年龄
            students_with_age = self._add_dynamic_age_to_list(students)
            
            result = {
                'students': students_with_age,
                'total': total,
                'page': page,
                'page_size': page_size,
                'total_pages': (total + page_size - 1) // page_size,
                'filters': {
                    'class_name': class_name,
                    'search_term': search_term,
                    'sort_by': sort_by,
                    'sort_order': sort_order
                }
            }
            
            service_logger.info(f"获取学生列表成功，共 {len(students)} 条记录")
            return result
            
        except Exception as e:
            service_logger.error(f"获取学生列表失败: {e}")
            raise ServiceException(f"获取学生列表失败: {e}")
    
    def search_students(self, 
                       search_term: str,
                       search_fields: Optional[List[str]] = None,
                       page: int = 1,
                       page_size: int = 20) -> Dict[str, Any]:
        """高级搜索学生
        
        Args:
            search_term: 搜索关键词
            search_fields: 搜索字段列表，默认为['name', 'student_id', 'phone', 'class_name']
            page: 页码
            page_size: 每页数量
        
        Returns:
            Dict: 包含搜索结果和分页信息
        """
        try:
            if not search_term.strip():
                return {
                    'students': [],
                    'total': 0,
                    'page': page,
                    'page_size': page_size,
                    'total_pages': 0,
                    'search_term': search_term
                }
            
            # 默认搜索字段
            if not search_fields:
                search_fields = ['name', 'student_id', 'phone', 'class_name']
            
            # 构建搜索条件
            search_conditions = []
            params = []
            search_pattern = f"%{search_term}%"
            
            field_mapping = {
                'name': 's.name',
                'student_id': 's.student_id',
                'phone': 's.phone',
                'class_name': 's.class_name',
                'email': 's.email',
                'qq': 's.qq',
                'wechat': 's.wechat',
                'address': 's.address',
                'notes': 's.notes',
                'id_card': 's.id_card',
                'primary_school': 's.primary_school'
            }
            
            for field in search_fields:
                if field in field_mapping:
                    search_conditions.append(f"{field_mapping[field]} LIKE ?")
                    params.append(search_pattern)
            
            if not search_conditions:
                raise ServiceException("无效的搜索字段")
            
            where_clause = "WHERE (" + " OR ".join(search_conditions) + ")"
            offset = (page - 1) * page_size
            
            # 获取总数
            count_query = f"""
                SELECT COUNT(*) as total 
                FROM students s
                LEFT JOIN classes c ON s.class_id = c.id
                {where_clause}
            """
            count_result = self.db.execute_query(count_query, tuple(params))
            total = count_result[0]['total'] if count_result else 0
            
            # 获取搜索结果
            query = f"""
                SELECT s.id, s.name, s.student_id, s.gender, s.age, s.class_id, c.name as class_name, 
                       s.phone, s.email, s.qq, s.wechat, s.address, s.father_job, s.mother_job, 
                       s.contact_info, s.notes, s.chinese_score, s.math_score, s.english_score, 
                       s.science_score, s.total_score, s.id_card, s.primary_school, s.height, 
                       s.vision, s.class_position_intention, s.visit_time, s.good_subjects,
                       s.created_at, s.updated_at 
                FROM students s
                LEFT JOIN classes c ON s.class_id = c.id
                {where_clause}
                ORDER BY s.student_id ASC
                LIMIT ? OFFSET ?
            """
            
            query_params = params + [page_size, offset]
            students = self.db.execute_query(query, tuple(query_params))
            
            # 添加动态年龄
            students_with_age = self._add_dynamic_age_to_list(students)
            
            result = {
                'students': students_with_age,
                'total': total,
                'page': page,
                'page_size': page_size,
                'total_pages': (total + page_size - 1) // page_size,
                'search_term': search_term,
                'search_fields': search_fields
            }
            
            service_logger.info(f"搜索学生成功，关键词: {search_term}，找到 {len(students)} 条记录")
            return result
            
        except Exception as e:
            service_logger.error(f"搜索学生失败: {e}")
            raise ServiceException(f"搜索学生失败: {e}")
    
    def get_students_statistics(self) -> Dict[str, Any]:
        """获取学生统计信息
        
        Returns:
            Dict: 包含各种统计信息
        """
        try:
            # 总学生数
            total_query = "SELECT COUNT(*) as total FROM students"
            total_result = self.db.execute_query(total_query)
            total_students = total_result[0]['total'] if total_result else 0
            
            # 按班级统计
            class_query = """
                SELECT class_name, COUNT(*) as count 
                FROM students 
                WHERE class_name IS NOT NULL AND class_name != ''
                GROUP BY class_name 
                ORDER BY count DESC
            """
            class_stats = self.db.execute_query(class_query)
            
            # 按性别统计
            gender_query = """
                SELECT gender, COUNT(*) as count 
                FROM students 
                WHERE gender IS NOT NULL AND gender != ''
                GROUP BY gender
            """
            gender_stats = self.db.execute_query(gender_query)
            
            # 年龄分布统计
            age_query = """
                SELECT 
                    CASE 
                        WHEN age < 15 THEN '15岁以下'
                        WHEN age BETWEEN 15 AND 16 THEN '15-16岁'
                        WHEN age BETWEEN 17 AND 18 THEN '17-18岁'
                        WHEN age > 18 THEN '18岁以上'
                        ELSE '未知'
                    END as age_group,
                    COUNT(*) as count
                FROM students 
                WHERE age IS NOT NULL
                GROUP BY age_group
                ORDER BY count DESC
            """
            age_stats = self.db.execute_query(age_query)
            
            # 最近创建的学生
            recent_query = """
                SELECT COUNT(*) as count 
                FROM students 
                WHERE created_at >= datetime('now', '-7 days')
            """
            recent_result = self.db.execute_query(recent_query)
            recent_students = recent_result[0]['count'] if recent_result else 0
            
            result = {
                'total_students': total_students,
                'class_distribution': class_stats,
                'gender_distribution': gender_stats,
                'age_distribution': age_stats,
                'recent_students': recent_students
            }
            
            service_logger.info(f"获取学生统计信息成功，总学生数: {total_students}")
            return result
            
        except Exception as e:
            service_logger.error(f"获取学生统计信息失败: {e}")
            raise ServiceException(f"获取学生统计信息失败: {e}")