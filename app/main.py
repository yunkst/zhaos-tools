"""
FastAPI应用主入口文件
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
from pathlib import Path

from app.core.config import settings
from app.core.logger import app_logger
from app.ai import initialize_ai_module  # 新增
from app.api.v1.students import router as students_router
from app.api.v1.classes import router as classes_router
from app.api.v1.checkin import router as checkin_router
from app.api.v1.system import router as system_router
from app.api.v1.config import router as config_router
from app.api.v1.ai_keys import router as ai_keys_router


def create_app() -> FastAPI:
    """创建FastAPI应用实例"""
    
    app = FastAPI(
        title=settings.APP_NAME,
        description=settings.APP_DESCRIPTION,
        version=settings.APP_VERSION,
        docs_url="/api/docs",
        redoc_url="/api/redoc",
        openapi_url="/api/openapi.json"
    )
    
    # 配置CORS
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.CORS_ORIGINS,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
    
    # 注册API路由
    app.include_router(classes_router, prefix="/api/v1", tags=["classes"])
    app.include_router(students_router, prefix="/api/v1", tags=["students"])
    app.include_router(checkin_router, prefix="/api/v1", tags=["checkin"])
    app.include_router(system_router, prefix="/api/v1", tags=["system"])
    app.include_router(config_router, prefix="/api/v1", tags=["config"])
    app.include_router(ai_keys_router, prefix="/api/v1", tags=["ai-keys"])  # 新增
    
    # 配置静态文件服务
    frontend_path = settings.frontend_path
    if frontend_path and frontend_path.exists():
        app.mount("/static", StaticFiles(directory=str(frontend_path)), name="static")
        
        @app.get("/")
        async def read_index():
            """提供前端入口页面"""
            index_file = frontend_path / "index.html"
            if index_file.exists():
                return FileResponse(str(index_file))
            return {"message": "前端文件未找到"}
    
    # 应用启动事件
    @app.on_event("startup")
    async def startup_event():
        """应用启动时的初始化"""
        app_logger.info(f"🚀 {settings.APP_NAME} 启动成功")
        app_logger.info(f"📖 API文档: http://{settings.HOST}:{settings.PORT}/api/docs")
        app_logger.info(f"🗄️ 数据库: {settings.database_path}")
        
        # 初始化AI模块
        initialize_ai_module()
        
        # 如果没有前端文件，提供提示
        if not frontend_path or not frontend_path.exists():
            app_logger.warning("⚠️  前端文件未找到，请构建前端项目")
    
    # 应用关闭事件
    @app.on_event("shutdown")
    async def shutdown_event():
        """应用关闭时的清理"""
        app_logger.info(f"👋 {settings.APP_NAME} 正在关闭...")
    
    return app


# 创建应用实例
app = create_app()