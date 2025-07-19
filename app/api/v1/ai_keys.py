""" 
AI Key管理API路由
"""

from fastapi import APIRouter, HTTPException, Query
from typing import List, Optional
from app.schemas.ai_key_schema import (
    AIKeyCreate,
    AIKeyUpdate,
    AIKeyResponse,
    AIKeyDetailResponse,
    AIKeyListResponse,
    AIProviderType
)
from app.schemas.common import ResponseModel
from app.services.ai_key_service import ai_key_service, AIKeyNotFoundException
from app.utils.exceptions import ServiceException
from app.core.logger import api_logger

router = APIRouter()


@router.get("/ai-keys", response_model=ResponseModel[AIKeyListResponse])
async def get_ai_keys(
    provider_type: Optional[str] = Query(None, description="服务商类型过滤"),
    is_active: Optional[bool] = Query(None, description="是否启用过滤")
):
    """获取AI Key列表"""
    try:
        keys = ai_key_service.get_all_ai_keys(provider_type=provider_type, is_active=is_active)
        
        return ResponseModel(
            success=True,
            data=AIKeyListResponse(
                keys=keys,
                total=len(keys)
            ),
            message="获取AI Key列表成功"
        )
        
    except ServiceException as e:
        api_logger.error(f"获取AI Key列表失败: {e}")
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        api_logger.error(f"获取AI Key列表异常: {e}")
        raise HTTPException(status_code=500, detail="服务器内部错误")


@router.get("/ai-keys/{key_id}", response_model=ResponseModel[AIKeyResponse])
async def get_ai_key(key_id: int):
    """获取单个AI Key（脱敏）"""
    try:
        ai_key = ai_key_service.get_ai_key_by_id(key_id)
        return ResponseModel(
            success=True,
            data=ai_key,
            message="获取AI Key成功"
        )
        
    except AIKeyNotFoundException as e:
        raise HTTPException(status_code=404, detail=str(e))
    except ServiceException as e:
        api_logger.error(f"获取AI Key失败: {e}")
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        api_logger.error(f"获取AI Key异常: {e}")
        raise HTTPException(status_code=500, detail="服务器内部错误")


@router.get("/ai-keys/{key_id}/detail", response_model=ResponseModel[AIKeyDetailResponse])
async def get_ai_key_detail(key_id: int):
    """获取AI Key详情（包含完整API Key）"""
    try:
        ai_key = ai_key_service.get_ai_key_detail_by_id(key_id)
        return ResponseModel(
            success=True,
            data=ai_key,
            message="获取AI Key详情成功"
        )
        
    except AIKeyNotFoundException as e:
        raise HTTPException(status_code=404, detail=str(e))
    except ServiceException as e:
        api_logger.error(f"获取AI Key详情失败: {e}")
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        api_logger.error(f"获取AI Key详情异常: {e}")
        raise HTTPException(status_code=500, detail="服务器内部错误")


@router.post("/ai-keys", response_model=ResponseModel[AIKeyResponse])
async def create_ai_key(ai_key: AIKeyCreate):
    """创建AI Key"""
    try:
        result = ai_key_service.create_ai_key(ai_key)
        return ResponseModel(
            success=True,
            data=result,
            message="创建AI Key成功"
        )
        
    except ServiceException as e:
        api_logger.error(f"创建AI Key失败: {e}")
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        api_logger.error(f"创建AI Key异常: {e}")
        raise HTTPException(status_code=500, detail="服务器内部错误")


@router.put("/ai-keys/{key_id}", response_model=ResponseModel[AIKeyResponse])
async def update_ai_key(key_id: int, ai_key: AIKeyUpdate):
    """更新AI Key"""
    try:
        result = ai_key_service.update_ai_key(key_id, ai_key)
        return ResponseModel(
            success=True,
            data=result,
            message="更新AI Key成功"
        )
        
    except AIKeyNotFoundException as e:
        raise HTTPException(status_code=404, detail=str(e))
    except ServiceException as e:
        api_logger.error(f"更新AI Key失败: {e}")
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        api_logger.error(f"更新AI Key异常: {e}")
        raise HTTPException(status_code=500, detail="服务器内部错误")


@router.delete("/ai-keys/{key_id}", response_model=ResponseModel[bool])
async def delete_ai_key(key_id: int):
    """删除AI Key"""
    try:
        result = ai_key_service.delete_ai_key(key_id)
        return ResponseModel(
            success=True,
            data=result,
            message="删除AI Key成功"
        )
        
    except AIKeyNotFoundException as e:
        raise HTTPException(status_code=404, detail=str(e))
    except ServiceException as e:
        api_logger.error(f"删除AI Key失败: {e}")
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        api_logger.error(f"删除AI Key异常: {e}")
        raise HTTPException(status_code=500, detail="服务器内部错误")


@router.get("/ai-keys/providers/types", response_model=ResponseModel[List[dict]])
async def get_provider_types():
    """获取支持的AI服务商类型"""
    try:
        provider_types = [
            {"value": provider.value, "label": provider.value.upper()}
            for provider in AIProviderType
        ]
        
        # 添加中文标签
        provider_labels = {
            "openai": "OpenAI",
            "claude": "Claude (Anthropic)",
            "qianwen": "通义千问",
            "baidu": "百度文心",
            "zhipu": "智谱AI",
            "custom": "自定义"
        }
        
        for provider in provider_types:
            provider["label"] = provider_labels.get(provider["value"], provider["value"].upper())
        
        return ResponseModel(
            success=True,
            data=provider_types,
            message="获取服务商类型成功"
        )
        
    except Exception as e:
        api_logger.error(f"获取服务商类型异常: {e}")
        raise HTTPException(status_code=500, detail="服务器内部错误")