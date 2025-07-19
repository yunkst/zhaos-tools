# 打卡服务模块

from .checkin_service import CheckInService
from .checkin_batch_service import CheckInBatchService
from .checkin_stats_service import CheckInStatsService
from .checkin_reply_service import CheckInReplyService

# 创建服务实例
checkin_service = CheckInService()
checkin_batch_service = CheckInBatchService()
checkin_stats_service = CheckInStatsService()
checkin_reply_service = CheckInReplyService()

__all__ = [
    'CheckInService',
    'CheckInBatchService', 
    'CheckInStatsService',
    'CheckInReplyService',
    'checkin_service',
    'checkin_batch_service',
    'checkin_stats_service',
    'checkin_reply_service'
]