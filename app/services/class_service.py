"""
班级服务模块
"""

from typing import Dict, Any, List, Optional
from datetime import datetime
from app.core.database import db_manager
from app.core.logger import service_logger
from app.schemas.class_schema import ClassCreate, ClassUpdate, ClassResponse
from app.utils.exceptions import ServiceException, NotFoundException


class ClassNotFoundException(NotFoundException):
    """班级未找到异常"""
    pass


class ClassService:
    """班级服务类"""
    
    def __init__(self):
        self.db = db_manager
    
    def create_class(self, class_data: ClassCreate) -> ClassResponse:
        """创建班级"""
        try:
            # 检查班级名称是否已存在
            existing_class = self.get_class_by_name(class_data.name)
            if existing_class:
                raise ServiceException(f"班级名称 '{class_data.name}' 已存在")
            
            # 插入新班级
            query = """
                INSERT INTO classes (name, description, grade, teacher_name, created_at, updated_at)
                VALUES (?, ?, ?, ?, ?, ?)
            """
            now = datetime.now()
            class_id = self.db.execute_insert(
                query,
                (
                    class_data.name,
                    class_data.description,
                    class_data.grade,
                    class_data.teacher_name,
                    now,
                    now
                )
            )
            
            service_logger.info(f"创建班级成功: {class_data.name}")
            return self.get_class_by_id(class_id)
            
        except ServiceException:
            raise
        except Exception as e:
            service_logger.error(f"创建班级失败: {e}")
            raise ServiceException(f"创建班级失败: {e}")
    
    def get_class_by_id(self, class_id: int) -> ClassResponse:
        """根据ID获取班级"""
        try:
            query = """
                SELECT c.*, 
                       (SELECT COUNT(*) FROM students WHERE class_id = c.id) as student_count
                FROM classes c 
                WHERE c.id = ?
            """
            result = self.db.execute_query(query, (class_id,))
            
            if not result:
                raise ClassNotFoundException(f"班级ID {class_id} 不存在")
            
            class_data = result[0]
            return ClassResponse(**class_data)
            
        except ClassNotFoundException:
            raise
        except Exception as e:
            service_logger.error(f"获取班级失败: {e}")
            raise ServiceException(f"获取班级失败: {e}")
    
    def get_class_by_name(self, name: str) -> Optional[ClassResponse]:
        """根据名称获取班级"""
        try:
            query = """
                SELECT c.*, 
                       (SELECT COUNT(*) FROM students WHERE class_id = c.id) as student_count
                FROM classes c 
                WHERE c.name = ?
            """
            result = self.db.execute_query(query, (name,))
            
            if not result:
                return None
            
            class_data = result[0]
            return ClassResponse(**class_data)
            
        except Exception as e:
            service_logger.error(f"获取班级失败: {e}")
            raise ServiceException(f"获取班级失败: {e}")
    
    def get_classes(self, page: int = 1, page_size: int = 20) -> Dict[str, Any]:
        """获取班级列表"""
        try:
            # 计算偏移量
            offset = (page - 1) * page_size
            
            # 获取班级列表
            query = """
                SELECT c.*, 
                       (SELECT COUNT(*) FROM students WHERE class_id = c.id) as student_count
                FROM classes c 
                ORDER BY c.created_at DESC
                LIMIT ? OFFSET ?
            """
            classes_data = self.db.execute_query(query, (page_size, offset))
            
            # 获取总数
            count_query = "SELECT COUNT(*) as total FROM classes"
            total_result = self.db.execute_query(count_query)
            total = total_result[0]['total'] if total_result else 0
            
            # 转换为响应模型
            classes = [ClassResponse(**class_data) for class_data in classes_data]
            
            return {
                "classes": classes,
                "total": total,
                "page": page,
                "page_size": page_size,
                "total_pages": (total + page_size - 1) // page_size
            }
            
        except Exception as e:
            service_logger.error(f"获取班级列表失败: {e}")
            raise ServiceException(f"获取班级列表失败: {e}")
    
    def update_class(self, class_id: int, class_data: ClassUpdate) -> ClassResponse:
        """更新班级"""
        try:
            # 检查班级是否存在
            existing_class = self.get_class_by_id(class_id)
            
            # 构建更新字段
            update_fields = []
            params = []
            
            if class_data.name is not None:
                # 检查新名称是否与其他班级冲突
                other_class = self.get_class_by_name(class_data.name)
                if other_class and other_class.id != class_id:
                    raise ServiceException(f"班级名称 '{class_data.name}' 已存在")
                update_fields.append("name = ?")
                params.append(class_data.name)
            
            if class_data.description is not None:
                update_fields.append("description = ?")
                params.append(class_data.description)
            
            if class_data.grade is not None:
                update_fields.append("grade = ?")
                params.append(class_data.grade)
            
            if class_data.teacher_name is not None:
                update_fields.append("teacher_name = ?")
                params.append(class_data.teacher_name)
            
            if not update_fields:
                return existing_class
            
            # 添加更新时间
            update_fields.append("updated_at = ?")
            params.append(datetime.now())
            params.append(class_id)
            
            # 执行更新
            query = f"UPDATE classes SET {', '.join(update_fields)} WHERE id = ?"
            affected_rows = self.db.execute_update(query, tuple(params))
            
            if affected_rows > 0:
                service_logger.info(f"更新班级成功: {existing_class.name}")
                return self.get_class_by_id(class_id)
            else:
                raise ServiceException("更新班级失败")
                
        except (ClassNotFoundException, ServiceException):
            raise
        except Exception as e:
            service_logger.error(f"更新班级失败: {e}")
            raise ServiceException(f"更新班级失败: {e}")
    
    def delete_class(self, class_id: int) -> bool:
        """删除班级"""
        try:
            # 检查班级是否存在
            existing_class = self.get_class_by_id(class_id)
            
            # 检查是否有学生在该班级
            student_count_query = "SELECT COUNT(*) as count FROM students WHERE class_id = ?"
            student_count_result = self.db.execute_query(student_count_query, (class_id,))
            student_count = student_count_result[0]['count'] if student_count_result else 0
            
            if student_count > 0:
                raise ServiceException(f"无法删除班级 '{existing_class.name}'，该班级还有 {student_count} 名学生")
            
            # 删除班级
            query = "DELETE FROM classes WHERE id = ?"
            affected_rows = self.db.execute_update(query, (class_id,))
            
            if affected_rows > 0:
                service_logger.info(f"删除班级成功: {existing_class.name}")
                return True
            else:
                return False
                
        except (ClassNotFoundException, ServiceException):
            raise
        except Exception as e:
            service_logger.error(f"删除班级失败: {e}")
            raise ServiceException(f"删除班级失败: {e}")
    
    def get_all_classes(self) -> List[ClassResponse]:
        """获取所有班级（不分页）"""
        try:
            query = """
                SELECT c.*, 
                       (SELECT COUNT(*) FROM students WHERE class_id = c.id) as student_count
                FROM classes c 
                ORDER BY c.name
            """
            classes_data = self.db.execute_query(query)
            return [ClassResponse(**class_data) for class_data in classes_data]
            
        except Exception as e:
            service_logger.error(f"获取所有班级失败: {e}")
            raise ServiceException(f"获取所有班级失败: {e}")


# 创建班级服务实例
class_service = ClassService() 