"""
配置管理API路由
"""

from fastapi import APIRouter, HTTPException, Query
from typing import List, Optional
from app.schemas.config_schema import (
    ConfigCreate,
    ConfigUpdate,
    ConfigResponse,
    ConfigListResponse,
    ConfigGroupResponse,
    ConfigBatchUpdate
)
from app.schemas.common import ResponseModel
from app.services.config_service import config_service, ConfigNotFoundException
from app.utils.exceptions import ServiceException
from app.core.logger import api_logger

router = APIRouter()


@router.get("/configs", response_model=ResponseModel[ConfigListResponse])
async def get_configs(
    group: Optional[str] = Query(None, description="配置组前缀")
):
    """获取配置列表"""
    try:
        if group:
            configs = config_service.get_configs_by_group(group)
        else:
            configs = config_service.get_all_configs()
        
        return ResponseModel(
            success=True,
            data=ConfigListResponse(
                configs=configs,
                total=len(configs)
            ),
            message="获取配置列表成功"
        )
        
    except ServiceException as e:
        api_logger.error(f"获取配置列表失败: {e}")
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        api_logger.error(f"获取配置列表异常: {e}")
        raise HTTPException(status_code=500, detail="服务器内部错误")


@router.get("/configs/{key}", response_model=ResponseModel[ConfigResponse])
async def get_config(key: str):
    """获取单个配置"""
    try:
        config = config_service.get_config_by_key(key)
        return ResponseModel(
            success=True,
            data=config,
            message="获取配置成功"
        )
        
    except ConfigNotFoundException as e:
        raise HTTPException(status_code=404, detail=str(e))
    except ServiceException as e:
        api_logger.error(f"获取配置失败: {e}")
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        api_logger.error(f"获取配置异常: {e}")
        raise HTTPException(status_code=500, detail="服务器内部错误")


@router.post("/configs", response_model=ResponseModel[ConfigResponse])
async def create_config(config: ConfigCreate):
    """创建配置"""
    try:
        result = config_service.create_config(config)
        return ResponseModel(
            success=True,
            data=result,
            message="创建配置成功"
        )
        
    except ServiceException as e:
        api_logger.error(f"创建配置失败: {e}")
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        api_logger.error(f"创建配置异常: {e}")
        raise HTTPException(status_code=500, detail="服务器内部错误")


@router.put("/configs/{key}", response_model=ResponseModel[ConfigResponse])
async def update_config(key: str, config: ConfigUpdate):
    """更新配置"""
    try:
        result = config_service.update_config(key, config)
        return ResponseModel(
            success=True,
            data=result,
            message="更新配置成功"
        )
        
    except ConfigNotFoundException as e:
        raise HTTPException(status_code=404, detail=str(e))
    except ServiceException as e:
        api_logger.error(f"更新配置失败: {e}")
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        api_logger.error(f"更新配置异常: {e}")
        raise HTTPException(status_code=500, detail="服务器内部错误")


@router.delete("/configs/{key}", response_model=ResponseModel[bool])
async def delete_config(key: str):
    """删除配置"""
    try:
        result = config_service.delete_config(key)
        return ResponseModel(
            success=True,
            data=result,
            message="删除配置成功"
        )
        
    except ConfigNotFoundException as e:
        raise HTTPException(status_code=404, detail=str(e))
    except ServiceException as e:
        api_logger.error(f"删除配置失败: {e}")
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        api_logger.error(f"删除配置异常: {e}")
        raise HTTPException(status_code=500, detail="服务器内部错误")


@router.post("/configs/batch", response_model=ResponseModel[List[ConfigResponse]])
async def batch_update_configs(batch_request: ConfigBatchUpdate):
    """批量更新配置"""
    try:
        results = config_service.batch_update_configs(batch_request.configs)
        return ResponseModel(
            success=True,
            data=results,
            message=f"批量更新 {len(results)} 个配置成功"
        )
        
    except ServiceException as e:
        api_logger.error(f"批量更新配置失败: {e}")
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        api_logger.error(f"批量更新配置异常: {e}")
        raise HTTPException(status_code=500, detail="服务器内部错误")


@router.get("/configs/groups/ai", response_model=ResponseModel[ConfigGroupResponse])
async def get_ai_configs():
    """获取AI相关配置"""
    try:
        configs = config_service.get_configs_by_group("AI_")
        openai_configs = config_service.get_configs_by_group("OPENAI_")
        langfuse_configs = config_service.get_configs_by_group("LANGFUSE_")
        
        all_configs = configs + openai_configs + langfuse_configs
        
        return ResponseModel(
            success=True,
            data=ConfigGroupResponse(
                group_name="AI配置",
                configs=all_configs
            ),
            message="获取AI配置成功"
        )
        
    except ServiceException as e:
        api_logger.error(f"获取AI配置失败: {e}")
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        api_logger.error(f"获取AI配置异常: {e}")
        raise HTTPException(status_code=500, detail="服务器内部错误")