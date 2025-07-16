"""
学生API路由
"""

from fastapi import APIRouter, HTTPException, Query, Path
from typing import Optional

from app.schemas.student import (
    StudentCreate, 
    StudentUpdate, 
    StudentResponse, 
    StudentListResponse
)
from app.schemas.common import ResponseModel, PaginatedResponse
from app.services.student_service import student_service
from app.utils.exceptions import (
    StudentNotFoundException,
    DuplicateStudentException,
    ServiceException
)
from app.core.logger import api_logger


router = APIRouter()


@router.get("/students", response_model=PaginatedResponse)
async def get_students(
    page: int = Query(1, ge=1, description="页码"),
    page_size: int = Query(20, ge=1, le=100, description="每页数量"),
    search: Optional[str] = Query(None, description="搜索关键词")
):
    """获取学生列表"""
    try:
        if search:
            result = student_service.search_students(search, page, page_size)
        else:
            result = student_service.get_all_students(page, page_size)
        
        return ResponseModel(
            success=True,
            data=result['students'],
            pagination={
                'page': result['page'],
                'page_size': result['page_size'],
                'total': result['total'],
                'total_pages': result['total_pages']
            }
        )
        
    except ServiceException as e:
        api_logger.error(f"获取学生列表失败: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/students/{student_id}", response_model=ResponseModel)
async def get_student(
    student_id: int = Path(..., description="学生ID")
):
    """获取单个学生信息"""
    try:
        student = student_service.get_student_by_id(student_id)
        return ResponseModel(success=True, data=student)
        
    except StudentNotFoundException as e:
        api_logger.warning(f"学生未找到: {student_id}")
        raise HTTPException(status_code=404, detail=str(e))
    except ServiceException as e:
        api_logger.error(f"获取学生信息失败: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/students", response_model=ResponseModel)
async def create_student(student_data: StudentCreate):
    """创建新学生"""
    try:
        new_student = student_service.create_student(student_data)
        return ResponseModel(
            success=True,
            message="学生创建成功",
            data=new_student
        )
        
    except DuplicateStudentException as e:
        api_logger.warning(f"学生学号重复: {student_data.student_id}")
        raise HTTPException(status_code=400, detail=str(e))
    except ServiceException as e:
        api_logger.error(f"创建学生失败: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.put("/students/{student_id}", response_model=ResponseModel)
async def update_student(
    student_id: int = Path(..., description="学生ID"),
    student_data: StudentUpdate = None
):
    """更新学生信息"""
    try:
        updated_student = student_service.update_student(student_id, student_data)
        return ResponseModel(
            success=True,
            message="学生信息更新成功",
            data=updated_student
        )
        
    except StudentNotFoundException as e:
        api_logger.warning(f"学生未找到: {student_id}")
        raise HTTPException(status_code=404, detail=str(e))
    except DuplicateStudentException as e:
        api_logger.warning(f"学生学号重复: {student_data.student_id}")
        raise HTTPException(status_code=400, detail=str(e))
    except ServiceException as e:
        api_logger.error(f"更新学生信息失败: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/students/{student_id}", response_model=ResponseModel)
async def delete_student(
    student_id: int = Path(..., description="学生ID")
):
    """删除学生"""
    try:
        success = student_service.delete_student(student_id)
        if success:
            return ResponseModel(
                success=True,
                message="学生删除成功"
            )
        else:
            raise HTTPException(status_code=500, detail="删除失败")
            
    except StudentNotFoundException as e:
        api_logger.warning(f"学生未找到: {student_id}")
        raise HTTPException(status_code=404, detail=str(e))
    except ServiceException as e:
        api_logger.error(f"删除学生失败: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/students/by-student-id/{student_id}", response_model=ResponseModel)
async def get_student_by_student_id(
    student_id: str = Path(..., description="学生学号")
):
    """根据学号获取学生信息"""
    try:
        student = student_service.get_student_by_student_id(student_id)
        if student:
            return ResponseModel(success=True, data=student)
        else:
            raise HTTPException(status_code=404, detail="学生未找到")
            
    except ServiceException as e:
        api_logger.error(f"根据学号获取学生信息失败: {e}")
        raise HTTPException(status_code=500, detail=str(e)) 