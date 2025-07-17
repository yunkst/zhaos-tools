"""
LangChain基础框架
"""

from typing import Any, Dict, List, Optional, Union
import logging

try:
    from langchain_openai import ChatOpenAI
    from langchain.schema import BaseMessage, HumanMessage, SystemMessage, AIMessage
    from langchain.callbacks.base import BaseCallbackHandler
    LANGCHAIN_AVAILABLE = True
except ImportError:
    LANGCHAIN_AVAILABLE = False
    BaseCallbackHandler = object

from .base import BaseAIFunction
from .config import ai_config
from .langfuse_client import langfuse_client

logger = logging.getLogger(__name__)


class LangfuseCallbackHandler(BaseCallbackHandler):
    """Langfuse回调处理器"""
    
    def __init__(self, trace_name: str = "langchain_execution"):
        self.trace_name = trace_name
        self.trace = None
        
        if langfuse_client.enabled:
            self.trace = langfuse_client.trace(name=trace_name)
    
    def on_llm_start(self, serialized: Dict[str, Any], prompts: List[str], **kwargs) -> None:
        """LLM开始时的回调"""
        if self.trace:
            self.trace.update(input=prompts)
    
    def on_llm_end(self, response, **kwargs) -> None:
        """LLM结束时的回调"""
        if self.trace:
            self.trace.update(output=response.dict() if hasattr(response, 'dict') else str(response))


class LangChainAIFunction(BaseAIFunction):
    """基于LangChain的AI功能基类"""
    
    def __init__(self, name: str, description: str = "", model: str = "gpt-3.5-turbo"):
        super().__init__(name, description)
        self.model = model
        self._llm: Optional[ChatOpenAI] = None
        self._initialize_llm()
    
    def _initialize_llm(self):
        """初始化LLM"""
        if not LANGCHAIN_AVAILABLE:
            logger.warning("LangChain未安装，无法初始化LLM")
            return
        
        if not ai_config.openai_api_key:
            logger.warning("OpenAI API Key未配置，无法初始化LLM")
            return
        
        try:
            self._llm = ChatOpenAI(
                model=self.model,
                openai_api_key=ai_config.openai_api_key,
                openai_api_base=ai_config.openai_base_url,
                temperature=0.7
            )
            logger.info(f"✅ LLM初始化成功: {self.model}")
        except Exception as e:
            logger.error(f"❌ LLM初始化失败: {e}")
    
    @property
    def llm(self) -> Optional[ChatOpenAI]:
        """获取LLM实例"""
        return self._llm
    
    def create_callback_handler(self) -> Optional[LangfuseCallbackHandler]:
        """创建回调处理器"""
        if langfuse_client.enabled:
            return LangfuseCallbackHandler(trace_name=f"{self.name}_execution")
        return None
    
    async def invoke_llm(
        self, 
        messages: List[BaseMessage], 
        **kwargs
    ) -> Optional[str]:
        """调用LLM
        
        Args:
            messages: 消息列表
            **kwargs: 额外参数
            
        Returns:
            LLM响应
        """
        if not self._llm:
            raise RuntimeError("LLM未初始化")
        
        callback_handler = self.create_callback_handler()
        callbacks = [callback_handler] if callback_handler else []
        
        try:
            response = await self._llm.ainvoke(messages, callbacks=callbacks, **kwargs)
            return response.content if hasattr(response, 'content') else str(response)
        except Exception as e:
            logger.error(f"LLM调用失败: {e}")
            raise
    
    def create_messages(
        self, 
        system_prompt: str = "", 
        user_input: str = "", 
        history: List[Dict[str, str]] = None
    ) -> List[BaseMessage]:
        """创建消息列表
        
        Args:
            system_prompt: 系统提示
            user_input: 用户输入
            history: 历史对话
            
        Returns:
            消息列表
        """
        messages = []
        
        if system_prompt:
            messages.append(SystemMessage(content=system_prompt))
        
        if history:
            for msg in history:
                if msg.get('role') == 'user':
                    messages.append(HumanMessage(content=msg['content']))
                elif msg.get('role') == 'assistant':
                    messages.append(AIMessage(content=msg['content']))
        
        if user_input:
            messages.append(HumanMessage(content=user_input))
        
        return messages