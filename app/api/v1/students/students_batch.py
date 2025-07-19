"""
学生批量操作API - 处理学生的批量操作
"""

from typing import Dict, Any, List
from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel

from app.services.student import student_batch_service
from app.utils.exceptions import ServiceException
from app.core.logger import api_logger

router = APIRouter()


class BatchUpdateRequest(BaseModel):
    """批量更新请求模型"""
    updates: List[Dict[str, Any]]


class BatchDeleteRequest(BaseModel):
    """批量删除请求模型"""
    student_ids: List[int]


class BatchGetRequest(BaseModel):
    """批量获取请求模型"""
    student_ids: List[int]


@router.post("/batch/update")
async def batch_update_students(request: BatchUpdateRequest) -> Dict[str, Any]:
    """
    批量更新学生信息
    
    Args:
        request: 批量更新请求，包含更新数据列表
    
    Returns:
        Dict: 批量更新结果统计
    
    Request Body Example:
        {
            "updates": [
                {
                    "id": 1,
                    "data": {
                        "name": "张三",
                        "age": 17
                    }
                },
                {
                    "id": 2,
                    "data": {
                        "phone": "13800138000"
                    }
                }
            ]
        }
    """
    try:
        api_logger.info(f"批量更新学生请求: {len(request.updates)} 条记录")
        
        if not request.updates:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="更新数据不能为空"
            )
        
        if len(request.updates) > 100:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="单次批量更新不能超过100条记录"
            )
        
        result = student_batch_service.batch_update_students(request.updates)
        
        api_logger.info(f"批量更新学生完成: 成功 {result['success_count']}, 失败 {result['failed_count']}")
        return {
            "code": 200,
            "message": f"批量更新完成，成功 {result['success_count']} 条，失败 {result['failed_count']} 条",
            "data": result
        }
        
    except HTTPException:
        raise
    except ServiceException as e:
        api_logger.error(f"批量更新学生失败 - 服务异常: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )
    except Exception as e:
        api_logger.error(f"批量更新学生失败 - 未知错误: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="批量更新学生失败"
        )


@router.post("/batch/delete")
async def batch_delete_students(request: BatchDeleteRequest) -> Dict[str, Any]:
    """
    批量删除学生
    
    Args:
        request: 批量删除请求，包含学生ID列表
    
    Returns:
        Dict: 批量删除结果统计
    
    Request Body Example:
        {
            "student_ids": [1, 2, 3, 4, 5]
        }
    """
    try:
        api_logger.info(f"批量删除学生请求: {len(request.student_ids)} 条记录")
        
        if not request.student_ids:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="学生ID列表不能为空"
            )
        
        if len(request.student_ids) > 50:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="单次批量删除不能超过50条记录"
            )
        
        result = student_batch_service.batch_delete_students(request.student_ids)
        
        api_logger.info(f"批量删除学生完成: 成功 {result['success_count']}, 失败 {result['failed_count']}")
        return {
            "code": 200,
            "message": f"批量删除完成，成功 {result['success_count']} 条，失败 {result['failed_count']} 条",
            "data": result
        }
        
    except HTTPException:
        raise
    except ServiceException as e:
        api_logger.error(f"批量删除学生失败 - 服务异常: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )
    except Exception as e:
        api_logger.error(f"批量删除学生失败 - 未知错误: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="批量删除学生失败"
        )


@router.post("/batch/get")
async def batch_get_students(request: BatchGetRequest) -> Dict[str, Any]:
    """
    批量获取学生信息
    
    Args:
        request: 批量获取请求，包含学生ID列表
    
    Returns:
        Dict: 学生信息列表
    
    Request Body Example:
        {
            "student_ids": [1, 2, 3, 4, 5]
        }
    """
    try:
        api_logger.info(f"批量获取学生信息请求: {len(request.student_ids)} 条记录")
        
        if not request.student_ids:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="学生ID列表不能为空"
            )
        
        if len(request.student_ids) > 100:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="单次批量获取不能超过100条记录"
            )
        
        students = student_batch_service.get_students_by_ids(request.student_ids)
        
        api_logger.info(f"批量获取学生信息成功: {len(students)} 条记录")
        return {
            "code": 200,
            "message": f"批量获取学生信息成功，共 {len(students)} 条记录",
            "data": students
        }
        
    except HTTPException:
        raise
    except ServiceException as e:
        api_logger.error(f"批量获取学生信息失败 - 服务异常: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )
    except Exception as e:
        api_logger.error(f"批量获取学生信息失败 - 未知错误: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="批量获取学生信息失败"
        )


@router.get("/by-class-id/{class_id}")
async def get_students_by_class_id(
    class_id: int,
    page: int = 1,
    page_size: int = 20
) -> Dict[str, Any]:
    """
    根据班级ID获取学生列表
    
    Args:
        class_id: 班级ID
        page: 页码，默认为1
        page_size: 每页数量，默认为20
    
    Returns:
        Dict: 包含学生列表和分页信息的结果
    """
    try:
        api_logger.info(f"根据班级ID获取学生列表请求: {class_id}, 页码: {page}, 每页: {page_size}")
        
        if page < 1:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="页码必须大于0"
            )
        
        if page_size < 1 or page_size > 100:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="每页数量必须在1-100之间"
            )
        
        result = student_batch_service.get_students_by_class_id(class_id, page, page_size)
        
        api_logger.info(f"根据班级ID获取学生列表成功: {class_id}, {len(result['students'])} 条记录")
        return {
            "success": True,
            "code": 200,
            "message": f"获取班级学生列表成功",
            "data": result['students'],
            "pagination": {
                "total": result['total'],
                "page": result['page'],
                "page_size": result['page_size'],
                "total_pages": result['total_pages']
            }
        }
        
    except HTTPException:
        raise
    except ServiceException as e:
        api_logger.error(f"根据班级ID获取学生列表失败 - 服务异常: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )
    except Exception as e:
        api_logger.error(f"根据班级ID获取学生列表失败 - 未知错误: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="获取学生列表失败"
        )


@router.get("/by-class/{class_name}")
async def get_students_by_class(
    class_name: str,
    page: int = 1,
    page_size: int = 20
) -> Dict[str, Any]:
    """
    根据班级获取学生列表
    
    Args:
        class_name: 班级名称
        page: 页码，默认为1
        page_size: 每页数量，默认为20
    
    Returns:
        Dict: 包含学生列表和分页信息的结果
    """
    try:
        api_logger.info(f"根据班级获取学生列表请求: {class_name}, 页码: {page}, 每页: {page_size}")
        
        if page < 1:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="页码必须大于0"
            )
        
        if page_size < 1 or page_size > 100:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="每页数量必须在1-100之间"
            )
        
        result = student_batch_service.get_students_by_class(class_name, page, page_size)
        
        api_logger.info(f"根据班级获取学生列表成功: {class_name}, {len(result['students'])} 条记录")
        return {
            "code": 200,
            "message": f"获取班级 {class_name} 学生列表成功",
            "data": result
        }
        
    except HTTPException:
        raise
    except ServiceException as e:
        api_logger.error(f"根据班级获取学生列表失败 - 服务异常: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )
    except Exception as e:
        api_logger.error(f"根据班级获取学生列表失败 - 未知错误: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="获取学生列表失败"
        )