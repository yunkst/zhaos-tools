"""打卡统计服务 - 处理打卡数据的统计分析"""

from typing import Dict, Any, List, Optional
from datetime import datetime, date, timedelta
from collections import defaultdict

from app.core.database import db_manager
from app.core.logger import service_logger
from app.utils.exceptions import ServiceException


class CheckInStatsService:
    """打卡统计服务类"""
    
    def __init__(self):
        self.db = db_manager
    
    def get_checkin_stats(self, start_date: date = None, end_date: date = None, 
                         student_id: int = None, class_id: int = None) -> Dict[str, Any]:
        """
        获取打卡统计信息
        
        Args:
            start_date: 开始日期
            end_date: 结束日期
            student_id: 可选的学生ID过滤
            class_id: 可选的班级ID过滤
            
        Returns:
            Dict: 统计信息
        """
        try:
            # 如果没有指定日期范围，默认为最近30天
            if not start_date:
                start_date = date.today() - timedelta(days=30)
            if not end_date:
                end_date = date.today()
            
            # 构建WHERE条件
            where_conditions = [
                "c.status != 'deleted'",
                "c.checkin_date >= ?",
                "c.checkin_date <= ?"
            ]
            where_params = [start_date, end_date]
            
            if student_id:
                where_conditions.append("c.student_id = ?")
                where_params.append(student_id)
            
            if class_id:
                where_conditions.append("s.class_id = ?")
                where_params.append(class_id)
            
            where_clause = " AND ".join(where_conditions)
            
            # 基础统计
            basic_stats_query = f"""
                SELECT 
                    COUNT(*) as total_checkins,
                    COUNT(DISTINCT c.student_id) as active_students,
                    COUNT(DISTINCT c.checkin_date) as active_days,
                    AVG(CASE WHEN c.reply IS NOT NULL THEN 1 ELSE 0 END) as reply_rate
                FROM checkins c
                LEFT JOIN students s ON c.student_id = s.id
                WHERE {where_clause}
            """
            
            basic_stats = self.db.execute_query(basic_stats_query, where_params)
            
            # 心情统计
            mood_stats_query = f"""
                SELECT 
                    c.mood,
                    COUNT(*) as count
                FROM checkins c
                LEFT JOIN students s ON c.student_id = s.id
                WHERE {where_clause} AND c.mood IS NOT NULL
                GROUP BY c.mood
                ORDER BY count DESC
            """
            
            mood_stats = self.db.execute_query(mood_stats_query, where_params)
            
            # 每日打卡统计
            daily_stats_query = f"""
                SELECT 
                    c.checkin_date,
                    COUNT(*) as checkin_count,
                    COUNT(DISTINCT c.student_id) as student_count
                FROM checkins c
                LEFT JOIN students s ON c.student_id = s.id
                WHERE {where_clause}
                GROUP BY c.checkin_date
                ORDER BY c.checkin_date
            """
            
            daily_stats = self.db.execute_query(daily_stats_query, where_params)
            
            # 学生打卡排行
            student_ranking_query = f"""
                SELECT 
                    s.id,
                    s.name,
                    s.student_id as student_number,
                    COUNT(c.id) as checkin_count,
                    COUNT(CASE WHEN c.reply IS NOT NULL THEN 1 END) as replied_count
                FROM students s
                LEFT JOIN checkins c ON s.id = c.student_id 
                    AND c.status != 'deleted'
                    AND c.checkin_date >= ?
                    AND c.checkin_date <= ?
                WHERE s.id IS NOT NULL
            """
            
            ranking_params = [start_date, end_date]
            
            if student_id:
                student_ranking_query += " AND s.id = ?"
                ranking_params.append(student_id)
            
            if class_id:
                student_ranking_query += " AND s.class_id = ?"
                ranking_params.append(class_id)
            
            student_ranking_query += """
                GROUP BY s.id, s.name, s.student_id
                ORDER BY checkin_count DESC
                LIMIT 20
            """
            
            student_ranking = self.db.execute_query(student_ranking_query, ranking_params)
            
            result = {
                'period': {
                    'start_date': start_date.isoformat(),
                    'end_date': end_date.isoformat()
                },
                'basic_stats': basic_stats[0] if basic_stats else {},
                'mood_distribution': mood_stats,
                'daily_stats': daily_stats,
                'student_ranking': student_ranking
            }
            
            service_logger.info(f"获取打卡统计信息成功: {start_date} 到 {end_date}")
            return result
            
        except Exception as e:
            service_logger.error(f"获取打卡统计信息失败: {e}")
            raise ServiceException(f"获取打卡统计信息失败: {e}")
    
    def get_student_checkin_summary(self, student_id: int, days: int = 30) -> Dict[str, Any]:
        """
        获取学生打卡汇总信息
        
        Args:
            student_id: 学生ID
            days: 统计天数，默认30天
            
        Returns:
            Dict: 学生打卡汇总
        """
        try:
            end_date = date.today()
            start_date = end_date - timedelta(days=days)
            
            # 验证学生是否存在
            student_query = "SELECT id, name, student_id FROM students WHERE id = ?"
            student_result = self.db.execute_query(student_query, (student_id,))
            
            if not student_result:
                raise ServiceException(f"学生ID {student_id} 不存在")
            
            student_info = student_result[0]
            
            # 获取打卡统计
            stats_query = """
                SELECT 
                    COUNT(*) as total_checkins,
                    COUNT(CASE WHEN reply IS NOT NULL THEN 1 END) as replied_count,
                    COUNT(DISTINCT checkin_date) as active_days,
                    MIN(checkin_date) as first_checkin,
                    MAX(checkin_date) as last_checkin
                FROM checkins
                WHERE student_id = ? 
                    AND status != 'deleted'
                    AND checkin_date >= ?
                    AND checkin_date <= ?
            """
            
            stats_result = self.db.execute_query(stats_query, (student_id, start_date, end_date))
            stats = stats_result[0] if stats_result else {}
            
            # 获取心情分布
            mood_query = """
                SELECT mood, COUNT(*) as count
                FROM checkins
                WHERE student_id = ? 
                    AND status != 'deleted'
                    AND checkin_date >= ?
                    AND checkin_date <= ?
                    AND mood IS NOT NULL
                GROUP BY mood
                ORDER BY count DESC
            """
            
            mood_distribution = self.db.execute_query(mood_query, (student_id, start_date, end_date))
            
            # 获取最近的打卡记录
            recent_query = """
                SELECT checkin_date, checkin_time, content, mood, reply
                FROM checkins
                WHERE student_id = ? AND status != 'deleted'
                ORDER BY checkin_date DESC, checkin_time DESC
                LIMIT 10
            """
            
            recent_checkins = self.db.execute_query(recent_query, (student_id,))
            
            # 计算连续打卡天数
            consecutive_days = self._calculate_consecutive_days(student_id)
            
            result = {
                'student_info': student_info,
                'period': {
                    'start_date': start_date.isoformat(),
                    'end_date': end_date.isoformat(),
                    'days': days
                },
                'stats': {
                    **stats,
                    'consecutive_days': consecutive_days,
                    'checkin_rate': round(stats.get('active_days', 0) / days * 100, 2) if days > 0 else 0
                },
                'mood_distribution': mood_distribution,
                'recent_checkins': recent_checkins
            }
            
            service_logger.info(f"获取学生打卡汇总成功: 学生ID {student_id}")
            return result
            
        except Exception as e:
            service_logger.error(f"获取学生打卡汇总失败: {e}")
            raise ServiceException(f"获取学生打卡汇总失败: {e}")
    
    def get_class_checkin_stats(self, class_id: int, days: int = 30) -> Dict[str, Any]:
        """
        获取班级打卡统计
        
        Args:
            class_id: 班级ID
            days: 统计天数，默认30天
            
        Returns:
            Dict: 班级打卡统计
        """
        try:
            end_date = date.today()
            start_date = end_date - timedelta(days=days)
            
            # 验证班级是否存在
            class_query = "SELECT id, name FROM classes WHERE id = ?"
            class_result = self.db.execute_query(class_query, (class_id,))
            
            if not class_result:
                raise ServiceException(f"班级ID {class_id} 不存在")
            
            class_info = class_result[0]
            
            # 获取班级学生总数
            student_count_query = "SELECT COUNT(*) as total FROM students WHERE class_id = ?"
            student_count_result = self.db.execute_query(student_count_query, (class_id,))
            total_students = student_count_result[0]['total'] if student_count_result else 0
            
            # 获取班级打卡统计
            return self.get_checkin_stats(
                start_date=start_date,
                end_date=end_date,
                class_id=class_id
            )
            
        except Exception as e:
            service_logger.error(f"获取班级打卡统计失败: {e}")
            raise ServiceException(f"获取班级打卡统计失败: {e}")
    
    def _calculate_consecutive_days(self, student_id: int) -> int:
        """
        计算学生连续打卡天数
        
        Args:
            student_id: 学生ID
            
        Returns:
            int: 连续打卡天数
        """
        try:
            # 获取最近的打卡日期（按日期倒序）
            query = """
                SELECT DISTINCT checkin_date
                FROM checkins
                WHERE student_id = ? AND status != 'deleted'
                ORDER BY checkin_date DESC
                LIMIT 100
            """
            
            dates_result = self.db.execute_query(query, (student_id,))
            
            if not dates_result:
                return 0
            
            # 转换为日期对象列表
            dates = []
            for row in dates_result:
                if isinstance(row['checkin_date'], str):
                    dates.append(datetime.strptime(row['checkin_date'], '%Y-%m-%d').date())
                else:
                    dates.append(row['checkin_date'])
            
            # 计算连续天数
            consecutive_days = 0
            today = date.today()
            
            for i, check_date in enumerate(dates):
                expected_date = today - timedelta(days=i)
                if check_date == expected_date:
                    consecutive_days += 1
                else:
                    break
            
            return consecutive_days
            
        except Exception as e:
            service_logger.warning(f"计算连续打卡天数失败: {e}")
            return 0
    
    def get_mood_trends(self, student_id: int = None, days: int = 30) -> Dict[str, Any]:
        """
        获取心情趋势分析
        
        Args:
            student_id: 可选的学生ID
            days: 分析天数
            
        Returns:
            Dict: 心情趋势数据
        """
        try:
            end_date = date.today()
            start_date = end_date - timedelta(days=days)
            
            where_conditions = [
                "status != 'deleted'",
                "checkin_date >= ?",
                "checkin_date <= ?",
                "mood IS NOT NULL"
            ]
            where_params = [start_date, end_date]
            
            if student_id:
                where_conditions.append("student_id = ?")
                where_params.append(student_id)
            
            where_clause = " AND ".join(where_conditions)
            
            # 按日期和心情统计
            query = f"""
                SELECT 
                    checkin_date,
                    mood,
                    COUNT(*) as count
                FROM checkins
                WHERE {where_clause}
                GROUP BY checkin_date, mood
                ORDER BY checkin_date, mood
            """
            
            mood_data = self.db.execute_query(query, where_params)
            
            # 整理数据格式
            trends = defaultdict(lambda: defaultdict(int))
            mood_totals = defaultdict(int)
            
            for row in mood_data:
                date_str = row['checkin_date'].isoformat() if hasattr(row['checkin_date'], 'isoformat') else str(row['checkin_date'])
                trends[date_str][row['mood']] = row['count']
                mood_totals[row['mood']] += row['count']
            
            result = {
                'period': {
                    'start_date': start_date.isoformat(),
                    'end_date': end_date.isoformat(),
                    'days': days
                },
                'daily_trends': dict(trends),
                'mood_totals': dict(mood_totals),
                'raw_data': mood_data
            }
            
            service_logger.info(f"获取心情趋势分析成功: {days} 天")
            return result
            
        except Exception as e:
            service_logger.error(f"获取心情趋势分析失败: {e}")
            raise ServiceException(f"获取心情趋势分析失败: {e}")