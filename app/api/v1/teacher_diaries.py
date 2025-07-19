from fastapi import APIRouter, HTTPException, Query
from typing import Optional
from app.schemas.teacher_diary import (
    TeacherDiaryCreate,
    TeacherDiaryUpdate,
    TeacherDiaryResponse,
    TeacherDiaryListResponse
)
from app.services.teacher_diary_service import TeacherDiaryService
from app.utils.exceptions import DatabaseException, NotFoundError
import math

router = APIRouter()


@router.post("/", response_model=TeacherDiaryResponse)
async def create_diary(diary: TeacherDiaryCreate):
    """创建教师日记"""
    try:
        return TeacherDiaryService.create_diary(diary)
    except DatabaseException as e:
        raise HTTPException(status_code=500, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"创建教师日记失败: {str(e)}")


@router.get("/", response_model=TeacherDiaryListResponse)
async def get_diaries(
    page: int = Query(1, ge=1, description="页码"),
    page_size: int = Query(20, ge=1, le=100, description="每页数量"),
    keyword: Optional[str] = Query(None, description="搜索关键词"),
    tags: Optional[str] = Query(None, description="标签筛选")
):
    """获取教师日记列表"""
    try:
        diaries, total = TeacherDiaryService.get_diaries(
            page=page,
            page_size=page_size,
            keyword=keyword,
            tags=tags
        )
        
        total_pages = math.ceil(total / page_size) if total > 0 else 0
        
        return TeacherDiaryListResponse(
            diaries=diaries,
            total=total,
            page=page,
            page_size=page_size,
            total_pages=total_pages
        )
    except DatabaseException as e:
        raise HTTPException(status_code=500, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"获取教师日记列表失败: {str(e)}")


@router.get("/search/", response_model=TeacherDiaryListResponse)
async def search_diaries(
    page: int = Query(1, ge=1, description="页码"),
    page_size: int = Query(20, ge=1, le=100, description="每页数量"),
    keyword: Optional[str] = Query(None, description="搜索关键词"),
    tags: Optional[str] = Query(None, description="标签筛选")
):
    """搜索教师日记"""
    try:
        diaries, total = TeacherDiaryService.search_diaries(
            keyword=keyword,
            tags=tags,
            page=page,
            page_size=page_size
        )
        
        total_pages = math.ceil(total / page_size) if total > 0 else 0
        
        return TeacherDiaryListResponse(
            diaries=diaries,
            total=total,
            page=page,
            page_size=page_size,
            total_pages=total_pages
        )
    except DatabaseException as e:
        raise HTTPException(status_code=500, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"搜索教师日记失败: {str(e)}")


@router.get("/{diary_id}", response_model=TeacherDiaryResponse)
async def get_diary(diary_id: int):
    """根据ID获取教师日记"""
    try:
        return TeacherDiaryService.get_diary_by_id(diary_id)
    except NotFoundError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except DatabaseException as e:
        raise HTTPException(status_code=500, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"获取教师日记失败: {str(e)}")


@router.put("/{diary_id}", response_model=TeacherDiaryResponse)
async def update_diary(diary_id: int, diary: TeacherDiaryUpdate):
    """更新教师日记"""
    try:
        return TeacherDiaryService.update_diary(diary_id, diary)
    except NotFoundError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except DatabaseException as e:
        raise HTTPException(status_code=500, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"更新教师日记失败: {str(e)}")


@router.delete("/{diary_id}")
async def delete_diary(diary_id: int):
    """删除教师日记"""
    try:
        success = TeacherDiaryService.delete_diary(diary_id)
        if success:
            return {"message": "删除成功"}
        else:
            raise HTTPException(status_code=500, detail="删除失败")
    except NotFoundError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except DatabaseException as e:
        raise HTTPException(status_code=500, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"删除教师日记失败: {str(e)}")