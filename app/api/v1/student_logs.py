"""学生日志API路由"""

from typing import Optional
from fastapi import APIRouter, HTTPException, Query
from fastapi.responses import JSONResponse

from app.schemas.student_log import (
    StudentLogCreate, 
    StudentLogUpdate, 
    StudentLogResponse,
    StudentLogListResponse
)
from app.services.student_log_service import student_log_service
from app.core.logger import get_logger

logger = get_logger(__name__)
router = APIRouter(prefix="/student-logs", tags=["学生日志"])


@router.post("/", response_model=StudentLogResponse, summary="创建学生日志")
async def create_student_log(log_data: StudentLogCreate):
    """创建新的学生日志"""
    try:
        log = student_log_service.create_log(log_data)
        return log
    except Exception as e:
        logger.error(f"创建学生日志失败: {e}")
        raise HTTPException(status_code=500, detail=f"创建学生日志失败: {str(e)}")


@router.get("/{log_id}", response_model=StudentLogResponse, summary="获取学生日志详情")
async def get_student_log(log_id: int):
    """根据ID获取学生日志详情"""
    try:
        log = student_log_service.get_log_by_id(log_id)
        if not log:
            raise HTTPException(status_code=404, detail="学生日志不存在")
        return log
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"获取学生日志失败: {e}")
        raise HTTPException(status_code=500, detail=f"获取学生日志失败: {str(e)}")


@router.get("/student/{student_id}", response_model=StudentLogListResponse, summary="获取指定学生的日志列表")
async def get_student_logs(
    student_id: str,
    page: int = Query(1, ge=1, description="页码"),
    page_size: int = Query(20, ge=1, le=100, description="每页数量")
):
    """获取指定学生的日志列表"""
    try:
        result = student_log_service.get_logs_by_student(student_id, page, page_size)
        return StudentLogListResponse(**result)
    except Exception as e:
        logger.error(f"获取学生日志列表失败: {e}")
        raise HTTPException(status_code=500, detail=f"获取学生日志列表失败: {str(e)}")


@router.get("/", response_model=StudentLogListResponse, summary="获取所有学生日志")
async def get_all_student_logs(
    page: int = Query(1, ge=1, description="页码"),
    page_size: int = Query(20, ge=1, le=100, description="每页数量")
):
    """获取所有学生日志列表"""
    try:
        result = student_log_service.get_all_logs(page, page_size)
        return StudentLogListResponse(**result)
    except Exception as e:
        logger.error(f"获取所有学生日志失败: {e}")
        raise HTTPException(status_code=500, detail=f"获取所有学生日志失败: {str(e)}")


@router.put("/{log_id}", response_model=StudentLogResponse, summary="更新学生日志")
async def update_student_log(log_id: int, log_data: StudentLogUpdate):
    """更新学生日志"""
    try:
        log = student_log_service.update_log(log_id, log_data)
        if not log:
            raise HTTPException(status_code=404, detail="学生日志不存在")
        return log
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"更新学生日志失败: {e}")
        raise HTTPException(status_code=500, detail=f"更新学生日志失败: {str(e)}")


@router.delete("/{log_id}", summary="删除学生日志")
async def delete_student_log(log_id: int):
    """删除学生日志"""
    try:
        success = student_log_service.delete_log(log_id)
        if not success:
            raise HTTPException(status_code=404, detail="学生日志不存在")
        return JSONResponse(content={"message": "学生日志删除成功"})
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"删除学生日志失败: {e}")
        raise HTTPException(status_code=500, detail=f"删除学生日志失败: {str(e)}")


@router.get("/search/", response_model=StudentLogListResponse, summary="搜索学生日志")
async def search_student_logs(
    keyword: str = Query(..., description="搜索关键词"),
    student_id: Optional[str] = Query(None, description="学生ID（可选）"),
    page: int = Query(1, ge=1, description="页码"),
    page_size: int = Query(20, ge=1, le=100, description="每页数量")
):
    """搜索学生日志"""
    try:
        result = student_log_service.search_logs(keyword, student_id, page, page_size)
        return StudentLogListResponse(**result)
    except Exception as e:
        logger.error(f"搜索学生日志失败: {e}")
        raise HTTPException(status_code=500, detail=f"搜索学生日志失败: {str(e)}")