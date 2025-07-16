"""
学生相关的Pydantic模型
"""

from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field, validator, model_validator
from enum import Enum
from ..utils.id_card_utils import calculate_age_from_id_card, get_gender_from_id_card


class GenderEnum(str, Enum):
    """性别枚举"""
    MALE = "male"
    FEMALE = "female"
    OTHER = "other"


class StudentBase(BaseModel):
    """学生基础模型"""
    name: str = Field(..., min_length=1, max_length=100, description="学生姓名")
    student_id: str = Field(..., min_length=1, max_length=50, description="学号")
    gender: Optional[GenderEnum] = Field(None, description="性别")
    age: Optional[int] = Field(None, ge=10, le=100, description="年龄")
    class_id: Optional[int] = Field(None, description="班级ID")
    class_name: Optional[str] = Field(None, max_length=100, description="班级名称")
    phone: Optional[str] = Field(None, max_length=20, description="手机号")
    email: Optional[str] = Field(None, max_length=100, description="邮箱")
    qq: Optional[str] = Field(None, max_length=20, description="QQ号")
    wechat: Optional[str] = Field(None, max_length=50, description="微信号")
    address: Optional[str] = Field(None, max_length=200, description="家庭住址")
    father_job: Optional[str] = Field(None, max_length=100, description="父亲职业")
    mother_job: Optional[str] = Field(None, max_length=100, description="母亲职业")
    contact_info: Optional[str] = Field(None, max_length=200, description="其他联系方式")
    notes: Optional[str] = Field(None, max_length=500, description="备注")
    
    # 新增字段 - Excel表格中的字段
    chinese_score: Optional[float] = Field(None, ge=0, le=150, description="语文成绩")
    math_score: Optional[float] = Field(None, ge=0, le=150, description="数学成绩")
    english_score: Optional[float] = Field(None, ge=0, le=150, description="外语成绩")
    science_score: Optional[float] = Field(None, ge=0, le=150, description="自然成绩")
    total_score: Optional[float] = Field(None, ge=0, le=600, description="总分")
    id_card: Optional[str] = Field(None, max_length=18, description="身份证号")
    primary_school: Optional[str] = Field(None, max_length=100, description="毕业小学")
    height: Optional[float] = Field(None, ge=100, le=250, description="身高(cm)")
    vision: Optional[str] = Field(None, max_length=20, description="视力")
    class_position_intention: Optional[str] = Field(None, max_length=100, description="初中意愿担任班级职务")
    visit_time: Optional[str] = Field(None, max_length=100, description="家访可行时间")
    good_subjects: Optional[str] = Field(None, max_length=200, description="擅长科目")
    
    @validator('student_id')
    def validate_student_id(cls, v):
        if not v.strip():
            raise ValueError('学号不能为空')
        return v.strip()
    
    @validator('name')
    def validate_name(cls, v):
        if not v.strip():
            raise ValueError('姓名不能为空')
        return v.strip()
    
    @validator('phone')
    def validate_phone(cls, v):
        if v and not v.strip():
            return None
        if v and len(v.strip()) > 0:
            # 简单的手机号验证
            phone_clean = v.strip()
            if not phone_clean.isdigit() or len(phone_clean) != 11:
                raise ValueError('手机号格式不正确')
        return v.strip() if v else None
    
    @validator('email')
    def validate_email(cls, v):
        if v and not v.strip():
            return None
        if v and '@' not in v:
            raise ValueError('邮箱格式不正确')
        return v.strip() if v else None
    
    @validator('qq')
    def validate_qq(cls, v):
        if v and not v.strip():
            return None
        if v and (not v.strip().isdigit() or len(v.strip()) < 5):
            raise ValueError('QQ号格式不正确')
        return v.strip() if v else None
    
    @validator('id_card')
    def validate_id_card(cls, v):
        if v and not v.strip():
            return None
        if v and len(v.strip()) not in [15, 18]:
            raise ValueError('身份证号格式不正确')
        return v.strip() if v else None
    
    @validator('gender', pre=True)
    def validate_gender(cls, v):
        if v is None or v == '':
            return None
        # 处理中文性别
        if v in ['男', 'male', 'MALE', 'Male']:
            return GenderEnum.MALE
        elif v in ['女', 'female', 'FEMALE', 'Female']:
            return GenderEnum.FEMALE
        elif v in ['其他', 'other', 'OTHER', 'Other']:
            return GenderEnum.OTHER
        return v
    
    @model_validator(mode='before')
    @classmethod
    def validate_gender_from_id_card(cls, values):
        """根据身份证号自动设置性别（年龄改为动态计算）"""
        # 处理字典或模型实例
        if isinstance(values, dict):
            data = values
        else:
            data = values.__dict__ if hasattr(values, '__dict__') else values
            
        id_card = data.get('id_card')
        if id_card:
            # 自动设置性别（如果没有手动设置）
            if not data.get('gender'):
                calculated_gender = get_gender_from_id_card(id_card)
                if calculated_gender:
                    data['gender'] = GenderEnum(calculated_gender)
        
        return data


class StudentCreate(StudentBase):
    """创建学生模型"""
    pass


class StudentUpdate(BaseModel):
    """更新学生模型"""
    name: Optional[str] = Field(None, min_length=1, max_length=100, description="学生姓名")
    student_id: Optional[str] = Field(None, min_length=1, max_length=50, description="学号")
    gender: Optional[GenderEnum] = Field(None, description="性别")
    age: Optional[int] = Field(None, ge=10, le=100, description="年龄")
    class_name: Optional[str] = Field(None, max_length=100, description="班级名称")
    phone: Optional[str] = Field(None, max_length=20, description="手机号")
    email: Optional[str] = Field(None, max_length=100, description="邮箱")
    qq: Optional[str] = Field(None, max_length=20, description="QQ号")
    wechat: Optional[str] = Field(None, max_length=50, description="微信号")
    address: Optional[str] = Field(None, max_length=200, description="家庭住址")
    father_job: Optional[str] = Field(None, max_length=100, description="父亲职业")
    mother_job: Optional[str] = Field(None, max_length=100, description="母亲职业")
    contact_info: Optional[str] = Field(None, max_length=200, description="其他联系方式")
    notes: Optional[str] = Field(None, max_length=500, description="备注")
    
    # 新增字段 - Excel表格中的字段
    chinese_score: Optional[float] = Field(None, ge=0, le=150, description="语文成绩")
    math_score: Optional[float] = Field(None, ge=0, le=150, description="数学成绩")
    english_score: Optional[float] = Field(None, ge=0, le=150, description="外语成绩")
    science_score: Optional[float] = Field(None, ge=0, le=150, description="自然成绩")
    total_score: Optional[float] = Field(None, ge=0, le=600, description="总分")
    id_card: Optional[str] = Field(None, max_length=18, description="身份证号")
    primary_school: Optional[str] = Field(None, max_length=100, description="毕业小学")
    height: Optional[float] = Field(None, ge=100, le=250, description="身高(cm)")
    vision: Optional[str] = Field(None, max_length=20, description="视力")
    class_position_intention: Optional[str] = Field(None, max_length=100, description="初中意愿担任班级职务")
    visit_time: Optional[str] = Field(None, max_length=100, description="家访可行时间")
    good_subjects: Optional[str] = Field(None, max_length=200, description="擅长科目")
    
    @validator('student_id')
    def validate_student_id(cls, v):
        if v is not None and not v.strip():
            raise ValueError('学号不能为空')
        return v.strip() if v else v
    
    @validator('name')
    def validate_name(cls, v):
        if v is not None and not v.strip():
            raise ValueError('姓名不能为空')
        return v.strip() if v else v
    
    @validator('phone')
    def validate_phone(cls, v):
        if v and not v.strip():
            return None
        if v and len(v.strip()) > 0:
            # 简单的手机号验证
            phone_clean = v.strip()
            if not phone_clean.isdigit() or len(phone_clean) != 11:
                raise ValueError('手机号格式不正确')
        return v.strip() if v else None
    
    @validator('email')
    def validate_email(cls, v):
        if v and not v.strip():
            return None
        if v and '@' not in v:
            raise ValueError('邮箱格式不正确')
        return v.strip() if v else None
    
    @validator('qq')
    def validate_qq(cls, v):
        if v and not v.strip():
            return None
        if v and (not v.strip().isdigit() or len(v.strip()) < 5):
            raise ValueError('QQ号格式不正确')
        return v.strip() if v else None
    
    @validator('id_card')
    def validate_id_card(cls, v):
        if v and not v.strip():
            return None
        if v and len(v.strip()) not in [15, 18]:
            raise ValueError('身份证号格式不正确')
        return v.strip() if v else None
    
    @validator('gender', pre=True)
    def validate_gender(cls, v):
        if v is None or v == '':
            return None
        # 处理中文性别
        if v in ['男', 'male', 'MALE', 'Male']:
            return GenderEnum.MALE
        elif v in ['女', 'female', 'FEMALE', 'Female']:
            return GenderEnum.FEMALE
        elif v in ['其他', 'other', 'OTHER', 'Other']:
            return GenderEnum.OTHER
        return v
    
    @model_validator(mode='before')
    @classmethod
    def validate_age_and_gender_from_id_card(cls, values):
        """根据身份证号自动计算年龄和性别"""
        # 处理字典或模型实例
        if isinstance(values, dict):
            data = values
        else:
            data = values.__dict__ if hasattr(values, '__dict__') else values
            
        id_card = data.get('id_card')
        if id_card:
            # 自动计算年龄
            calculated_age = calculate_age_from_id_card(id_card)
            if calculated_age is not None:
                data['age'] = calculated_age
            
            # 自动设置性别（如果没有手动设置）
            if not data.get('gender'):
                calculated_gender = get_gender_from_id_card(id_card)
                if calculated_gender:
                    data['gender'] = GenderEnum(calculated_gender)
        
        return data


class StudentResponse(StudentBase):
    """学生响应模型"""
    id: int
    created_at: datetime
    updated_at: datetime
    
    class Config:
        orm_mode = True


class StudentListResponse(BaseModel):
    """学生列表响应模型"""
    students: list[StudentResponse]
    total: int 


class StudentBatchImport(BaseModel):
    """批量导入学生模型"""
    students: list[StudentCreate] = Field(..., min_items=1, description="学生列表")
    
    @validator('students')
    def validate_students(cls, v):
        if not v:
            raise ValueError('学生列表不能为空')
        # 检查学号是否重复
        student_ids = [s.student_id for s in v]
        if len(student_ids) != len(set(student_ids)):
            raise ValueError('学生列表中存在重复的学号')
        return v


class ExcelImportResult(BaseModel):
    """Excel导入结果模型"""
    success_count: int = Field(..., description="成功导入数量")
    failed_count: int = Field(..., description="失败数量")
    total_count: int = Field(..., description="总数量")
    errors: list[str] = Field(default=[], description="错误信息列表")
    success_students: list[str] = Field(default=[], description="成功导入的学生姓名列表")
    failed_students: list[dict] = Field(default=[], description="失败的学生信息列表")


class BatchUpdateRequest(BaseModel):
    """批量更新请求模型"""
    student_ids: list[int] = Field(..., min_length=1, description="要更新的学生ID列表")
    update_data: dict = Field(..., description="要更新的数据")


class BatchDeleteRequest(BaseModel):
    """批量删除请求模型"""
    student_ids: list[int] = Field(..., min_length=1, description="要删除的学生ID列表")


class BatchOperationResult(BaseModel):
    """批量操作结果模型"""
    success_count: int = Field(..., description="成功操作数量")
    failed_count: int = Field(..., description="失败数量")
    total_count: int = Field(..., description="总数量")
    errors: list[str] = Field(default=[], description="错误信息列表")
    success_ids: list[int] = Field(default=[], description="成功操作的学生ID列表")
    failed_ids: list[int] = Field(default=[], description="失败的学生ID列表")