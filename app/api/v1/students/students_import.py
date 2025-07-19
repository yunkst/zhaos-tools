"""
学生导入导出API - 处理学生的Excel导入导出功能
"""

from typing import Dict, Any, List
from fastapi import APIRouter, HTTPException, UploadFile, File, Query, status
from fastapi.responses import StreamingResponse
from pydantic import BaseModel
import io

from app.services.student import student_import_service
from app.utils.exceptions import ServiceException
from app.core.logger import api_logger

router = APIRouter()


class BatchImportRequest(BaseModel):
    """批量导入请求模型"""
    students_data: List[Dict[str, Any]]
    skip_duplicates: bool = True


@router.get("/import/template")
async def get_import_template() -> Dict[str, Any]:
    """
    获取导入模板的字段定义
    
    Returns:
        Dict: 包含模板字段定义和示例数据
    """
    try:
        api_logger.info("获取导入模板请求")
        
        template = student_import_service.get_import_template()
        
        api_logger.info("获取导入模板成功")
        return {
            "code": 200,
            "message": "获取导入模板成功",
            "data": template
        }
        
    except ServiceException as e:
        api_logger.error(f"获取导入模板失败 - 服务异常: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )
    except Exception as e:
        api_logger.error(f"获取导入模板失败 - 未知错误: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="获取导入模板失败"
        )


@router.get("/import/template/download")
async def download_import_template() -> StreamingResponse:
    """
    下载Excel导入模板文件
    
    Returns:
        StreamingResponse: Excel文件流
    """
    try:
        api_logger.info("下载导入模板请求")
        
        excel_data = student_import_service.generate_excel_template()
        
        # 创建文件流
        excel_stream = io.BytesIO(excel_data)
        excel_stream.seek(0)
        
        api_logger.info("下载导入模板成功")
        return StreamingResponse(
            io.BytesIO(excel_data),
            media_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            headers={"Content-Disposition": "attachment; filename=student_import_template.xlsx"}
        )
        
    except ServiceException as e:
        api_logger.error(f"下载导入模板失败 - 服务异常: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )
    except Exception as e:
        api_logger.error(f"下载导入模板失败 - 未知错误: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="下载导入模板失败"
        )


@router.post("/import/excel")
async def import_from_excel(
    file: UploadFile = File(..., description="Excel文件"),
    skip_duplicates: bool = Query(True, description="是否跳过重复的学号")
) -> Dict[str, Any]:
    """
    从Excel文件导入学生数据
    
    Args:
        file: 上传的Excel文件
        skip_duplicates: 是否跳过重复的学号，默认为True
    
    Returns:
        Dict: 导入结果统计
    """
    try:
        api_logger.info(f"Excel导入请求: 文件名 {file.filename}")
        
        # 验证文件类型
        if not file.filename:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="请选择文件"
            )
        
        if not file.filename.endswith(('.xlsx', '.xls')):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="只支持Excel文件格式（.xlsx, .xls）"
            )
        
        # 验证文件大小（限制为10MB）
        file_content = await file.read()
        if len(file_content) > 10 * 1024 * 1024:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="文件大小不能超过10MB"
            )
        
        if len(file_content) == 0:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="文件不能为空"
            )
        
        # 导入数据
        result = student_import_service.import_from_excel(file_content, skip_duplicates)
        
        api_logger.info(f"Excel导入完成: 成功 {result['success_count']}, 失败 {result['failed_count']}, 重复 {result['duplicate_count']}")
        return {
            "code": 200,
            "message": f"导入完成，成功 {result['success_count']} 条，失败 {result['failed_count']} 条，重复 {result['duplicate_count']} 条",
            "data": result
        }
        
    except HTTPException:
        raise
    except ServiceException as e:
        api_logger.error(f"Excel导入失败 - 服务异常: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )
    except Exception as e:
        api_logger.error(f"Excel导入失败 - 未知错误: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Excel导入失败"
        )


@router.post("/import/batch")
async def batch_import_students(request: BatchImportRequest) -> Dict[str, Any]:
    """
    批量导入学生数据（JSON格式）
    
    Args:
        request: 批量导入请求，包含学生数据列表
    
    Returns:
        Dict: 导入结果统计
    
    Request Body Example:
        {
            "students_data": [
                {
                    "name": "张三",
                    "student_id": "2024001",
                    "gender": "男",
                    "age": 16,
                    "class_name": "高一(1)班"
                },
                {
                    "name": "李四",
                    "student_id": "2024002",
                    "gender": "女",
                    "age": 15,
                    "class_name": "高一(2)班"
                }
            ],
            "skip_duplicates": true
        }
    """
    try:
        api_logger.info(f"批量导入学生请求: {len(request.students_data)} 条记录")
        
        if not request.students_data:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="学生数据不能为空"
            )
        
        if len(request.students_data) > 500:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="单次批量导入不能超过500条记录"
            )
        
        # 验证数据
        validation_result = student_import_service.validate_import_data(request.students_data)
        
        if not validation_result['valid_data']:
            return {
                "code": 400,
                "message": "没有有效的数据可以导入",
                "data": {
                    'success_count': 0,
                    'failed_count': validation_result['invalid_count'],
                    'duplicate_count': 0,
                    'total_count': validation_result['total_rows'],
                    'failed_items': validation_result['invalid_data']
                }
            }
        
        # 导入有效数据
        import_result = student_import_service.batch_import_students(
            validation_result['valid_data'], 
            request.skip_duplicates
        )
        
        # 合并结果
        result = {
            'success_count': import_result['success_count'],
            'failed_count': import_result['failed_count'] + validation_result['invalid_count'],
            'duplicate_count': import_result['duplicate_count'],
            'total_count': validation_result['total_rows'],
            'failed_items': import_result['failed_items'] + validation_result['invalid_data']
        }
        
        api_logger.info(f"批量导入学生完成: 成功 {result['success_count']}, 失败 {result['failed_count']}, 重复 {result['duplicate_count']}")
        return {
            "code": 200,
            "message": f"导入完成，成功 {result['success_count']} 条，失败 {result['failed_count']} 条，重复 {result['duplicate_count']} 条",
            "data": result
        }
        
    except HTTPException:
        raise
    except ServiceException as e:
        api_logger.error(f"批量导入学生失败 - 服务异常: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )
    except Exception as e:
        api_logger.error(f"批量导入学生失败 - 未知错误: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="批量导入学生失败"
        )


@router.post("/import/validate")
async def validate_import_data(students_data: List[Dict[str, Any]]) -> Dict[str, Any]:
    """
    验证导入数据（不实际导入）
    
    Args:
        students_data: 待验证的学生数据列表
    
    Returns:
        Dict: 验证结果，包含有效数据和错误信息
    
    Request Body Example:
        [
            {
                "姓名": "张三",
                "学号": "2024001",
                "性别": "男",
                "年龄": 16,
                "班级": "高一(1)班"
            }
        ]
    """
    try:
        api_logger.info(f"验证导入数据请求: {len(students_data)} 条记录")
        
        if not students_data:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="验证数据不能为空"
            )
        
        if len(students_data) > 1000:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="单次验证不能超过1000条记录"
            )
        
        result = student_import_service.validate_import_data(students_data)
        
        api_logger.info(f"验证导入数据完成: 有效 {result['valid_count']}, 无效 {result['invalid_count']}")
        return {
            "code": 200,
            "message": f"验证完成，有效 {result['valid_count']} 条，无效 {result['invalid_count']} 条",
            "data": result
        }
        
    except HTTPException:
        raise
    except ServiceException as e:
        api_logger.error(f"验证导入数据失败 - 服务异常: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )
    except Exception as e:
        api_logger.error(f"验证导入数据失败 - 未知错误: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="验证导入数据失败"
        )