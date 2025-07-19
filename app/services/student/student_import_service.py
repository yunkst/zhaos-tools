"""
学生导入服务 - 处理学生的Excel导入功能
"""

from typing import List, Dict, Any, Optional, IO
from datetime import datetime
import pandas as pd
import io

from app.core.database import db_manager
from app.core.logger import service_logger
from app.schemas.student import StudentCreate
from app.utils.exceptions import ServiceException, DuplicateStudentException
from app.services.excel_service import ExcelService


class StudentImportService:
    """学生导入服务类"""
    
    def __init__(self):
        self.db = db_manager
        self.excel_service = ExcelService()
    
    def get_import_template(self) -> Dict[str, Any]:
        """获取导入模板的字段定义
        
        Returns:
            Dict: 包含模板字段定义和示例数据
        """
        try:
            template_fields = {
                'name': {'label': '姓名', 'required': True, 'type': 'string', 'example': '张三'},
                'student_id': {'label': '学号', 'required': True, 'type': 'string', 'example': '2024001'},
                'gender': {'label': '性别', 'required': False, 'type': 'string', 'example': '男', 'options': ['男', '女']},
                'age': {'label': '年龄', 'required': False, 'type': 'integer', 'example': 16},
                'class_name': {'label': '班级', 'required': False, 'type': 'string', 'example': '高一(1)班'},
                'phone': {'label': '电话', 'required': False, 'type': 'string', 'example': '13800138000'},
                'email': {'label': '邮箱', 'required': False, 'type': 'string', 'example': 'zhangsan@example.com'},
                'qq': {'label': 'QQ', 'required': False, 'type': 'string', 'example': '123456789'},
                'wechat': {'label': '微信', 'required': False, 'type': 'string', 'example': 'zhangsan_wx'},
                'address': {'label': '地址', 'required': False, 'type': 'string', 'example': '北京市朝阳区'},
                'father_job': {'label': '父亲职业', 'required': False, 'type': 'string', 'example': '工程师'},
                'mother_job': {'label': '母亲职业', 'required': False, 'type': 'string', 'example': '教师'},
                'contact_info': {'label': '联系信息', 'required': False, 'type': 'string', 'example': '紧急联系人：李四 13900139000'},
                'notes': {'label': '备注', 'required': False, 'type': 'string', 'example': '学习积极主动'},
                'chinese_score': {'label': '语文成绩', 'required': False, 'type': 'number', 'example': 85.5},
                'math_score': {'label': '数学成绩', 'required': False, 'type': 'number', 'example': 92.0},
                'english_score': {'label': '英语成绩', 'required': False, 'type': 'number', 'example': 88.0},
                'science_score': {'label': '科学成绩', 'required': False, 'type': 'number', 'example': 90.0},
                'total_score': {'label': '总分', 'required': False, 'type': 'number', 'example': 355.5},
                'id_card': {'label': '身份证号', 'required': False, 'type': 'string', 'example': '110101200801011234'},
                'primary_school': {'label': '小学', 'required': False, 'type': 'string', 'example': '北京市第一小学'},
                'height': {'label': '身高(cm)', 'required': False, 'type': 'number', 'example': 165.5},
                'vision': {'label': '视力', 'required': False, 'type': 'string', 'example': '5.0'},
                'class_position_intention': {'label': '班级职位意向', 'required': False, 'type': 'string', 'example': '学习委员'},
                'visit_time': {'label': '家访时间', 'required': False, 'type': 'string', 'example': '2024-01-15'},
                'good_subjects': {'label': '擅长科目', 'required': False, 'type': 'string', 'example': '数学,物理'}
            }
            
            # 生成示例数据
            example_data = []
            for i in range(3):
                example_row = {}
                for field, config in template_fields.items():
                    if field == 'name':
                        example_row[config['label']] = f"学生{i+1}"
                    elif field == 'student_id':
                        example_row[config['label']] = f"202400{i+1:02d}"
                    elif field == 'class_name':
                        example_row[config['label']] = f"高一({i+1})班"
                    else:
                        example_row[config['label']] = config.get('example', '')
                example_data.append(example_row)
            
            result = {
                'fields': template_fields,
                'example_data': example_data,
                'required_fields': [config['label'] for field, config in template_fields.items() if config['required']]
            }
            
            service_logger.info("获取导入模板成功")
            return result
            
        except Exception as e:
            service_logger.error(f"获取导入模板失败: {e}")
            raise ServiceException(f"获取导入模板失败: {e}")
    
    def generate_excel_template(self) -> bytes:
        """生成Excel导入模板文件
        
        Returns:
            bytes: Excel文件的二进制数据
        """
        try:
            template_info = self.get_import_template()
            
            # 创建DataFrame
            headers = [config['label'] for config in template_info['fields'].values()]
            df = pd.DataFrame(template_info['example_data'])
            
            # 生成Excel文件
            excel_data = self.excel_service.create_excel_from_dataframe(
                df, 
                sheet_name="学生导入模板",
                headers=headers
            )
            
            service_logger.info("生成Excel导入模板成功")
            return excel_data
            
        except Exception as e:
            service_logger.error(f"生成Excel导入模板失败: {e}")
            raise ServiceException(f"生成Excel导入模板失败: {e}")
    
    def validate_import_data(self, data: List[Dict[str, Any]]) -> Dict[str, Any]:
        """验证导入数据
        
        Args:
            data: 待验证的数据列表
        
        Returns:
            Dict: 验证结果，包含有效数据和错误信息
        """
        try:
            valid_data = []
            invalid_data = []
            
            # 字段映射（中文标签到英文字段名）
            field_mapping = {
                '姓名': 'name',
                '学号': 'student_id',
                '性别': 'gender',
                '年龄': 'age',
                '班级': 'class_name',
                '电话': 'phone',
                '邮箱': 'email',
                'QQ': 'qq',
                '微信': 'wechat',
                '地址': 'address',
                '父亲职业': 'father_job',
                '母亲职业': 'mother_job',
                '联系信息': 'contact_info',
                '备注': 'notes',
                '语文成绩': 'chinese_score',
                '数学成绩': 'math_score',
                '英语成绩': 'english_score',
                '科学成绩': 'science_score',
                '总分': 'total_score',
                '身份证号': 'id_card',
                '小学': 'primary_school',
                '身高(cm)': 'height',
                '视力': 'vision',
                '班级职位意向': 'class_position_intention',
                '家访时间': 'visit_time',
                '擅长科目': 'good_subjects'
            }
            
            for row_index, row_data in enumerate(data, start=1):
                errors = []
                converted_data = {}
                
                # 转换字段名
                for chinese_field, english_field in field_mapping.items():
                    value = row_data.get(chinese_field)
                    if value is not None and str(value).strip():
                        converted_data[english_field] = str(value).strip()
                
                # 验证必填字段
                if not converted_data.get('name'):
                    errors.append("姓名不能为空")
                
                if not converted_data.get('student_id'):
                    errors.append("学号不能为空")
                
                # 验证数据类型和格式
                if 'age' in converted_data:
                    try:
                        age = int(float(converted_data['age']))
                        if age < 0 or age > 100:
                            errors.append("年龄必须在0-100之间")
                        else:
                            converted_data['age'] = age
                    except (ValueError, TypeError):
                        errors.append("年龄必须是数字")
                
                # 验证性别
                if 'gender' in converted_data:
                    if converted_data['gender'] not in ['男', '女']:
                        errors.append("性别只能是'男'或'女'")
                
                # 验证成绩字段
                score_fields = ['chinese_score', 'math_score', 'english_score', 'science_score', 'total_score', 'height']
                for field in score_fields:
                    if field in converted_data:
                        try:
                            score = float(converted_data[field])
                            if score < 0:
                                errors.append(f"{field}不能为负数")
                            else:
                                converted_data[field] = score
                        except (ValueError, TypeError):
                            errors.append(f"{field}必须是数字")
                
                # 验证邮箱格式
                if 'email' in converted_data:
                    email = converted_data['email']
                    if '@' not in email or '.' not in email:
                        errors.append("邮箱格式不正确")
                
                # 验证身份证号格式
                if 'id_card' in converted_data:
                    id_card = converted_data['id_card']
                    if len(id_card) not in [15, 18]:
                        errors.append("身份证号长度不正确")
                
                if errors:
                    invalid_data.append({
                        'row': row_index,
                        'data': row_data,
                        'errors': errors
                    })
                else:
                    valid_data.append(converted_data)
            
            result = {
                'valid_data': valid_data,
                'invalid_data': invalid_data,
                'total_rows': len(data),
                'valid_count': len(valid_data),
                'invalid_count': len(invalid_data)
            }
            
            service_logger.info(f"数据验证完成: 有效 {len(valid_data)} 条，无效 {len(invalid_data)} 条")
            return result
            
        except Exception as e:
            service_logger.error(f"验证导入数据失败: {e}")
            raise ServiceException(f"验证导入数据失败: {e}")
    
    def import_from_excel(self, file_content: bytes, skip_duplicates: bool = True) -> Dict[str, Any]:
        """从Excel文件导入学生数据
        
        Args:
            file_content: Excel文件的二进制内容
            skip_duplicates: 是否跳过重复的学号
        
        Returns:
            Dict: 导入结果统计
        """
        try:
            # 读取Excel文件
            df = pd.read_excel(io.BytesIO(file_content))
            
            # 转换为字典列表
            data = df.to_dict('records')
            
            # 验证数据
            validation_result = self.validate_import_data(data)
            
            if not validation_result['valid_data']:
                return {
                    'success_count': 0,
                    'failed_count': validation_result['invalid_count'],
                    'duplicate_count': 0,
                    'total_count': validation_result['total_rows'],
                    'failed_items': validation_result['invalid_data'],
                    'message': '没有有效的数据可以导入'
                }
            
            # 导入有效数据
            import_result = self.batch_import_students(
                validation_result['valid_data'], 
                skip_duplicates
            )
            
            # 合并结果
            result = {
                'success_count': import_result['success_count'],
                'failed_count': import_result['failed_count'] + validation_result['invalid_count'],
                'duplicate_count': import_result['duplicate_count'],
                'total_count': validation_result['total_rows'],
                'failed_items': import_result['failed_items'] + validation_result['invalid_data']
            }
            
            service_logger.info(f"Excel导入完成: 成功 {result['success_count']}, 失败 {result['failed_count']}, 重复 {result['duplicate_count']}")
            return result
            
        except Exception as e:
            service_logger.error(f"Excel导入失败: {e}")
            raise ServiceException(f"Excel导入失败: {e}")
    
    def batch_import_students(self, students_data: List[Dict[str, Any]], skip_duplicates: bool = True) -> Dict[str, Any]:
        """批量导入学生数据
        
        Args:
            students_data: 学生数据列表
            skip_duplicates: 是否跳过重复的学号
        
        Returns:
            Dict: 导入结果统计
        """
        try:
            success_count = 0
            failed_count = 0
            duplicate_count = 0
            failed_items = []
            
            for student_data in students_data:
                try:
                    # 检查学号是否已存在
                    existing_query = "SELECT id FROM students WHERE student_id = ?"
                    existing_student = self.db.execute_query(existing_query, (student_data['student_id'],))
                    
                    if existing_student:
                        duplicate_count += 1
                        if not skip_duplicates:
                            failed_count += 1
                            failed_items.append({
                                'data': student_data,
                                'error': f"学号 {student_data['student_id']} 已存在"
                            })
                        continue
                    
                    # 插入新学生
                    insert_query = """
                        INSERT INTO students (
                            name, student_id, gender, age, class_name, phone, email, qq, wechat, 
                            address, father_job, mother_job, contact_info, notes, chinese_score, 
                            math_score, english_score, science_score, total_score, id_card, 
                            primary_school, height, vision, class_position_intention, visit_time, 
                            good_subjects, created_at, updated_at
                        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    """
                    
                    now = datetime.now()
                    values = (
                        student_data.get('name'),
                        student_data.get('student_id'),
                        student_data.get('gender'),
                        student_data.get('age'),
                        student_data.get('class_name'),
                        student_data.get('phone'),
                        student_data.get('email'),
                        student_data.get('qq'),
                        student_data.get('wechat'),
                        student_data.get('address'),
                        student_data.get('father_job'),
                        student_data.get('mother_job'),
                        student_data.get('contact_info'),
                        student_data.get('notes'),
                        student_data.get('chinese_score'),
                        student_data.get('math_score'),
                        student_data.get('english_score'),
                        student_data.get('science_score'),
                        student_data.get('total_score'),
                        student_data.get('id_card'),
                        student_data.get('primary_school'),
                        student_data.get('height'),
                        student_data.get('vision'),
                        student_data.get('class_position_intention'),
                        student_data.get('visit_time'),
                        student_data.get('good_subjects'),
                        now,
                        now
                    )
                    
                    self.db.execute_insert(insert_query, values)
                    success_count += 1
                    
                except Exception as e:
                    failed_count += 1
                    failed_items.append({
                        'data': student_data,
                        'error': str(e)
                    })
            
            result = {
                'success_count': success_count,
                'failed_count': failed_count,
                'duplicate_count': duplicate_count,
                'total_count': len(students_data),
                'failed_items': failed_items
            }
            
            service_logger.info(f"批量导入学生完成: 成功 {success_count}, 失败 {failed_count}, 重复 {duplicate_count}")
            return result
            
        except Exception as e:
            service_logger.error(f"批量导入学生失败: {e}")
            raise ServiceException(f"批量导入学生失败: {e}")