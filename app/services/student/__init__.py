"""
学生服务模块

将原来的大型StudentService拆分为多个职责单一的服务类：
- StudentService: 基础CRUD操作
- StudentBatchService: 批量操作
- StudentSearchService: 搜索和查询
- StudentImportService: Excel导入功能
"""

from .student_service import StudentService
from .student_batch_service import StudentBatchService
from .student_search_service import StudentSearchService
from .student_import_service import StudentImportService

# 创建服务实例
student_service = StudentService()
student_batch_service = StudentBatchService()
student_search_service = StudentSearchService()
student_import_service = StudentImportService()

__all__ = [
    'StudentService',
    'StudentBatchService', 
    'StudentSearchService',
    'StudentImportService',
    'student_service',
    'student_batch_service',
    'student_search_service',
    'student_import_service'
]