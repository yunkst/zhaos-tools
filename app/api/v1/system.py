"""
系统API路由
"""

import sys
from fastapi import APIRouter, HTTPException

from app.schemas.common import ResponseModel, SystemInfo
from app.schemas.checkin import AutoReplyRequest, AutoReplyResponse
from app.services.reply_service import reply_service
from app.core.config import settings
from app.core.logger import api_logger
from app.utils.exceptions import ServiceException


router = APIRouter()


@router.get("/system/info", response_model=ResponseModel)
async def get_system_info():
    """获取系统信息"""
    try:
        system_info = SystemInfo(
            app_name=settings.APP_NAME,
            version=settings.APP_VERSION,
            description=settings.APP_DESCRIPTION,
            python_version=sys.version,
            platform=sys.platform,
            database_path=str(settings.database_path)
        )
        
        return ResponseModel(
            success=True,
            data=system_info.dict()
        )
        
    except Exception as e:
        api_logger.error(f"获取系统信息失败: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/system/auto-reply", response_model=ResponseModel)
async def generate_auto_reply(request: AutoReplyRequest):
    """生成自动回复"""
    try:
        reply = reply_service.generate_reply(request.content)
        
        return ResponseModel(
            success=True,
            data=AutoReplyResponse(reply=reply).dict()
        )
        
    except ServiceException as e:
        api_logger.error(f"生成自动回复失败: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/system/reply-templates", response_model=ResponseModel)
async def get_reply_templates():
    """获取所有回复模板"""
    try:
        templates = reply_service.get_all_templates()
        
        return ResponseModel(
            success=True,
            data=templates
        )
        
    except ServiceException as e:
        api_logger.error(f"获取回复模板失败: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/system/reply-templates", response_model=ResponseModel)
async def add_reply_template(template: dict):
    """添加自定义回复模板"""
    try:
        template_text = template.get("template", "").strip()
        if not template_text:
            raise HTTPException(status_code=400, detail="模板内容不能为空")
        
        success = reply_service.add_custom_template(template_text)
        
        return ResponseModel(
            success=success,
            message="模板添加成功" if success else "模板已存在"
        )
        
    except ServiceException as e:
        api_logger.error(f"添加回复模板失败: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/system/reply-templates", response_model=ResponseModel)
async def remove_reply_template(template: dict):
    """删除自定义回复模板"""
    try:
        template_text = template.get("template", "").strip()
        if not template_text:
            raise HTTPException(status_code=400, detail="模板内容不能为空")
        
        success = reply_service.remove_custom_template(template_text)
        
        return ResponseModel(
            success=success,
            message="模板删除成功" if success else "模板不存在"
        )
        
    except ServiceException as e:
        api_logger.error(f"删除回复模板失败: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/system/analyze-content", response_model=ResponseModel)
async def analyze_content(request: AutoReplyRequest):
    """分析内容情感"""
    try:
        analysis = reply_service.analyze_content_sentiment(request.content)
        
        return ResponseModel(
            success=True,
            data=analysis
        )
        
    except ServiceException as e:
        api_logger.error(f"分析内容失败: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/system/health", response_model=ResponseModel)
async def health_check():
    """健康检查"""
    return ResponseModel(
        success=True,
        message="系统运行正常",
        data={
            "status": "healthy",
            "timestamp": "2024-01-01T00:00:00Z"
        }
    ) 