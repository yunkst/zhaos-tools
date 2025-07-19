"""
学生搜索API - 处理学生的搜索和查询功能
"""

from typing import Dict, Any, Optional, List
from fastapi import APIRouter, HTTPException, Query, status
from pydantic import BaseModel

from app.services.student import student_search_service
from app.utils.exceptions import ServiceException
from app.core.logger import api_logger

router = APIRouter()


class AdvancedSearchRequest(BaseModel):
    """高级搜索请求模型"""
    search_term: str
    search_fields: Optional[List[str]] = None
    page: int = 1
    page_size: int = 20


@router.get("/")
async def get_students(
    page: int = Query(1, ge=1, description="页码"),
    page_size: int = Query(20, ge=1, le=100, description="每页数量"),
    class_name: Optional[str] = Query(None, description="班级名称过滤"),
    search_term: Optional[str] = Query(None, description="搜索关键词（姓名、学号）"),
    sort_by: str = Query("student_id", description="排序字段"),
    sort_order: str = Query("asc", regex="^(asc|desc)$", description="排序方向")
) -> Dict[str, Any]:
    """
    获取学生列表（支持分页、搜索、排序）
    
    Args:
        page: 页码，默认为1
        page_size: 每页数量，默认为20，最大100
        class_name: 班级名称过滤
        search_term: 搜索关键词（姓名、学号）
        sort_by: 排序字段，可选值：student_id, name, class_name, age, created_at
        sort_order: 排序方向，可选值：asc, desc
    
    Returns:
        Dict: 包含学生列表和分页信息的结果
    """
    try:
        api_logger.info(f"获取学生列表请求: 页码 {page}, 每页 {page_size}, 班级 {class_name}, 搜索 {search_term}")
        
        result = student_search_service.get_students(
            page=page,
            page_size=page_size,
            class_name=class_name,
            search_term=search_term,
            sort_by=sort_by,
            sort_order=sort_order
        )
        
        api_logger.info(f"获取学生列表成功: {len(result['students'])} 条记录")
        return {
            "code": 200,
            "message": "获取学生列表成功",
            "data": result
        }
        
    except ServiceException as e:
        api_logger.error(f"获取学生列表失败 - 服务异常: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )
    except Exception as e:
        api_logger.error(f"获取学生列表失败 - 未知错误: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="获取学生列表失败"
        )


@router.post("/search")
async def search_students(request: AdvancedSearchRequest) -> Dict[str, Any]:
    """
    高级搜索学生
    
    Args:
        request: 高级搜索请求
    
    Returns:
        Dict: 包含搜索结果和分页信息
    
    Request Body Example:
        {
            "search_term": "张三",
            "search_fields": ["name", "student_id", "phone"],
            "page": 1,
            "page_size": 20
        }
    """
    try:
        api_logger.info(f"高级搜索学生请求: 关键词 {request.search_term}, 字段 {request.search_fields}")
        
        if not request.search_term or not request.search_term.strip():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="搜索关键词不能为空"
            )
        
        if request.page < 1:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="页码必须大于0"
            )
        
        if request.page_size < 1 or request.page_size > 100:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="每页数量必须在1-100之间"
            )
        
        result = student_search_service.search_students(
            search_term=request.search_term,
            search_fields=request.search_fields,
            page=request.page,
            page_size=request.page_size
        )
        
        api_logger.info(f"高级搜索学生成功: 关键词 {request.search_term}, {len(result['students'])} 条记录")
        return {
            "code": 200,
            "message": f"搜索完成，找到 {result['total']} 条记录",
            "data": result
        }
        
    except HTTPException:
        raise
    except ServiceException as e:
        api_logger.error(f"高级搜索学生失败 - 服务异常: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )
    except Exception as e:
        api_logger.error(f"高级搜索学生失败 - 未知错误: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="搜索学生失败"
        )


@router.get("/search/simple")
async def simple_search_students(
    q: str = Query(..., min_length=1, description="搜索关键词"),
    page: int = Query(1, ge=1, description="页码"),
    page_size: int = Query(20, ge=1, le=100, description="每页数量")
) -> Dict[str, Any]:
    """
    简单搜索学生（在姓名、学号、电话、班级中搜索）
    
    Args:
        q: 搜索关键词
        page: 页码，默认为1
        page_size: 每页数量，默认为20，最大100
    
    Returns:
        Dict: 包含搜索结果和分页信息
    """
    try:
        api_logger.info(f"简单搜索学生请求: 关键词 {q}")
        
        result = student_search_service.search_students(
            search_term=q,
            search_fields=['name', 'student_id', 'phone', 'class_name'],
            page=page,
            page_size=page_size
        )
        
        api_logger.info(f"简单搜索学生成功: 关键词 {q}, {len(result['students'])} 条记录")
        return {
            "code": 200,
            "message": f"搜索完成，找到 {result['total']} 条记录",
            "data": result
        }
        
    except ServiceException as e:
        api_logger.error(f"简单搜索学生失败 - 服务异常: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )
    except Exception as e:
        api_logger.error(f"简单搜索学生失败 - 未知错误: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="搜索学生失败"
        )


@router.get("/statistics")
async def get_students_statistics() -> Dict[str, Any]:
    """
    获取学生统计信息
    
    Returns:
        Dict: 包含各种统计信息
    """
    try:
        api_logger.info("获取学生统计信息请求")
        
        stats = student_search_service.get_students_statistics()
        
        api_logger.info(f"获取学生统计信息成功: 总学生数 {stats['total_students']}")
        return {
            "code": 200,
            "message": "获取学生统计信息成功",
            "data": stats
        }
        
    except ServiceException as e:
        api_logger.error(f"获取学生统计信息失败 - 服务异常: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )
    except Exception as e:
        api_logger.error(f"获取学生统计信息失败 - 未知错误: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="获取学生统计信息失败"
        )


@router.get("/search/fields")
async def get_search_fields() -> Dict[str, Any]:
    """
    获取可搜索的字段列表
    
    Returns:
        Dict: 可搜索字段的配置信息
    """
    try:
        api_logger.info("获取搜索字段列表请求")
        
        search_fields = {
            'name': {'label': '姓名', 'type': 'string', 'description': '学生姓名'},
            'student_id': {'label': '学号', 'type': 'string', 'description': '学生学号'},
            'phone': {'label': '电话', 'type': 'string', 'description': '联系电话'},
            'class_name': {'label': '班级', 'type': 'string', 'description': '所在班级'},
            'email': {'label': '邮箱', 'type': 'string', 'description': '电子邮箱'},
            'qq': {'label': 'QQ', 'type': 'string', 'description': 'QQ号码'},
            'wechat': {'label': '微信', 'type': 'string', 'description': '微信号'},
            'address': {'label': '地址', 'type': 'string', 'description': '家庭地址'},
            'notes': {'label': '备注', 'type': 'string', 'description': '备注信息'},
            'id_card': {'label': '身份证号', 'type': 'string', 'description': '身份证号码'},
            'primary_school': {'label': '小学', 'type': 'string', 'description': '毕业小学'}
        }
        
        sort_fields = {
            'student_id': {'label': '学号', 'type': 'string'},
            'name': {'label': '姓名', 'type': 'string'},
            'class_name': {'label': '班级', 'type': 'string'},
            'age': {'label': '年龄', 'type': 'number'},
            'created_at': {'label': '创建时间', 'type': 'datetime'}
        }
        
        result = {
            'search_fields': search_fields,
            'sort_fields': sort_fields,
            'sort_orders': [
                {'value': 'asc', 'label': '升序'},
                {'value': 'desc', 'label': '降序'}
            ]
        }
        
        api_logger.info("获取搜索字段列表成功")
        return {
            "code": 200,
            "message": "获取搜索字段列表成功",
            "data": result
        }
        
    except Exception as e:
        api_logger.error(f"获取搜索字段列表失败 - 未知错误: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="获取搜索字段列表失败"
        )