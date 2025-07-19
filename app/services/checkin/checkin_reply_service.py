"""打卡回复服务 - 处理打卡记录的回复功能"""

from typing import Dict, Any, List, Optional
from datetime import datetime
import random

from app.core.database import db_manager
from app.core.logger import service_logger
from app.utils.exceptions import (
    NotFoundException,
    ServiceException
)


class CheckInReplyService:
    """打卡回复服务类"""
    
    def __init__(self):
        self.db = db_manager
        # 预设的自动回复模板
        self.auto_reply_templates = {
            '开心': [
                '看到你这么开心，老师也很高兴！继续保持这份快乐哦！😊',
                '你的快乐感染了老师，希望你每天都能这么开心！',
                '开心的心情是最好的学习状态，加油！',
                '你的笑容是最美的，继续保持这份阳光心态！'
            ],
            '难过': [
                '遇到困难不要气馁，老师相信你能克服的！💪',
                '每个人都会有低落的时候，重要的是要学会调整心态。',
                '有什么困扰可以和老师聊聊，我们一起想办法解决。',
                '困难只是暂时的，相信明天会更好！'
            ],
            '平静': [
                '平静的心态很好，这样更容易专注学习。',
                '保持内心的平静，这是一种很好的状态。',
                '平静中蕴含着力量，继续保持！',
                '心如止水，学习效果会更好哦！'
            ],
            '兴奋': [
                '你的兴奋劲儿很棒！把这份热情投入到学习中吧！',
                '看到你这么有活力，老师也被感染了！',
                '保持这份热情，但也要注意劳逸结合哦！',
                '你的活力是班级的正能量！'
            ],
            '焦虑': [
                '感到焦虑是正常的，深呼吸，放松一下。',
                '有什么让你焦虑的事情吗？可以和老师分享。',
                '焦虑时可以试试运动或听音乐来放松。',
                '记住，你比想象中更强大！'
            ],
            '疲惫': [
                '注意休息，身体健康最重要！',
                '感到疲惫时要适当放松，劳逸结合。',
                '早点休息，明天又是充满活力的一天！',
                '累了就休息，不要勉强自己。'
            ]
        }
        
        # 通用回复模板
        self.general_replies = [
            '谢谢你的分享，老师看到了你的成长！',
            '每一次打卡都是你进步的见证，继续加油！',
            '老师为你的坚持点赞！👍',
            '看到你的打卡，老师很欣慰！',
            '你的努力老师都看在眼里，继续保持！',
            '每天的坚持都很棒，为你骄傲！'
        ]
    
    def add_reply(self, checkin_id: int, reply: str, teacher_id: int = None) -> Dict[str, Any]:
        """
        为打卡记录添加回复
        
        Args:
            checkin_id: 打卡记录ID
            reply: 回复内容
            teacher_id: 教师ID
            
        Returns:
            Dict: 更新后的打卡记录
        """
        try:
            # 检查打卡记录是否存在
            check_query = "SELECT id FROM checkins WHERE id = ? AND status != 'deleted'"
            check_result = self.db.execute_query(check_query, (checkin_id,))
            
            if not check_result:
                raise NotFoundException(f"打卡记录ID {checkin_id} 不存在或已删除")
            
            # 更新回复
            update_query = """
                UPDATE checkins 
                SET reply = ?, reply_time = ?, teacher_id = ?, updated_at = ?
                WHERE id = ?
            """
            
            affected_rows = self.db.execute_update(update_query, (
                reply,
                datetime.now(),
                teacher_id,
                datetime.now(),
                checkin_id
            ))
            
            if affected_rows == 0:
                raise ServiceException(f"更新打卡记录回复失败")
            
            # 获取更新后的记录
            updated_query = """
                SELECT c.*, s.name as student_name, s.student_id as student_number
                FROM checkins c
                LEFT JOIN students s ON c.student_id = s.id
                WHERE c.id = ?
            """
            
            updated_result = self.db.execute_query(updated_query, (checkin_id,))
            
            service_logger.info(f"添加打卡回复成功: 打卡ID {checkin_id}")
            return updated_result[0] if updated_result else {}
            
        except (NotFoundException, ServiceException):
            raise
        except Exception as e:
            service_logger.error(f"添加打卡回复失败: {e}")
            raise ServiceException(f"添加打卡回复失败: {e}")
    
    def generate_auto_reply(self, checkin_id: int, teacher_id: int = None) -> Dict[str, Any]:
        """
        为打卡记录生成自动回复
        
        Args:
            checkin_id: 打卡记录ID
            teacher_id: 教师ID
            
        Returns:
            Dict: 包含自动回复的打卡记录
        """
        try:
            # 获取打卡记录信息
            checkin_query = """
                SELECT c.*, s.name as student_name
                FROM checkins c
                LEFT JOIN students s ON c.student_id = s.id
                WHERE c.id = ? AND c.status != 'deleted'
            """
            
            checkin_result = self.db.execute_query(checkin_query, (checkin_id,))
            
            if not checkin_result:
                raise NotFoundException(f"打卡记录ID {checkin_id} 不存在或已删除")
            
            checkin_data = checkin_result[0]
            
            # 根据心情生成回复
            mood = checkin_data.get('mood')
            if mood and mood in self.auto_reply_templates:
                reply_templates = self.auto_reply_templates[mood]
                auto_reply = random.choice(reply_templates)
            else:
                # 使用通用回复
                auto_reply = random.choice(self.general_replies)
            
            # 如果有学生姓名，个性化回复
            student_name = checkin_data.get('student_name')
            if student_name:
                auto_reply = f"{student_name}，{auto_reply}"
            
            # 添加回复
            return self.add_reply(checkin_id, auto_reply, teacher_id)
            
        except (NotFoundException, ServiceException):
            raise
        except Exception as e:
            service_logger.error(f"生成自动回复失败: {e}")
            raise ServiceException(f"生成自动回复失败: {e}")
    
    def batch_generate_auto_replies(self, checkin_ids: List[int], teacher_id: int = None) -> Dict[str, Any]:
        """
        批量生成自动回复
        
        Args:
            checkin_ids: 打卡记录ID列表
            teacher_id: 教师ID
            
        Returns:
            Dict: 批量操作结果
        """
        try:
            success_count = 0
            failed_count = 0
            failed_items = []
            
            for checkin_id in checkin_ids:
                try:
                    self.generate_auto_reply(checkin_id, teacher_id)
                    success_count += 1
                except Exception as e:
                    failed_count += 1
                    failed_items.append({
                        'checkin_id': checkin_id,
                        'error': str(e)
                    })
                    service_logger.warning(f"为打卡记录 {checkin_id} 生成自动回复失败: {e}")
            
            result = {
                'success_count': success_count,
                'failed_count': failed_count,
                'total_count': len(checkin_ids),
                'failed_items': failed_items
            }
            
            service_logger.info(f"批量生成自动回复完成: 成功 {success_count}, 失败 {failed_count}")
            return result
            
        except Exception as e:
            service_logger.error(f"批量生成自动回复失败: {e}")
            raise ServiceException(f"批量生成自动回复失败: {e}")
    
    def get_unreplied_checkins(self, days: int = 7, student_id: int = None) -> List[Dict[str, Any]]:
        """
        获取未回复的打卡记录
        
        Args:
            days: 查询最近几天的记录
            student_id: 可选的学生ID过滤
            
        Returns:
            List: 未回复的打卡记录列表
        """
        try:
            from datetime import date, timedelta
            
            start_date = date.today() - timedelta(days=days)
            
            where_conditions = [
                "c.status != 'deleted'",
                "c.checkin_date >= ?",
                "(c.reply IS NULL OR c.reply = '')"
            ]
            where_params = [start_date]
            
            if student_id:
                where_conditions.append("c.student_id = ?")
                where_params.append(student_id)
            
            where_clause = " AND ".join(where_conditions)
            
            query = f"""
                SELECT c.*, s.name as student_name, s.student_id as student_number
                FROM checkins c
                LEFT JOIN students s ON c.student_id = s.id
                WHERE {where_clause}
                ORDER BY c.checkin_date DESC, c.checkin_time DESC
            """
            
            unreplied_checkins = self.db.execute_query(query, where_params)
            
            service_logger.info(f"获取未回复打卡记录成功: 最近 {days} 天，共 {len(unreplied_checkins)} 条")
            return unreplied_checkins
            
        except Exception as e:
            service_logger.error(f"获取未回复打卡记录失败: {e}")
            raise ServiceException(f"获取未回复打卡记录失败: {e}")
    
    def update_reply_templates(self, mood: str, templates: List[str]) -> bool:
        """
        更新指定心情的回复模板
        
        Args:
            mood: 心情类型
            templates: 新的回复模板列表
            
        Returns:
            bool: 更新是否成功
        """
        try:
            if not templates:
                raise ServiceException("回复模板不能为空")
            
            self.auto_reply_templates[mood] = templates
            
            service_logger.info(f"更新回复模板成功: {mood}，共 {len(templates)} 个模板")
            return True
            
        except Exception as e:
            service_logger.error(f"更新回复模板失败: {e}")
            raise ServiceException(f"更新回复模板失败: {e}")
    
    def get_reply_templates(self) -> Dict[str, List[str]]:
        """
        获取所有回复模板
        
        Returns:
            Dict: 按心情分类的回复模板
        """
        try:
            service_logger.info("获取回复模板成功")
            return {
                'auto_reply_templates': self.auto_reply_templates,
                'general_replies': self.general_replies
            }
            
        except Exception as e:
            service_logger.error(f"获取回复模板失败: {e}")
            raise ServiceException(f"获取回复模板失败: {e}")
    
    def delete_reply(self, checkin_id: int) -> Dict[str, Any]:
        """
        删除打卡记录的回复
        
        Args:
            checkin_id: 打卡记录ID
            
        Returns:
            Dict: 更新后的打卡记录
        """
        try:
            # 检查打卡记录是否存在
            check_query = "SELECT id FROM checkins WHERE id = ? AND status != 'deleted'"
            check_result = self.db.execute_query(check_query, (checkin_id,))
            
            if not check_result:
                raise NotFoundException(f"打卡记录ID {checkin_id} 不存在或已删除")
            
            # 清除回复
            update_query = """
                UPDATE checkins 
                SET reply = NULL, reply_time = NULL, teacher_id = NULL, updated_at = ?
                WHERE id = ?
            """
            
            affected_rows = self.db.execute_update(update_query, (
                datetime.now(),
                checkin_id
            ))
            
            if affected_rows == 0:
                raise ServiceException(f"删除打卡记录回复失败")
            
            # 获取更新后的记录
            updated_query = """
                SELECT c.*, s.name as student_name, s.student_id as student_number
                FROM checkins c
                LEFT JOIN students s ON c.student_id = s.id
                WHERE c.id = ?
            """
            
            updated_result = self.db.execute_query(updated_query, (checkin_id,))
            
            service_logger.info(f"删除打卡回复成功: 打卡ID {checkin_id}")
            return updated_result[0] if updated_result else {}
            
        except (NotFoundException, ServiceException):
            raise
        except Exception as e:
            service_logger.error(f"删除打卡回复失败: {e}")
            raise ServiceException(f"删除打卡回复失败: {e}")