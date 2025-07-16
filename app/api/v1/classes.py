"""
班级管理API路由
"""

from fastapi import APIRouter, HTTPException, Query, Depends
from typing import List
from app.schemas.class_schema import (
    ClassCreate, 
    ClassUpdate, 
    ClassResponse, 
    ClassListResponse
)
from app.schemas.common import ResponseModel
from app.services.class_service import class_service, ClassNotFoundException
from app.utils.exceptions import ServiceException
from app.core.logger import api_logger

router = APIRouter(prefix="/classes", tags=["班级管理"])


@router.post("/", response_model=ResponseModel[ClassResponse])
async def create_class(class_data: ClassCreate):
    """创建班级"""
    try:
        result = class_service.create_class(class_data)
        api_logger.info(f"创建班级成功: {class_data.name}")
        return ResponseModel(
            success=True,
            data=result,
            message="班级创建成功"
        )
    except ServiceException as e:
        api_logger.error(f"创建班级失败: {e}")
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        api_logger.error(f"创建班级异常: {e}")
        raise HTTPException(status_code=500, detail="服务器内部错误")


@router.get("/", response_model=ResponseModel[ClassListResponse])
async def get_classes(
    page: int = Query(1, ge=1, description="页码"),
    page_size: int = Query(20, ge=1, le=100, description="每页数量")
):
    """获取班级列表"""
    try:
        result = class_service.get_classes(page=page, page_size=page_size)
        api_logger.info(f"获取班级列表成功: 页码={page}, 每页={page_size}")
        return ResponseModel(
            success=True,
            data=result,
            message="获取班级列表成功"
        )
    except ServiceException as e:
        api_logger.error(f"获取班级列表失败: {e}")
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        api_logger.error(f"获取班级列表异常: {e}")
        raise HTTPException(status_code=500, detail="服务器内部错误")


@router.get("/all", response_model=ResponseModel[List[ClassResponse]])
async def get_all_classes():
    """获取所有班级（不分页）"""
    try:
        result = class_service.get_all_classes()
        api_logger.info("获取所有班级成功")
        return ResponseModel(
            success=True,
            data=result,
            message="获取所有班级成功"
        )
    except ServiceException as e:
        api_logger.error(f"获取所有班级失败: {e}")
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        api_logger.error(f"获取所有班级异常: {e}")
        raise HTTPException(status_code=500, detail="服务器内部错误")


@router.get("/detail/{class_id}", response_model=ResponseModel[ClassResponse])
async def get_class(class_id: int):
    """获取单个班级"""
    try:
        result = class_service.get_class_by_id(class_id)
        api_logger.info(f"获取班级成功: {class_id}")
        return ResponseModel(
            success=True,
            data=result,
            message="获取班级成功"
        )
    except ClassNotFoundException as e:
        api_logger.error(f"班级不存在: {e}")
        raise HTTPException(status_code=404, detail=str(e))
    except ServiceException as e:
        api_logger.error(f"获取班级失败: {e}")
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        api_logger.error(f"获取班级异常: {e}")
        raise HTTPException(status_code=500, detail="服务器内部错误")


@router.put("/{class_id}", response_model=ResponseModel[ClassResponse])
async def update_class(class_id: int, class_data: ClassUpdate):
    """更新班级"""
    try:
        result = class_service.update_class(class_id, class_data)
        api_logger.info(f"更新班级成功: {class_id}")
        return ResponseModel(
            success=True,
            data=result,
            message="班级更新成功"
        )
    except ClassNotFoundException as e:
        api_logger.error(f"班级不存在: {e}")
        raise HTTPException(status_code=404, detail=str(e))
    except ServiceException as e:
        api_logger.error(f"更新班级失败: {e}")
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        api_logger.error(f"更新班级异常: {e}")
        raise HTTPException(status_code=500, detail="服务器内部错误")


@router.delete("/{class_id}", response_model=ResponseModel[bool])
async def delete_class(class_id: int):
    """删除班级"""
    try:
        result = class_service.delete_class(class_id)
        api_logger.info(f"删除班级成功: {class_id}")
        return ResponseModel(
            success=True,
            data=result,
            message="班级删除成功"
        )
    except ClassNotFoundException as e:
        api_logger.error(f"班级不存在: {e}")
        raise HTTPException(status_code=404, detail=str(e))
    except ServiceException as e:
        api_logger.error(f"删除班级失败: {e}")
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        api_logger.error(f"删除班级异常: {e}")
        raise HTTPException(status_code=500, detail="服务器内部错误") 