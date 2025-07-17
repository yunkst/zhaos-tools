"""
自动回复服务层 - 处理自动回复相关的业务逻辑
"""

import random
from typing import Dict, Any

from app.core.config import settings
from app.core.logger import service_logger
from app.utils.exceptions import ServiceException
from app.ai import smart_reply_generator, ai_config


class ReplyService:
    """自动回复服务类"""
    
    def __init__(self):
        self.reply_templates = settings.AUTO_REPLY_TEMPLATES
    
    def generate_reply(self, content: str) -> str:
        """生成自动回复"""
        try:
            # TODO: 未来可以集成 Langflow 来生成更智能的回复
            # 目前使用简单的模板随机选择
            
            # 基于内容长度和关键词选择不同类型的回复
            reply = self._select_reply_by_content(content)
            
            service_logger.info(f"生成自动回复成功: {reply[:20]}...")
            
            return reply
            
        except Exception as e:
            service_logger.error(f"生成自动回复失败: {e}")
            raise ServiceException(f"生成自动回复失败: {e}")
    
    def _select_reply_by_content(self, content: str) -> str:
        """根据内容选择合适的回复"""
        content_lower = content.lower()
        
        # 检查内容中的关键词，选择更合适的回复
        if any(keyword in content_lower for keyword in ['学习', '笔记', '总结', '复习']):
            learning_replies = [
                "很棒的学习记录，继续努力！📚",
                "学习笔记整理得很好，继续保持！📝",
                "能看到你的思考过程，很棒！🧠",
                "学习态度很认真，为你点赞！⭐",
                "持续学习的精神值得表扬！🌟"
            ]
            return random.choice(learning_replies)
        
        elif any(keyword in content_lower for keyword in ['练习', '作业', '完成', '提交']):
            work_replies = [
                "作业完成得很好，加油！💪",
                "看到你的努力，很开心！😊",
                "继续保持这种认真的态度！👍",
                "每次的练习都是进步！🚀",
                "坚持就是胜利，加油！💪"
            ]
            return random.choice(work_replies)
        
        elif any(keyword in content_lower for keyword in ['问题', '困难', '不懂', '求助']):
            help_replies = [
                "遇到问题很正常，继续思考！🤔",
                "不懂就问，这是好习惯！👍",
                "困难是成长的阶梯，加油！💪",
                "问题解决了会很有成就感的！🌟",
                "学习路上有困难很正常，坚持！🚀"
            ]
            return random.choice(help_replies)
        
        elif any(keyword in content_lower for keyword in ['分享', '心得', '体会', '感想']):
            sharing_replies = [
                "很棒的分享！继续保持这种学习态度！👍",
                "感谢分享你的心得体会！🌟",
                "你的分享对其他同学也很有帮助！👏",
                "能够总结和分享说明你在认真思考！🧠",
                "这样的分享很有价值！⭐"
            ]
            return random.choice(sharing_replies)
        
        else:
            # 默认回复
            return random.choice(self.reply_templates)
    
    def add_custom_template(self, template: str) -> bool:
        """添加自定义回复模板"""
        try:
            if template.strip() and template not in self.reply_templates:
                self.reply_templates.append(template.strip())
                service_logger.info(f"添加自定义回复模板: {template[:20]}...")
                return True
            return False
        except Exception as e:
            service_logger.error(f"添加自定义回复模板失败: {e}")
            raise ServiceException(f"添加自定义回复模板失败: {e}")
    
    def remove_custom_template(self, template: str) -> bool:
        """移除自定义回复模板"""
        try:
            if template in self.reply_templates:
                self.reply_templates.remove(template)
                service_logger.info(f"移除自定义回复模板: {template[:20]}...")
                return True
            return False
        except Exception as e:
            service_logger.error(f"移除自定义回复模板失败: {e}")
            raise ServiceException(f"移除自定义回复模板失败: {e}")
    
    def get_all_templates(self) -> list[str]:
        """获取所有回复模板"""
        return self.reply_templates.copy()
    
    def analyze_content_sentiment(self, content: str) -> Dict[str, Any]:
        """分析内容情感（简单版本）"""
        try:
            # 简单的情感分析
            positive_keywords = ['好', '棒', '开心', '高兴', '成功', '完成', '理解', '明白']
            negative_keywords = ['难', '困难', '不懂', '失败', '错误', '问题', '困惑']
            
            content_lower = content.lower()
            
            positive_count = sum(1 for keyword in positive_keywords if keyword in content_lower)
            negative_count = sum(1 for keyword in negative_keywords if keyword in content_lower)
            
            if positive_count > negative_count:
                sentiment = "positive"
            elif negative_count > positive_count:
                sentiment = "negative"
            else:
                sentiment = "neutral"
            
            return {
                'sentiment': sentiment,
                'positive_score': positive_count,
                'negative_score': negative_count,
                'length': len(content)
            }
            
        except Exception as e:
            service_logger.error(f"分析内容情感失败: {e}")
            return {
                'sentiment': 'neutral',
                'positive_score': 0,
                'negative_score': 0,
                'length': len(content)
            }
    
    async def generate_smart_reply(self, student_name: str, checkin_content: str) -> str:
        """生成智能回复"""
        if not ai_config.enabled:
            # 回退到模板回复
            return self.get_random_template()
        
        try:
            result = await smart_reply_generator.run({
                "student_name": student_name,
                "checkin_content": checkin_content
            })
            
            if result["success"]:
                return result["data"]["reply"]
            else:
                logger.warning(f"AI回复生成失败: {result['error']}")
                return self.get_random_template()
                
        except Exception as e:
            logger.error(f"AI回复生成异常: {e}")
            return self.get_random_template()


# 创建全局回复服务实例
reply_service = ReplyService()