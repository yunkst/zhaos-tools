"""学生服务层 - 兼容性包装类"""

from typing import List, Optional, Dict, Any
from datetime import datetime

from app.core.logger import service_logger
from app.services.student.student_service import StudentService as NewStudentService
from app.services.student.student_batch_service import StudentBatchService
from app.services.student.student_search_service import StudentSearchService
from app.services.student.student_import_service import StudentImportService
from app.schemas.student import StudentCreate, StudentUpdate
from app.utils.exceptions import (
    StudentNotFoundException,
    ServiceException
)


class StudentService:
    """学生服务兼容性包装类 - 保持向后兼容性"""
    
    def __init__(self):
        self.student_service = NewStudentService()
        self.batch_service = StudentBatchService()
        self.search_service = StudentSearchService()
        self.import_service = StudentImportService()
        
        service_logger.info("初始化学生服务兼容性包装类")
    
    def get_students(self, page: int = 1, page_size: int = 20, search: Optional[str] = None) -> Dict[str, Any]:
        """获取学生列表 - 委托给搜索服务"""
        return self.search_service.get_students(page=page, page_size=page_size, search=search)
    
    def get_student_by_id(self, student_id: int) -> Optional[Dict[str, Any]]:
        """根据ID获取学生 - 委托给新的服务"""
        return self.student_service.get_student_by_id(student_id)
    
    def get_student_by_student_id(self, student_id: str) -> Optional[Dict[str, Any]]:
        """根据学号获取学生 - 委托给新的服务"""
        return self.student_service.get_student_by_student_id(student_id)
    
    def create_student(self, student_data: StudentCreate) -> Dict[str, Any]:
        """创建学生 - 委托给新的服务"""
        return self.student_service.create_student(student_data)
    
    def update_student(self, student_id: int, student_data: StudentUpdate) -> Dict[str, Any]:
        """更新学生 - 委托给新的服务"""
        return self.student_service.update_student(student_id, student_data)
    
    def delete_student(self, student_id: int) -> bool:
        """删除学生 - 委托给新的服务"""
        return self.student_service.delete_student(student_id)
    
    def get_classes(self) -> List[str]:
        """获取所有班级 - 委托给新的服务"""
        return self.student_service.get_classes()
    
    def search_students(self, search_params: Dict[str, Any]) -> Dict[str, Any]:
        """搜索学生 - 委托给搜索服务"""
        return self.search_service.search_students(search_params)
    
    def get_students_by_class(self, class_name: str) -> List[Dict[str, Any]]:
        """根据班级获取学生 - 委托给批量服务"""
        return self.batch_service.get_students_by_class(class_name)
    
    def batch_update_students(self, updates: List[Dict[str, Any]]) -> Dict[str, Any]:
        """批量更新学生 - 委托给批量服务"""
        return self.batch_service.batch_update_students(updates)
    
    def batch_delete_students(self, student_ids: List[int]) -> Dict[str, Any]:
        """批量删除学生 - 委托给批量服务"""
        return self.batch_service.batch_delete_students(student_ids)
    
    def import_students_from_excel(self, file_path: str) -> Dict[str, Any]:
        """从Excel导入学生 - 委托给导入服务"""
        return self.import_service.import_students_from_excel(file_path)
    
    def get_import_template(self) -> Dict[str, Any]:
        """获取导入模板 - 委托给导入服务"""
        return self.import_service.get_import_template()


# 创建全局学生服务实例
student_service = StudentService()