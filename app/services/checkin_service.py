"""打卡服务层 - 兼容性包装类"""

from typing import List, Optional, Dict, Any
from datetime import datetime, date

from app.core.logger import service_logger
from app.services.checkin.checkin_service import CheckInService as NewCheckInService
from app.services.checkin.checkin_batch_service import CheckInBatchService
from app.services.checkin.checkin_stats_service import CheckInStatsService
from app.services.checkin.checkin_reply_service import CheckInReplyService
from app.schemas.checkin import CheckInCreate, CheckInUpdate
from app.utils.exceptions import (
    StudentNotFoundException,
    ServiceException
)


class CheckInService:
    """打卡服务兼容性包装类 - 保持向后兼容性"""
    
    def __init__(self):
        self.checkin_service = NewCheckInService()
        self.batch_service = CheckInBatchService()
        self.stats_service = CheckInStatsService()
        self.reply_service = CheckInReplyService()
        
        service_logger.info("初始化打卡服务兼容性包装类")
    
    def get_checkins(
        self,
        page: int = 1,
        page_size: int = 20,
        student_id: Optional[str] = None,
        start_date: Optional[date] = None,
        end_date: Optional[date] = None,
        search: Optional[str] = None
    ) -> Dict[str, Any]:
        """获取打卡记录列表 - 委托给新的服务"""
        filters = {}
        if student_id:
            filters['student_id'] = student_id
        if start_date:
            filters['date_from'] = start_date
        if end_date:
            filters['date_to'] = end_date
        if search:
            filters['search'] = search
            
        return self.checkin_service.get_checkins(
            page=page,
            page_size=page_size,
            **filters
        )
    
    def get_checkin_by_id(self, checkin_id: int) -> Optional[Dict[str, Any]]:
        """根据ID获取打卡记录 - 委托给新的服务"""
        return self.checkin_service.get_checkin_by_id(checkin_id)
    
    def create_checkin(self, checkin_data: CheckInCreate) -> Dict[str, Any]:
        """创建打卡记录 - 委托给新的服务"""
        return self.checkin_service.create_checkin(checkin_data)
    
    def update_checkin(self, checkin_id: int, checkin_data: CheckInUpdate) -> Dict[str, Any]:
        """更新打卡记录 - 委托给新的服务"""
        return self.checkin_service.update_checkin(checkin_id, checkin_data)
    
    def delete_checkin(self, checkin_id: int) -> bool:
        """删除打卡记录 - 委托给新的服务"""
        return self.checkin_service.delete_checkin(checkin_id)
    
    def get_student_checkins(
        self,
        student_id: str,
        page: int = 1,
        page_size: int = 20,
        start_date: Optional[date] = None,
        end_date: Optional[date] = None
    ) -> Dict[str, Any]:
        """获取指定学生的打卡记录 - 委托给新的服务"""
        # 将student_id转换为int类型，因为新服务期望int类型
        try:
            student_id_int = int(student_id)
        except (ValueError, TypeError):
            # 如果转换失败，尝试通过学号查找学生ID
            from app.services.student.student_service import StudentService as NewStudentService
            student_service = NewStudentService()
            student = student_service.get_student_by_student_id(student_id)
            if not student:
                raise StudentNotFoundException(f"学生 {student_id} 不存在")
            student_id_int = student['id']
            
        return self.checkin_service.get_student_checkins(
            student_id=student_id_int,
            page=page,
            page_size=page_size
        )
    
    def get_checkin_stats(self) -> Dict[str, Any]:
        """获取打卡统计信息 - 委托给统计服务"""
        return self.stats_service.get_checkin_stats()
    
    def get_checkins_by_date_range(
        self,
        start_date: date,
        end_date: date,
        student_id: Optional[str] = None
    ) -> List[Dict[str, Any]]:
        """根据日期范围获取打卡记录 - 委托给批量服务"""
        return self.batch_service.get_checkins_by_date_range(
            start_date=start_date,
            end_date=end_date,
            student_id=student_id
        )
    
    def batch_update_replies(self, checkin_ids: List[int], auto_reply: str) -> Dict[str, Any]:
        """批量更新回复 - 委托给批量服务"""
        return self.batch_service.batch_update_replies(
            checkin_ids=checkin_ids,
            auto_reply=auto_reply
        )


# 创建全局打卡服务实例
checkin_service = CheckInService()