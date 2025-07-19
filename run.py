#!/usr/bin/env python3
"""
启动脚本 - FastAPI应用启动器
"""

import subprocess
import sys
import os
import webbrowser
from pathlib import Path
import argparse
import time
import signal


def check_frontend_build():
    """检查前端是否已构建"""
    frontend_dist = Path("fronted/dist")
    return frontend_dist.exists() and any(frontend_dist.iterdir())


def build_frontend():
    """构建前端项目"""
    print("🔨 正在构建前端项目...")
    
    frontend_dir = Path("fronted")
    if not frontend_dir.exists():
        print("❌ 前端目录不存在")
        return False
    
    try:
        # 安装依赖
        print("📦 安装前端依赖...")
        subprocess.run(["yarn", "install"], cwd=frontend_dir, check=True)
        
        # 构建项目
        print("🏗️ 构建前端项目...")
        subprocess.run(["yarn", "build"], cwd=frontend_dir, check=True)
        
        print("✅ 前端构建完成")
        return True
        
    except subprocess.CalledProcessError as e:
        print(f"❌ 前端构建失败: {e}")
        return False
    except FileNotFoundError:
        print("❌ 未找到 yarn 命令，请确保已安装 Node.js 和 yarn")
        return False


def start_frontend_dev():
    """启动前端开发服务器"""
    print("🚀 启动前端开发服务器...")
    
    frontend_dir = Path("fronted")
    if not frontend_dir.exists():
        print("❌ 前端目录不存在")
        return None
    
    try:
        # 启动开发服务器
        process = subprocess.Popen(
            ["yarn", "dev"],
            cwd=frontend_dir,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE
        )
        
        print("✅ 前端开发服务器已启动")
        return process
        
    except FileNotFoundError:
        print("❌ 未找到 yarn 命令，请确保已安装 Node.js 和 yarn")
        return None


def start_fastapi_server(host="0.0.0.0", port=8000, reload=True):
    """启动FastAPI服务器"""
    print("🚀 启动FastAPI服务器...")
    
    try:
        # 设置环境变量
        env = os.environ.copy()
        if reload:
            env["ENVIRONMENT"] = "development"
        
        # 启动FastAPI服务器（使用uv run）
        cmd = [
            "uv", "run", "uvicorn",
            "app.main:app",
            "--host", host,
            "--port", str(port),
            "--log-level", "info"
        ]
        
        if reload:
            cmd.append("--reload")
        
        process = subprocess.Popen(cmd, env=env)
        
        print(f"✅ FastAPI服务器已启动")
        print(f"🌐 应用地址: http://{host}:{port}")
        print(f"📖 API文档: http://{host}:{port}/api/docs")
        
        return process
        
    except Exception as e:
        print(f"❌ FastAPI服务器启动失败: {e}")
        return None


def open_browser(url, delay=3):
    """延迟打开浏览器"""
    def open_url():
        time.sleep(delay)
        try:
            webbrowser.open(url)
            print(f"🌐 已打开浏览器: {url}")
        except Exception as e:
            print(f"⚠️  无法自动打开浏览器: {e}")
    
    import threading
    thread = threading.Thread(target=open_url)
    thread.daemon = True
    thread.start()


def main():
    parser = argparse.ArgumentParser(description="赵老师的工具箱 - FastAPI启动器")
    parser.add_argument(
        "--mode", 
        choices=["dev", "prod"], 
        default="dev",
        help="运行模式: dev(开发模式) 或 prod(生产模式)"
    )
    parser.add_argument(
        "--host",
        default="0.0.0.0",
        help="服务器主机地址"
    )
    parser.add_argument(
        "--port",
        type=int,
        default=8000,
        help="服务器端口"
    )
    parser.add_argument(
        "--build", 
        action="store_true",
        help="强制重新构建前端"
    )
    parser.add_argument(
        "--no-frontend", 
        action="store_true",
        help="不启动前端开发服务器"
    )
    parser.add_argument(
        "--browser", 
        action="store_true",
        help="自动打开浏览器"
    )
    
    args = parser.parse_args()
    
    print("🎯 赵老师的工具箱 - FastAPI启动器")
    print(f"📋 运行模式: {args.mode}")
    print(f"🌐 服务地址: http://{args.host}:{args.port}")
    print("-" * 50)
    
    # 检查 Python 环境
    if not Path(".venv").exists():
        print("⚠️  虚拟环境不存在，请运行: uv sync")
        return
    
    frontend_process = None
    fastapi_process = None
    
    try:
        # 处理前端
        if not args.no_frontend:
            if args.mode == "dev":
                # 开发模式：启动前端开发服务器
                frontend_process = start_frontend_dev()
                if frontend_process is None:
                    print("⚠️  前端开发服务器启动失败，继续启动后端")
                else:
                    print("⏳ 等待前端服务器启动...")
                    time.sleep(3)
                
            else:
                # 生产模式：检查并构建前端
                if args.build or not check_frontend_build():
                    if not build_frontend():
                        print("⚠️  前端构建失败，仅启动后端API")
                else:
                    print("✅ 前端已构建，跳过构建步骤")
        
        # 启动FastAPI服务器
        reload = args.mode == "dev"
        fastapi_process = start_fastapi_server(args.host, args.port, reload)
        
        if fastapi_process is None:
            print("❌ FastAPI服务器启动失败")
            return
        
        # 自动打开浏览器
        if args.browser:
            if args.mode == "dev" and frontend_process:
                # 开发模式打开前端开发服务器
                open_browser("http://localhost:5173")
            else:
                # 生产模式或仅后端模式打开FastAPI
                open_browser(f"http://{args.host}:{args.port}")
        
        print("\n🎉 应用启动成功！")
        print("按 Ctrl+C 停止应用")
        
        # 等待进程结束
        try:
            fastapi_process.wait()
        except KeyboardInterrupt:
            print("\n👋 正在停止应用...")
        
    except KeyboardInterrupt:
        print("\n👋 正在停止应用...")
        
    finally:
        # 清理进程
        if frontend_process:
            print("🛑 停止前端开发服务器...")
            frontend_process.terminate()
            try:
                frontend_process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                frontend_process.kill()
        
        if fastapi_process:
            print("🛑 停止FastAPI服务器...")
            fastapi_process.terminate()
            try:
                fastapi_process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                fastapi_process.kill()
        
        print("✅ 应用已停止")


if __name__ == "__main__":
    main()