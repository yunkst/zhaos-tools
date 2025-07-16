"""
打卡管理API路由
"""

from fastapi import APIRouter, HTTPException, Query, Path
from typing import Optional
from datetime import date, datetime

from app.schemas.checkin import (
    CheckInCreate,
    CheckInUpdate,
    CheckInResponse,
    CheckInWithStudentResponse,
    CheckInListResponse,
    AutoReplyRequest,
    AutoReplyResponse
)
from app.schemas.common import ResponseModel, PaginatedResponse
from app.services.checkin_service import checkin_service
from app.services.reply_service import reply_service
from app.utils.exceptions import (
    StudentNotFoundException,
    ServiceException
)
from app.core.logger import api_logger


router = APIRouter()


@router.get("/checkins", response_model=PaginatedResponse)
async def get_checkins(
    page: int = Query(1, ge=1, description="页码"),
    page_size: int = Query(20, ge=1, le=100, description="每页数量"),
    student_id: Optional[str] = Query(None, description="学生学号"),
    start_date: Optional[date] = Query(None, description="开始日期"),
    end_date: Optional[date] = Query(None, description="结束日期"),
    search: Optional[str] = Query(None, description="搜索关键词")
):
    """获取打卡记录列表"""
    try:
        result = checkin_service.get_checkins(
            page=page,
            page_size=page_size,
            student_id=student_id,
            start_date=start_date,
            end_date=end_date,
            search=search
        )
        
        return ResponseModel(
            success=True,
            data=result['records'],
            pagination={
                'page': result['page'],
                'page_size': result['page_size'],
                'total': result['total'],
                'total_pages': result['total_pages']
            }
        )
        
    except ServiceException as e:
        api_logger.error(f"获取打卡记录列表失败: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/checkins/{checkin_id}", response_model=ResponseModel)
async def get_checkin(
    checkin_id: int = Path(..., description="打卡记录ID")
):
    """获取单个打卡记录"""
    try:
        checkin = checkin_service.get_checkin_by_id(checkin_id)
        return ResponseModel(success=True, data=checkin)
        
    except ServiceException as e:
        api_logger.error(f"获取打卡记录失败: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/checkins", response_model=ResponseModel)
async def create_checkin(checkin_data: CheckInCreate):
    """创建打卡记录"""
    try:
        new_checkin = checkin_service.create_checkin(checkin_data)
        return ResponseModel(
            success=True,
            message="打卡记录创建成功",
            data=new_checkin
        )
        
    except StudentNotFoundException as e:
        api_logger.warning(f"学生未找到: {checkin_data.student_id}")
        raise HTTPException(status_code=404, detail=str(e))
    except ServiceException as e:
        api_logger.error(f"创建打卡记录失败: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.put("/checkins/{checkin_id}", response_model=ResponseModel)
async def update_checkin(
    checkin_id: int = Path(..., description="打卡记录ID"),
    checkin_data: CheckInUpdate = None
):
    """更新打卡记录"""
    try:
        updated_checkin = checkin_service.update_checkin(checkin_id, checkin_data)
        return ResponseModel(
            success=True,
            message="打卡记录更新成功",
            data=updated_checkin
        )
        
    except ServiceException as e:
        api_logger.error(f"更新打卡记录失败: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/checkins/{checkin_id}", response_model=ResponseModel)
async def delete_checkin(
    checkin_id: int = Path(..., description="打卡记录ID")
):
    """删除打卡记录"""
    try:
        success = checkin_service.delete_checkin(checkin_id)
        if success:
            return ResponseModel(
                success=True,
                message="打卡记录删除成功"
            )
        else:
            raise HTTPException(status_code=500, detail="删除失败")
            
    except ServiceException as e:
        api_logger.error(f"删除打卡记录失败: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/checkins/{checkin_id}/generate-reply", response_model=ResponseModel)
async def generate_reply_for_checkin(
    checkin_id: int = Path(..., description="打卡记录ID")
):
    """为打卡记录生成自动回复"""
    try:
        checkin = checkin_service.get_checkin_by_id(checkin_id)
        if not checkin:
            raise HTTPException(status_code=404, detail="打卡记录不存在")
        
        # 生成自动回复
        reply = reply_service.generate_reply(checkin['content'])
        
        # 更新打卡记录的回复
        update_data = CheckInUpdate(auto_reply=reply)
        updated_checkin = checkin_service.update_checkin(checkin_id, update_data)
        
        return ResponseModel(
            success=True,
            message="自动回复生成成功",
            data={
                'checkin': updated_checkin,
                'reply': reply
            }
        )
        
    except ServiceException as e:
        api_logger.error(f"生成自动回复失败: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/checkins/generate-reply", response_model=ResponseModel)
async def generate_reply(request: AutoReplyRequest):
    """生成自动回复（不关联具体打卡记录）"""
    try:
        reply = reply_service.generate_reply(request.content)
        return ResponseModel(
            success=True,
            data=AutoReplyResponse(reply=reply).dict()
        )
        
    except ServiceException as e:
        api_logger.error(f"生成自动回复失败: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/checkins/student/{student_id}", response_model=ResponseModel)
async def get_student_checkins(
    student_id: str = Path(..., description="学生学号"),
    page: int = Query(1, ge=1, description="页码"),
    page_size: int = Query(20, ge=1, le=100, description="每页数量"),
    start_date: Optional[date] = Query(None, description="开始日期"),
    end_date: Optional[date] = Query(None, description="结束日期")
):
    """获取指定学生的打卡记录"""
    try:
        result = checkin_service.get_student_checkins(
            student_id=student_id,
            page=page,
            page_size=page_size,
            start_date=start_date,
            end_date=end_date
        )
        
        return ResponseModel(
            success=True,
            data=result['records'],
            pagination={
                'page': result['page'],
                'page_size': result['page_size'],
                'total': result['total'],
                'total_pages': result['total_pages']
            }
        )
        
    except ServiceException as e:
        api_logger.error(f"获取学生打卡记录失败: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/checkins/stats/summary", response_model=ResponseModel)
async def get_checkin_stats():
    """获取打卡统计信息"""
    try:
        stats = checkin_service.get_checkin_stats()
        return ResponseModel(success=True, data=stats)
        
    except ServiceException as e:
        api_logger.error(f"获取打卡统计信息失败: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/checkins/batch-reply", response_model=ResponseModel)
async def batch_generate_replies(
    checkin_ids: list[int],
    force_regenerate: bool = Query(False, description="强制重新生成回复")
):
    """批量生成自动回复"""
    try:
        results = []
        success_count = 0
        failed_count = 0
        
        for checkin_id in checkin_ids:
            try:
                checkin = checkin_service.get_checkin_by_id(checkin_id)
                if not checkin:
                    results.append({
                        'checkin_id': checkin_id,
                        'success': False,
                        'error': '打卡记录不存在'
                    })
                    failed_count += 1
                    continue
                
                # 如果已有回复且不强制重新生成，则跳过
                if checkin.get('auto_reply') and not force_regenerate:
                    results.append({
                        'checkin_id': checkin_id,
                        'success': True,
                        'reply': checkin['auto_reply'],
                        'message': '使用现有回复'
                    })
                    success_count += 1
                    continue
                
                # 生成新回复
                reply = reply_service.generate_reply(checkin['content'])
                update_data = CheckInUpdate(auto_reply=reply)
                updated_checkin = checkin_service.update_checkin(checkin_id, update_data)
                
                results.append({
                    'checkin_id': checkin_id,
                    'success': True,
                    'reply': reply,
                    'message': '生成成功'
                })
                success_count += 1
                
            except Exception as e:
                results.append({
                    'checkin_id': checkin_id,
                    'success': False,
                    'error': str(e)
                })
                failed_count += 1
        
        return ResponseModel(
            success=True,
            message=f"批量生成完成，成功: {success_count}，失败: {failed_count}",
            data={
                'results': results,
                'success_count': success_count,
                'failed_count': failed_count,
                'total_count': len(checkin_ids)
            }
        )
        
    except ServiceException as e:
        api_logger.error(f"批量生成回复失败: {e}")
        raise HTTPException(status_code=500, detail=str(e)) 