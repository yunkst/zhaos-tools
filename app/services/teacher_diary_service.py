from datetime import datetime
from typing import List, Optional, Tuple
from app.core.database import db_manager
from app.schemas.teacher_diary import TeacherDiaryCreate, TeacherDiaryUpdate, TeacherDiaryResponse
from app.utils.exceptions import DatabaseException, NotFoundError
import math


class TeacherDiaryService:
    """教师日记服务类"""
    
    @staticmethod
    def create_diary(diary_data: TeacherDiaryCreate) -> TeacherDiaryResponse:
        """创建教师日记"""
        try:
            query = """
            INSERT INTO teacher_diaries (title, content, markdown_content, images, tags)
            VALUES (?, ?, ?, ?, ?)
            """
            
            diary_id = db_manager.execute_insert(
                query,
                (diary_data.title, diary_data.content, diary_data.markdown_content,
                 diary_data.images, diary_data.tags)
            )
            
            return TeacherDiaryService.get_diary_by_id(diary_id)
        except Exception as e:
            raise DatabaseException(f"创建教师日记失败: {str(e)}")
    
    @staticmethod
    def get_diary_by_id(diary_id: int) -> TeacherDiaryResponse:
        """根据ID获取教师日记"""
        try:
            query = "SELECT * FROM teacher_diaries WHERE id = ?"
            result = db_manager.execute_query(query, (diary_id,))
            
            if not result:
                raise NotFoundError(f"未找到ID为{diary_id}的教师日记")
            
            diary = result[0]
            return TeacherDiaryResponse(
                id=diary[0],
                title=diary[1],
                content=diary[2],
                markdown_content=diary[3],
                images=diary[4],
                tags=diary[5],
                created_at=datetime.fromisoformat(diary[6]),
                updated_at=datetime.fromisoformat(diary[7])
            )
        except NotFoundError:
            raise
        except Exception as e:
            raise DatabaseException(f"获取教师日记失败: {str(e)}")
    
    @staticmethod
    def get_diaries(
        page: int = 1,
        page_size: int = 20,
        keyword: Optional[str] = None,
        tags: Optional[str] = None
    ) -> Tuple[List[TeacherDiaryResponse], int]:
        """获取教师日记列表"""
        try:
            # 构建查询条件
            where_conditions = []
            params = []
            
            if keyword:
                where_conditions.append("(title LIKE ? OR content LIKE ?)")
                params.extend([f"%{keyword}%", f"%{keyword}%"])
            
            if tags:
                where_conditions.append("tags LIKE ?")
                params.append(f"%{tags}%")
            
            where_clause = ""
            if where_conditions:
                where_clause = "WHERE " + " AND ".join(where_conditions)
            
            # 获取总数
            count_query = f"SELECT COUNT(*) FROM teacher_diaries {where_clause}"
            count_result = db_manager.execute_query(count_query, params)
            total = count_result[0][0] if count_result else 0
            
            # 获取分页数据
            offset = (page - 1) * page_size
            query = f"""
            SELECT * FROM teacher_diaries {where_clause}
            ORDER BY created_at DESC
            LIMIT ? OFFSET ?
            """
            params.extend([page_size, offset])
            
            results = db_manager.execute_query(query, params)
            
            diaries = []
            for row in results:
                diary = TeacherDiaryResponse(
                    id=row[0],
                    title=row[1],
                    content=row[2],
                    markdown_content=row[3],
                    images=row[4],
                    tags=row[5],
                    created_at=datetime.fromisoformat(row[6]),
                    updated_at=datetime.fromisoformat(row[7])
                )
                diaries.append(diary)
            
            return diaries, total
        except Exception as e:
            raise DatabaseException(f"获取教师日记列表失败: {str(e)}")
    
    @staticmethod
    def update_diary(diary_id: int, diary_data: TeacherDiaryUpdate) -> TeacherDiaryResponse:
        """更新教师日记"""
        try:
            # 检查日记是否存在
            existing_diary = TeacherDiaryService.get_diary_by_id(diary_id)
            
            # 构建更新字段
            update_fields = []
            params = []
            
            if diary_data.title is not None:
                update_fields.append("title = ?")
                params.append(diary_data.title)
            
            if diary_data.content is not None:
                update_fields.append("content = ?")
                params.append(diary_data.content)
            
            if diary_data.markdown_content is not None:
                update_fields.append("markdown_content = ?")
                params.append(diary_data.markdown_content)
            
            if diary_data.images is not None:
                update_fields.append("images = ?")
                params.append(diary_data.images)
            
            if diary_data.tags is not None:
                update_fields.append("tags = ?")
                params.append(diary_data.tags)
            
            if not update_fields:
                return existing_diary
            
            # 添加更新时间
            update_fields.append("updated_at = CURRENT_TIMESTAMP")
            params.append(diary_id)
            
            query = f"""
            UPDATE teacher_diaries
            SET {', '.join(update_fields)}
            WHERE id = ?
            """
            
            db_manager.execute_update(query, params)
            
            return TeacherDiaryService.get_diary_by_id(diary_id)
        except NotFoundError:
            raise
        except Exception as e:
            raise DatabaseException(f"更新教师日记失败: {str(e)}")
    
    @staticmethod
    def delete_diary(diary_id: int) -> bool:
        """删除教师日记"""
        try:
            # 检查日记是否存在
            TeacherDiaryService.get_diary_by_id(diary_id)
            
            query = "DELETE FROM teacher_diaries WHERE id = ?"
            affected_rows = db_manager.execute_update(query, (diary_id,))
            
            return affected_rows > 0
        except NotFoundError:
            raise
        except Exception as e:
            raise DatabaseException(f"删除教师日记失败: {str(e)}")
    
    @staticmethod
    def search_diaries(
        keyword: Optional[str] = None,
        tags: Optional[str] = None,
        page: int = 1,
        page_size: int = 20
    ) -> Tuple[List[TeacherDiaryResponse], int]:
        """搜索教师日记"""
        return TeacherDiaryService.get_diaries(
            page=page,
            page_size=page_size,
            keyword=keyword,
            tags=tags
        )