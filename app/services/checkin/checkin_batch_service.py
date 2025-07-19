"""打卡批量操作服务 - 处理批量更新、删除等操作"""

from typing import Dict, Any, List
from datetime import datetime, date

from app.core.database import db_manager
from app.core.logger import service_logger
from app.utils.exceptions import (
    NotFoundException,
    StudentNotFoundException,
    ServiceException
)


class CheckInBatchService:
    """打卡批量操作服务类"""
    
    def __init__(self):
        self.db = db_manager
    
    def batch_update_checkins(self, updates: List[Dict[str, Any]]) -> Dict[str, Any]:
        """
        批量更新打卡记录
        
        Args:
            updates: 更新数据列表，每个元素包含id和要更新的字段
            
        Returns:
            Dict: 批量操作结果
        """
        try:
            success_count = 0
            failed_count = 0
            failed_items = []
            
            for update_item in updates:
                try:
                    checkin_id = update_item.get('id')
                    if not checkin_id:
                        failed_count += 1
                        failed_items.append({
                            'item': update_item,
                            'error': '缺少打卡记录ID'
                        })
                        continue
                    
                    # 检查打卡记录是否存在
                    check_query = "SELECT id FROM checkins WHERE id = ? AND status != 'deleted'"
                    check_result = self.db.execute_query(check_query, (checkin_id,))
                    
                    if not check_result:
                        failed_count += 1
                        failed_items.append({
                            'item': update_item,
                            'error': f'打卡记录ID {checkin_id} 不存在或已删除'
                        })
                        continue
                    
                    # 构建更新字段
                    update_fields = []
                    update_values = []
                    
                    allowed_fields = [
                        'content', 'mood', 'weather', 'location', 'photos',
                        'reply', 'reply_time', 'teacher_id', 'status'
                    ]
                    
                    for field in allowed_fields:
                        if field in update_item and field != 'id':
                            update_fields.append(f"{field} = ?")
                            update_values.append(update_item[field])
                    
                    if not update_fields:
                        failed_count += 1
                        failed_items.append({
                            'item': update_item,
                            'error': '没有有效的更新字段'
                        })
                        continue
                    
                    # 添加更新时间
                    update_fields.append("updated_at = ?")
                    update_values.append(datetime.now())
                    
                    # 添加WHERE条件的参数
                    update_values.append(checkin_id)
                    
                    # 执行更新
                    update_query = f"UPDATE checkins SET {', '.join(update_fields)} WHERE id = ?"
                    affected_rows = self.db.execute_update(update_query, tuple(update_values))
                    
                    if affected_rows > 0:
                        success_count += 1
                    else:
                        failed_count += 1
                        failed_items.append({
                            'item': update_item,
                            'error': f'更新打卡记录ID {checkin_id} 失败'
                        })
                        
                except Exception as e:
                    failed_count += 1
                    failed_items.append({
                        'item': update_item,
                        'error': str(e)
                    })
                    service_logger.warning(f"批量更新单个记录失败: {e}")
            
            result = {
                'success_count': success_count,
                'failed_count': failed_count,
                'total_count': len(updates),
                'failed_items': failed_items
            }
            
            service_logger.info(f"批量更新打卡记录完成: 成功 {success_count}, 失败 {failed_count}")
            return result
            
        except Exception as e:
            service_logger.error(f"批量更新打卡记录失败: {e}")
            raise ServiceException(f"批量更新打卡记录失败: {e}")
    
    def batch_delete_checkins(self, checkin_ids: List[int]) -> Dict[str, Any]:
        """
        批量删除打卡记录（软删除）
        
        Args:
            checkin_ids: 打卡记录ID列表
            
        Returns:
            Dict: 批量操作结果
        """
        try:
            success_count = 0
            failed_count = 0
            failed_items = []
            
            for checkin_id in checkin_ids:
                try:
                    # 检查打卡记录是否存在
                    check_query = "SELECT id FROM checkins WHERE id = ? AND status != 'deleted'"
                    check_result = self.db.execute_query(check_query, (checkin_id,))
                    
                    if not check_result:
                        failed_count += 1
                        failed_items.append({
                            'id': checkin_id,
                            'error': f'打卡记录ID {checkin_id} 不存在或已删除'
                        })
                        continue
                    
                    # 执行软删除
                    delete_query = "UPDATE checkins SET status = 'deleted', updated_at = ? WHERE id = ?"
                    affected_rows = self.db.execute_update(delete_query, (datetime.now(), checkin_id))
                    
                    if affected_rows > 0:
                        success_count += 1
                    else:
                        failed_count += 1
                        failed_items.append({
                            'id': checkin_id,
                            'error': f'删除打卡记录ID {checkin_id} 失败'
                        })
                        
                except Exception as e:
                    failed_count += 1
                    failed_items.append({
                        'id': checkin_id,
                        'error': str(e)
                    })
                    service_logger.warning(f"批量删除单个记录失败: {e}")
            
            result = {
                'success_count': success_count,
                'failed_count': failed_count,
                'total_count': len(checkin_ids),
                'failed_items': failed_items
            }
            
            service_logger.info(f"批量删除打卡记录完成: 成功 {success_count}, 失败 {failed_count}")
            return result
            
        except Exception as e:
            service_logger.error(f"批量删除打卡记录失败: {e}")
            raise ServiceException(f"批量删除打卡记录失败: {e}")
    
    def get_checkins_by_date_range(self, start_date: date, end_date: date, 
                                   student_id: int = None) -> List[Dict[str, Any]]:
        """
        根据日期范围获取打卡记录
        
        Args:
            start_date: 开始日期
            end_date: 结束日期
            student_id: 可选的学生ID过滤
            
        Returns:
            List: 打卡记录列表
        """
        try:
            where_conditions = [
                "c.status != 'deleted'",
                "c.checkin_date >= ?",
                "c.checkin_date <= ?"
            ]
            where_params = [start_date, end_date]
            
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
            
            checkins = self.db.execute_query(query, where_params)
            
            service_logger.info(f"根据日期范围获取打卡记录成功: {start_date} 到 {end_date}, 共 {len(checkins)} 条")
            return checkins
            
        except Exception as e:
            service_logger.error(f"根据日期范围获取打卡记录失败: {e}")
            raise ServiceException(f"根据日期范围获取打卡记录失败: {e}")
    
    def get_checkins_by_student_ids(self, student_ids: List[int], 
                                   date_from: date = None, date_to: date = None) -> List[Dict[str, Any]]:
        """
        根据学生ID列表获取打卡记录
        
        Args:
            student_ids: 学生ID列表
            date_from: 可选的开始日期
            date_to: 可选的结束日期
            
        Returns:
            List: 打卡记录列表
        """
        try:
            if not student_ids:
                return []
            
            # 构建IN条件的占位符
            placeholders = ','.join(['?' for _ in student_ids])
            
            where_conditions = [
                "c.status != 'deleted'",
                f"c.student_id IN ({placeholders})"
            ]
            where_params = student_ids.copy()
            
            if date_from:
                where_conditions.append("c.checkin_date >= ?")
                where_params.append(date_from)
            
            if date_to:
                where_conditions.append("c.checkin_date <= ?")
                where_params.append(date_to)
            
            where_clause = " AND ".join(where_conditions)
            
            query = f"""
                SELECT c.*, s.name as student_name, s.student_id as student_number
                FROM checkins c
                LEFT JOIN students s ON c.student_id = s.id
                WHERE {where_clause}
                ORDER BY c.student_id, c.checkin_date DESC, c.checkin_time DESC
            """
            
            checkins = self.db.execute_query(query, where_params)
            
            service_logger.info(f"根据学生ID列表获取打卡记录成功: {len(student_ids)} 个学生, 共 {len(checkins)} 条记录")
            return checkins
            
        except Exception as e:
            service_logger.error(f"根据学生ID列表获取打卡记录失败: {e}")
            raise ServiceException(f"根据学生ID列表获取打卡记录失败: {e}")
    
    def batch_update_replies(self, reply_updates: List[Dict[str, Any]]) -> Dict[str, Any]:
        """
        批量更新打卡回复
        
        Args:
            reply_updates: 回复更新列表，每个元素包含checkin_id, reply, teacher_id等
            
        Returns:
            Dict: 批量操作结果
        """
        try:
            success_count = 0
            failed_count = 0
            failed_items = []
            
            for reply_update in reply_updates:
                try:
                    checkin_id = reply_update.get('checkin_id')
                    reply = reply_update.get('reply')
                    teacher_id = reply_update.get('teacher_id')
                    
                    if not checkin_id or not reply:
                        failed_count += 1
                        failed_items.append({
                            'item': reply_update,
                            'error': '缺少必要的打卡记录ID或回复内容'
                        })
                        continue
                    
                    # 检查打卡记录是否存在
                    check_query = "SELECT id FROM checkins WHERE id = ? AND status != 'deleted'"
                    check_result = self.db.execute_query(check_query, (checkin_id,))
                    
                    if not check_result:
                        failed_count += 1
                        failed_items.append({
                            'item': reply_update,
                            'error': f'打卡记录ID {checkin_id} 不存在或已删除'
                        })
                        continue
                    
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
                    
                    if affected_rows > 0:
                        success_count += 1
                    else:
                        failed_count += 1
                        failed_items.append({
                            'item': reply_update,
                            'error': f'更新打卡记录ID {checkin_id} 的回复失败'
                        })
                        
                except Exception as e:
                    failed_count += 1
                    failed_items.append({
                        'item': reply_update,
                        'error': str(e)
                    })
                    service_logger.warning(f"批量更新回复单个记录失败: {e}")
            
            result = {
                'success_count': success_count,
                'failed_count': failed_count,
                'total_count': len(reply_updates),
                'failed_items': failed_items
            }
            
            service_logger.info(f"批量更新打卡回复完成: 成功 {success_count}, 失败 {failed_count}")
            return result
            
        except Exception as e:
            service_logger.error(f"批量更新打卡回复失败: {e}")
            raise ServiceException(f"批量更新打卡回复失败: {e}")