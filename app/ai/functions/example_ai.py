"""
示例AI功能 - 智能回复生成
"""

from typing import Any, Dict
from ..langchain_base import LangChainAIFunction


class SmartReplyGenerator(LangChainAIFunction):
    """智能回复生成器"""
    
    def __init__(self):
        super().__init__(
            name="smart_reply_generator",
            description="根据学生打卡内容生成个性化回复"
        )
    
    async def execute(self, input_data: Dict[str, Any]) -> Dict[str, Any]:
        """执行智能回复生成
        
        Args:
            input_data: {
                "student_name": "学生姓名",
                "checkin_content": "打卡内容",
                "student_info": "学生信息（可选）"
            }
            
        Returns:
            生成的回复内容
        """
        student_name = input_data.get("student_name", "同学")
        checkin_content = input_data.get("checkin_content", "")
        student_info = input_data.get("student_info", "")
        
        if not checkin_content:
            raise ValueError("打卡内容不能为空")
        
        # 构建系统提示
        system_prompt = f"""
你是一位温暖、鼓励的老师，需要对学生的打卡内容给出个性化的回复。

回复要求：
1. 语气温暖、鼓励，体现老师的关怀
2. 针对具体的打卡内容给出有针对性的反馈
3. 长度控制在50字以内
4. 可以适当使用emoji表情
5. 体现正面引导和鼓励

学生信息：{student_info if student_info else '暂无特殊信息'}
"""
        
        user_input = f"""
学生姓名：{student_name}
打卡内容：{checkin_content}

请为这位学生生成一个温暖鼓励的回复。
"""
        
        # 创建消息
        messages = self.create_messages(
            system_prompt=system_prompt,
            user_input=user_input
        )
        
        # 调用LLM
        reply = await self.invoke_llm(messages)
        
        return {
            "reply": reply,
            "student_name": student_name,
            "original_content": checkin_content
        }


# 创建全局实例
smart_reply_generator = SmartReplyGenerator()