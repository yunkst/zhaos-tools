"""
学生API路由
"""

from fastapi import APIRouter, HTTPException, Query, Path, File, UploadFile
from fastapi.responses import StreamingResponse
from typing import Optional, List
import json
from io import BytesIO

from app.schemas.student import (
    StudentCreate, 
    StudentUpdate, 
    StudentResponse, 
    StudentListResponse,
    StudentBatchImport,
    ExcelImportResult,
    BatchUpdateRequest,
    BatchDeleteRequest,
    BatchOperationResult
)
from app.schemas.common import PaginationModel, ResponseModel, PaginatedResponse
from app.services.student_service import student_service
from app.services.excel_service import excel_service
from app.utils.exceptions import (
    StudentNotFoundException,
    DuplicateStudentException,
    ServiceException
)
from app.core.logger import api_logger


router = APIRouter()


@router.get("/students", response_model=PaginatedResponse)
async def get_students(
    page: int = Query(1, ge=1, description="页码"),
    page_size: int = Query(20, ge=1, le=100, description="每页数量"),
    search: Optional[str] = Query(None, description="搜索关键词"),
    class_name: Optional[str] = Query(None, description="班级名称")
):
    """获取学生列表"""
    try:
        if class_name:
            # 按班级查询
            students = student_service.get_students_by_class(class_name)
            # 手动分页处理
            total = len(students)
            start_index = (page - 1) * page_size
            end_index = start_index + page_size
            paginated_students = students[start_index:end_index]
            
            return PaginatedResponse(
                success=True,
                data=paginated_students,
                pagination=PaginationModel(
                    page=page,
                    page_size=page_size,
                    total=total,
                    total_pages=(total + page_size - 1) // page_size
                )
            )
        elif search:
            result = student_service.search_students(search, page, page_size)
        else:
            result = student_service.get_all_students(page, page_size)
        
        return PaginatedResponse(
            success=True,
            data=result['students'],
            pagination=PaginationModel(
                page=result['page'],
                page_size=result['page_size'],
                total=result['total'],
                total_pages=result['total_pages']
            )
        )
        
    except ServiceException as e:
        api_logger.error(f"获取学生列表失败: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/students/by-class/{class_id}", response_model=PaginatedResponse[List[StudentResponse]])
async def get_students_by_class_id(
    class_id: int,
    page: int = Query(1, ge=1, description="页码"),
    page_size: int = Query(20, ge=1, le=100, description="每页数量")
):
    """根据班级ID获取学生列表"""
    try:
        result = student_service.get_students_by_class_id(class_id, page, page_size)
        
        return PaginatedResponse(
            success=True,
            data=result['students'],
            pagination=PaginationModel(
                page=result['page'],
                page_size=result['page_size'],
                total=result['total'],
                total_pages=result['total_pages']
            )
        )
        
    except ServiceException as e:
        api_logger.error(f"获取班级学生列表失败: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/students/classes", response_model=ResponseModel)
async def get_class_list():
    """获取所有班级列表"""
    try:
        classes = student_service.get_class_list()
        return ResponseModel(success=True, data=classes)
        
    except ServiceException as e:
        api_logger.error(f"获取班级列表失败: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/students", response_model=ResponseModel)
async def create_student(student_data: StudentCreate):
    """创建新学生"""
    try:
        new_student = student_service.create_student(student_data)
        return ResponseModel(
            success=True,
            message="学生创建成功",
            data=new_student
        )
        
    except DuplicateStudentException as e:
        api_logger.warning(f"学生学号重复: {student_data.student_id}")
        raise HTTPException(status_code=400, detail=str(e))
    except ServiceException as e:
        api_logger.error(f"创建学生失败: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/students/batch", response_model=ResponseModel)
async def batch_import_students(batch_data: StudentBatchImport):
    """批量导入学生"""
    try:
        result = student_service.batch_import_students(batch_data)
        return ResponseModel(
            success=True,
            message=f"批量导入完成，成功: {result['success_count']}，失败: {result['failed_count']}",
            data=result
        )
        
    except ServiceException as e:
        api_logger.error(f"批量导入学生失败: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/students/import-file", response_model=ResponseModel)
async def import_students_from_file(file: UploadFile = File(...)):
    """从文件导入学生数据"""
    try:
        if not file.filename or not file.filename.endswith(('.json', '.csv')):
            raise HTTPException(status_code=400, detail="仅支持JSON和CSV文件格式")
        
        content = await file.read()
        
        if file.filename.endswith('.json'):
            # 处理JSON文件
            try:
                data = json.loads(content.decode('utf-8'))
                if not isinstance(data, list):
                    raise HTTPException(status_code=400, detail="JSON文件格式错误，应为学生数组")
                
                students = [StudentCreate(**student) for student in data]
                batch_data = StudentBatchImport(students=students)
                
            except json.JSONDecodeError:
                raise HTTPException(status_code=400, detail="JSON文件格式错误")
            except Exception as e:
                raise HTTPException(status_code=400, detail=f"数据格式错误: {str(e)}")
        
        elif file.filename.endswith('.csv'):
            # 处理CSV文件
            import csv
            import io
            
            try:
                content_str = content.decode('utf-8')
                csv_reader = csv.DictReader(io.StringIO(content_str))
                students = []
                
                for row in csv_reader:
                    # 清理空值
                    cleaned_row = {k: v.strip() if v and v.strip() else None for k, v in row.items()}
                    students.append(StudentCreate(**cleaned_row))
                
                batch_data = StudentBatchImport(students=students)
                
            except Exception as e:
                raise HTTPException(status_code=400, detail=f"CSV文件格式错误: {str(e)}")
        
        result = student_service.batch_import_students(batch_data)
        return ResponseModel(
            success=True,
            message=f"文件导入完成，成功: {result['success_count']}，失败: {result['failed_count']}",
            data=result
        )
        
    except HTTPException:
        raise
    except ServiceException as e:
        api_logger.error(f"文件导入失败: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    except Exception as e:
        api_logger.error(f"文件导入失败: {e}")
        raise HTTPException(status_code=500, detail=f"文件导入失败: {str(e)}")



@router.get("/students/by-student-id/{student_id}", response_model=ResponseModel)
async def get_student_by_student_id(
    student_id: str = Path(..., description="学生学号")
):
    """根据学号获取学生信息"""
    try:
        student = student_service.get_student_by_student_id(student_id)
        if student:
            return ResponseModel(success=True, data=student)
        else:
            raise HTTPException(status_code=404, detail="学生未找到")
            
    except ServiceException as e:
        api_logger.error(f"根据学号获取学生信息失败: {e}")
        raise HTTPException(status_code=500, detail=str(e)) 


@router.get("/students/export/template", response_model=ResponseModel)
async def get_import_template():
    """获取导入模板"""
    template = {
        "json_template": [
            {
                "name": "张三",
                "student_id": "2024001",
                "gender": "male",
                "age": 20,
                "class_name": "计算机科学与技术1班",
                "phone": "13800138000",
                "email": "zhangsan@example.com",
                "qq": "123456789",
                "wechat": "zhangsan_wx",
                "address": "北京市海淀区",
                "father_job": "工程师",
                "mother_job": "教师",
                "contact_info": "紧急联系人：李四 13900139000",
                "notes": "备注信息"
            }
        ],
        "csv_headers": [
            "name", "student_id", "gender", "age", "class_name", "phone", 
            "email", "qq", "wechat", "address", "father_job", "mother_job", 
            "contact_info", "notes"
        ],
        "field_descriptions": {
            "name": "姓名（必填）",
            "student_id": "学号（必填，唯一）",
            "gender": "性别（male/female/other）",
            "age": "年龄（10-100）",
            "class_name": "班级名称",
            "phone": "手机号（11位数字）",
            "email": "邮箱",
            "qq": "QQ号（纯数字，至少5位）",
            "wechat": "微信号",
            "address": "家庭住址",
            "father_job": "父亲职业",
            "mother_job": "母亲职业",
            "contact_info": "其他联系方式",
            "notes": "备注"
        }
    }
    
    return ResponseModel(
        success=True,
        message="导入模板获取成功",
        data=template
    )


@router.post("/students/import/excel", response_model=ResponseModel)
async def import_students_from_excel(
    file: UploadFile = File(..., description="Excel文件")
):
    """从Excel文件导入学生数据"""
    try:
        # 验证文件类型
        if not file.filename.endswith(('.xlsx', '.xls')):
            raise HTTPException(
                status_code=400,
                detail="不支持的文件格式，请上传Excel文件(.xlsx或.xls)"
            )
        
        # 读取文件内容
        file_content = await file.read()
        
        # 解析Excel文件
        excel_data = excel_service.read_excel_file(file_content, file.filename)
        
        # 解析为学生对象
        parse_result, students = excel_service.parse_excel_data(excel_data)
        
        if not students:
            return ResponseModel(
                success=False,
                message="没有有效的学生数据",
                data=parse_result
            )
        
        # 导入到数据库
        import_result = student_service.import_students_from_excel(students)
        
        api_logger.info(f"Excel导入完成: {file.filename}, 成功: {import_result.success_count}, 失败: {import_result.failed_count}")
        
        return ResponseModel(
            success=True,
            message=f"导入完成，成功: {import_result.success_count}, 失败: {import_result.failed_count}",
            data=import_result
        )
        
    except HTTPException:
        raise
    except ServiceException as e:
        api_logger.error(f"Excel导入失败: {e}")
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        api_logger.error(f"Excel导入异常: {e}")
        raise HTTPException(status_code=500, detail=f"Excel导入失败: {str(e)}")


@router.get("/students/template/excel")
async def download_excel_template():
    """下载Excel导入模板"""
    try:
        # 生成Excel模板
        template_bytes = excel_service.generate_excel_template()
        
        # 返回文件流
        return StreamingResponse(
            BytesIO(template_bytes),
            media_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            headers={"Content-Disposition": "attachment; filename=student_import_template.xlsx"}
        )
        
    except Exception as e:
        api_logger.error(f"生成Excel模板失败: {e}")
        raise HTTPException(status_code=500, detail=f"生成Excel模板失败: {str(e)}")


@router.patch("/students/batch", response_model=ResponseModel)
async def batch_update_students(request: BatchUpdateRequest):
    """批量更新学生信息"""
    try:
        # 验证更新数据
        allowed_fields = {
            'class_id', 'phone', 'email', 'notes', 'address', 'qq', 'wechat',
            'father_job', 'mother_job', 'contact_info'
        }
        
        # 过滤不允许批量更新的字段
        filtered_data = {k: v for k, v in request.update_data.items() if k in allowed_fields}
        
        if not filtered_data:
            raise HTTPException(
                status_code=400,
                detail="没有可更新的字段，只允许批量更新: " + ", ".join(allowed_fields)
            )
        
        # 调用服务层进行批量更新
        result = student_service.batch_update_students(request.student_ids, filtered_data)
        
        api_logger.info(f"批量更新学生: {len(request.student_ids)}个, 成功: {result.success_count}, 失败: {result.failed_count}")
        
        return ResponseModel(
            success=True,
            message=f"批量更新完成，成功: {result.success_count}, 失败: {result.failed_count}",
            data=result
        )
        
    except HTTPException:
        raise
    except ServiceException as e:
        api_logger.error(f"批量更新学生失败: {e}")
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        api_logger.error(f"批量更新学生异常: {e}")
        raise HTTPException(status_code=500, detail=f"批量更新失败: {str(e)}")


@router.delete("/students/batch", response_model=ResponseModel)
async def batch_delete_students(request: BatchDeleteRequest):
    """批量删除学生"""
    try:
        # 调用服务层进行批量删除
        result = student_service.batch_delete_students(request.student_ids)
        
        api_logger.info(f"批量删除学生: {len(request.student_ids)}个, 成功: {result.success_count}, 失败: {result.failed_count}")
        
        return ResponseModel(
            success=True,
            message=f"批量删除完成，成功: {result.success_count}, 失败: {result.failed_count}",
            data=result
        )
        
    except HTTPException:
        raise
    except ServiceException as e:
        api_logger.error(f"批量删除学生失败: {e}")
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        api_logger.error(f"批量删除学生异常: {e}")
        raise HTTPException(status_code=500, detail=f"批量删除失败: {str(e)}")


@router.get("/detail/{student_id}", response_model=ResponseModel[StudentResponse])
async def get_student(
    student_id: int = Path(..., description="学生ID")
):
    """获取单个学生信息"""
    try:
        student = student_service.get_student_by_id(student_id)
        return ResponseModel(success=True, data=student)
        
    except StudentNotFoundException as e:
        api_logger.warning(f"学生未找到: {student_id}")
        raise HTTPException(status_code=404, detail=str(e))
    except ServiceException as e:
        api_logger.error(f"获取学生信息失败: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    

@router.put("/students/{student_id}", response_model=ResponseModel)
async def update_student(
    student_id: int = Path(..., description="学生ID"),
    student_data: StudentUpdate = None
):
    """更新学生信息"""
    try:
        updated_student = student_service.update_student(student_id, student_data)
        return ResponseModel(
            success=True,
            message="学生信息更新成功",
            data=updated_student
        )
        
    except StudentNotFoundException as e:
        api_logger.warning(f"学生未找到: {student_id}")
        raise HTTPException(status_code=404, detail=str(e))
    except DuplicateStudentException as e:
        api_logger.warning(f"学生学号重复: {student_data.student_id}")
        raise HTTPException(status_code=400, detail=str(e))
    except ServiceException as e:
        api_logger.error(f"更新学生信息失败: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/students/{student_id}", response_model=ResponseModel)
async def delete_student(
    student_id: int = Path(..., description="学生ID")
):
    """删除学生"""
    try:
        success = student_service.delete_student(student_id)
        if success:
            return ResponseModel(
                success=True,
                message="学生删除成功"
            )
        else:
            raise HTTPException(status_code=500, detail="删除失败")
            
    except StudentNotFoundException as e:
        api_logger.warning(f"学生未找到: {student_id}")
        raise HTTPException(status_code=404, detail=str(e))
    except ServiceException as e:
        api_logger.error(f"删除学生失败: {e}")
        raise HTTPException(status_code=500, detail=str(e))
