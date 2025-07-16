"""
Excel处理服务
"""

import pandas as pd
import openpyxl
from typing import List, Dict, Any, Optional
from io import BytesIO
from pathlib import Path

from app.schemas.student import StudentCreate, ExcelImportResult
from app.core.logger import api_logger
from app.utils.exceptions import ServiceException


class ExcelService:
    """Excel处理服务"""
    
    # Excel表格字段映射
    EXCEL_FIELD_MAPPING = {
        '学号': 'student_id',
        '姓名': 'name',
        '语文': 'chinese_score',
        '数学': 'math_score',
        '外语': 'english_score',
        '自然': 'science_score',
        '总分': 'total_score',
        '性别': 'gender',
        '身份证号': 'id_card',
        '毕业小学': 'primary_school',
        '家庭住址': 'address',
        '联系方式': 'contact_info',
        '身高': 'height',
        '视力': 'vision',
        '初中意愿担任班级职务': 'class_position_intention',
        '家访可行时间': 'visit_time',
        '擅长科目': 'good_subjects'
    }
    
    def __init__(self):
        pass
    
    def read_excel_file(self, file_content: bytes, filename: str) -> List[Dict[str, Any]]:
        """读取Excel文件内容"""
        try:
            # 使用pandas读取Excel文件
            if filename.endswith('.xlsx') or filename.endswith('.xls'):
                df = pd.read_excel(BytesIO(file_content), engine='openpyxl')
            else:
                raise ServiceException("不支持的文件格式，请上传Excel文件(.xlsx或.xls)")
            
            # 去除空行
            df = df.dropna(how='all')
            
            # 转换为字典列表
            data = df.to_dict('records')
            
            api_logger.info(f"成功读取Excel文件 {filename}，共 {len(data)} 行数据")
            return data
            
        except Exception as e:
            api_logger.error(f"读取Excel文件失败: {e}")
            raise ServiceException(f"读取Excel文件失败: {str(e)}")
    
    def parse_excel_data(self, excel_data: List[Dict[str, Any]]) -> ExcelImportResult:
        """解析Excel数据为学生对象"""
        result = ExcelImportResult(
            success_count=0,
            failed_count=0,
            total_count=len(excel_data),
            errors=[],
            success_students=[],
            failed_students=[]
        )
        
        students = []
        
        for index, row in enumerate(excel_data, start=1):
            try:
                # 映射Excel字段到模型字段
                student_data = {}
                for excel_field, model_field in self.EXCEL_FIELD_MAPPING.items():
                    if excel_field in row:
                        value = row[excel_field]
                        # 处理空值
                        if pd.isna(value) or value == '':
                            value = None
                        elif isinstance(value, str):
                            value = value.strip()
                        student_data[model_field] = value
                
                # 数据类型转换和验证
                student_data = self._convert_data_types(student_data)
                
                # 创建学生对象
                student = StudentCreate(**student_data)
                students.append(student)
                
                result.success_count += 1
                result.success_students.append(student.name)
                
            except Exception as e:
                result.failed_count += 1
                error_msg = f"第{index}行数据解析失败: {str(e)}"
                result.errors.append(error_msg)
                result.failed_students.append({
                    'row': index,
                    'data': row,
                    'error': str(e)
                })
                api_logger.warning(error_msg)
        
        # 将成功解析的学生添加到结果中
        if hasattr(result, 'students'):
            result.students = students
        else:
            # 如果模型没有students字段，我们需要在调用处处理
            pass
        
        api_logger.info(f"Excel数据解析完成，成功: {result.success_count}, 失败: {result.failed_count}")
        return result, students
    
    def _convert_data_types(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """转换数据类型"""
        # 数值字段转换
        numeric_fields = ['chinese_score', 'math_score', 'english_score', 'science_score', 'total_score', 'height']
        for field in numeric_fields:
            if field in data and data[field] is not None:
                try:
                    data[field] = float(data[field])
                except (ValueError, TypeError):
                    data[field] = None
        
        # 整数字段转换
        integer_fields = ['age']
        for field in integer_fields:
            if field in data and data[field] is not None:
                try:
                    data[field] = int(data[field])
                except (ValueError, TypeError):
                    data[field] = None
        
        # 字符串字段处理
        string_fields = ['student_id', 'name', 'gender', 'id_card', 'primary_school', 
                        'address', 'contact_info', 'vision', 'class_position_intention', 
                        'visit_time', 'good_subjects']
        for field in string_fields:
            if field in data and data[field] is not None:
                data[field] = str(data[field]).strip()
        
        return data
    
    def generate_excel_template(self) -> bytes:
        """生成Excel导入模板"""
        try:
            # 创建示例数据
            template_data = {
                '学号': ['2024001', '2024002'],
                '姓名': ['张三', '李四'],
                '语文': [85.5, 90.0],
                '数学': [88.0, 92.5],
                '外语': [82.5, 89.0],
                '自然': [90.0, 87.5],
                '总分': [346.0, 359.0],
                '性别': ['男', '女'],
                '身份证号': ['123456789012345678', '123456789012345679'],
                '毕业小学': ['示例小学', '示例小学'],
                '家庭住址': ['示例地址1', '示例地址2'],
                '联系方式': ['13800138001', '13800138002'],
                '身高': [165.0, 160.0],
                '视力': ['5.0', '4.8'],
                '初中意愿担任班级职务': ['班长', '学习委员'],
                '家访可行时间': ['周末', '工作日晚上'],
                '擅长科目': ['数学,物理', '语文,英语']
            }
            
            # 创建DataFrame
            df = pd.DataFrame(template_data)
            
            # 转换为Excel字节流
            output = BytesIO()
            with pd.ExcelWriter(output, engine='openpyxl') as writer:
                df.to_excel(writer, index=False, sheet_name='学生信息')
                
                # 设置列宽
                worksheet = writer.sheets['学生信息']
                for column in worksheet.columns:
                    max_length = 0
                    column_letter = column[0].column_letter
                    for cell in column:
                        try:
                            if len(str(cell.value)) > max_length:
                                max_length = len(str(cell.value))
                        except:
                            pass
                    adjusted_width = min(max_length + 2, 20)
                    worksheet.column_dimensions[column_letter].width = adjusted_width
            
            output.seek(0)
            return output.read()
            
        except Exception as e:
            api_logger.error(f"生成Excel模板失败: {e}")
            raise ServiceException(f"生成Excel模板失败: {str(e)}")


# 创建全局实例
excel_service = ExcelService() 