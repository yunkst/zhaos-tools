"""
学生API模块

将原来的大型students.py拆分为多个职责单一的API模块：
- students_crud.py: 基础CRUD操作API
- students_batch.py: 批量操作API
- students_import.py: 导入导出API
- students_search.py: 搜索和查询API
"""

from fastapi import APIRouter
from .students_crud import router as crud_router
from .students_batch import router as batch_router
from .students_import import router as import_router
from .students_search import router as search_router

# 创建主路由
router = APIRouter(prefix="/students", tags=["students"])

# 包含所有子路由
router.include_router(crud_router)
router.include_router(batch_router)
router.include_router(import_router)
router.include_router(search_router)

__all__ = ['router']