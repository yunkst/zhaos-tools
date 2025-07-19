"""
学生基础CRUD API - 处理学生的基础增删改查操作
"""

from typing import Dict, Any
from fastapi import APIRouter, HTTPException, Depends, status
from fastapi.responses import JSONResponse

from app.schemas.student import StudentCreate, StudentUpdate, StudentResponse
from app.services.student import student_service
from app.utils.exceptions import (
    StudentNotFoundException,
    DuplicateStudentException,
    ServiceException
)
from app.core.logger import api_logger

router = APIRouter()


@router.post("/", response_model=StudentResponse, status_code=status.HTTP_201_CREATED)
async def create_student(student_data: StudentCreate) -> Dict[str, Any]:
    """
    创建新学生
    
    Args:
        student_data: 学生创建数据
    
    Returns:
        Dict: 创建的学生信息
    
    Raises:
        HTTPException: 当学号已存在或创建失败时
    """
    try:
        api_logger.info(f"创建学生请求: {student_data.name} ({student_data.student_id})")
        
        new_student = student_service.create_student(student_data)
        
        api_logger.info(f"创建学生成功: {new_student['name']}")
        return {
            "code": 200,
            "message": "创建学生成功",
            "data": new_student
        }
        
    except DuplicateStudentException as e:
        api_logger.warning(f"创建学生失败 - 学号重复: {e}")
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=str(e)
        )
    except ServiceException as e:
        api_logger.error(f"创建学生失败 - 服务异常: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )
    except Exception as e:
        api_logger.error(f"创建学生失败 - 未知错误: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="创建学生失败"
        )


@router.get("/{student_id}", response_model=StudentResponse)
async def get_student(student_id: int) -> Dict[str, Any]:
    """
    根据ID获取学生信息
    
    Args:
        student_id: 学生ID
    
    Returns:
        Dict: 学生信息
    
    Raises:
        HTTPException: 当学生不存在时
    """
    try:
        api_logger.info(f"获取学生信息请求: ID {student_id}")
        
        student = student_service.get_student_by_id(student_id)
        
        if not student:
            api_logger.warning(f"学生不存在: ID {student_id}")
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"未找到ID为 {student_id} 的学生"
            )
        
        api_logger.info(f"获取学生信息成功: {student['name']}")
        return {
            "code": 200,
            "message": "获取学生信息成功",
            "data": student
        }
        
    except HTTPException:
        raise
    except ServiceException as e:
        api_logger.error(f"获取学生信息失败 - 服务异常: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )
    except Exception as e:
        api_logger.error(f"获取学生信息失败 - 未知错误: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="获取学生信息失败"
        )


@router.get("/by-student-id/{student_id}")
async def get_student_by_student_id(student_id: str) -> Dict[str, Any]:
    """
    根据学号获取学生信息
    
    Args:
        student_id: 学号
    
    Returns:
        Dict: 学生信息
    
    Raises:
        HTTPException: 当学生不存在时
    """
    try:
        api_logger.info(f"根据学号获取学生信息请求: {student_id}")
        
        student = student_service.get_student_by_student_id(student_id)
        
        if not student:
            api_logger.warning(f"学生不存在: 学号 {student_id}")
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"未找到学号为 {student_id} 的学生"
            )
        
        api_logger.info(f"根据学号获取学生信息成功: {student['name']}")
        return {
            "code": 200,
            "message": "获取学生信息成功",
            "data": student
        }
        
    except HTTPException:
        raise
    except ServiceException as e:
        api_logger.error(f"根据学号获取学生信息失败 - 服务异常: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )
    except Exception as e:
        api_logger.error(f"根据学号获取学生信息失败 - 未知错误: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="获取学生信息失败"
        )


@router.put("/{student_id}", response_model=StudentResponse)
async def update_student(student_id: int, student_data: StudentUpdate) -> Dict[str, Any]:
    """
    更新学生信息
    
    Args:
        student_id: 学生ID
        student_data: 更新数据
    
    Returns:
        Dict: 更新后的学生信息
    
    Raises:
        HTTPException: 当学生不存在或更新失败时
    """
    try:
        api_logger.info(f"更新学生信息请求: ID {student_id}")
        
        updated_student = student_service.update_student(student_id, student_data)
        
        api_logger.info(f"更新学生信息成功: {updated_student['name']}")
        return {
            "code": 200,
            "message": "更新学生信息成功",
            "data": updated_student
        }
        
    except StudentNotFoundException as e:
        api_logger.warning(f"更新学生信息失败 - 学生不存在: {e}")
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )
    except DuplicateStudentException as e:
        api_logger.warning(f"更新学生信息失败 - 学号重复: {e}")
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=str(e)
        )
    except ServiceException as e:
        api_logger.error(f"更新学生信息失败 - 服务异常: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )
    except Exception as e:
        api_logger.error(f"更新学生信息失败 - 未知错误: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="更新学生信息失败"
        )


@router.delete("/{student_id}")
async def delete_student(student_id: int) -> Dict[str, Any]:
    """
    删除学生
    
    Args:
        student_id: 学生ID
    
    Returns:
        Dict: 删除结果
    
    Raises:
        HTTPException: 当学生不存在或删除失败时
    """
    try:
        api_logger.info(f"删除学生请求: ID {student_id}")
        
        success = student_service.delete_student(student_id)
        
        if success:
            api_logger.info(f"删除学生成功: ID {student_id}")
            return {
                "code": 200,
                "message": "删除学生成功",
                "data": None
            }
        else:
            api_logger.warning(f"删除学生失败: ID {student_id}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="删除学生失败"
            )
        
    except StudentNotFoundException as e:
        api_logger.warning(f"删除学生失败 - 学生不存在: {e}")
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )
    except ServiceException as e:
        api_logger.error(f"删除学生失败 - 服务异常: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )
    except Exception as e:
        api_logger.error(f"删除学生失败 - 未知错误: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="删除学生失败"
        )


@router.get("/classes/list")
async def get_class_list() -> Dict[str, Any]:
    """
    获取所有班级列表
    
    Returns:
        Dict: 班级列表
    """
    try:
        api_logger.info("获取班级列表请求")
        
        classes = student_service.get_class_list()
        
        api_logger.info(f"获取班级列表成功，共 {len(classes)} 个班级")
        return {
            "code": 200,
            "message": "获取班级列表成功",
            "data": classes
        }
        
    except ServiceException as e:
        api_logger.error(f"获取班级列表失败 - 服务异常: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )
    except Exception as e:
        api_logger.error(f"获取班级列表失败 - 未知错误: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="获取班级列表失败"
        )