"""学生API路由 - 重定向到新的模块化结构"""

# 为了保持向后兼容性，重定向到新的模块化结构
from app.api.v1.students import (
    students_crud,
    students_batch, 
    students_search,
    students_import
)
from fastapi import APIRouter

# 创建主路由
router = APIRouter()

# 包含所有子路由
router.include_router(students_crud.router, tags=["学生-基础操作"])
router.include_router(students_batch.router, tags=["学生-批量操作"])
router.include_router(students_search.router, tags=["学生-搜索查询"])
router.include_router(students_import.router, tags=["学生-导入导出"])

# 导出router以保持兼容性
__all__ = ['router']
