"""
异常处理模块 - 定义应用中的自定义异常
"""


class ZhaosToolsException(Exception):
    """应用基础异常类"""
    
    def __init__(self, message: str, code: str = None):
        self.message = message
        self.code = code
        super().__init__(self.message)


class DatabaseException(ZhaosToolsException):
    """数据库相关异常"""
    pass


class ValidationException(ZhaosToolsException):
    """数据验证异常"""
    pass


class ServiceException(ZhaosToolsException):
    """服务层异常"""
    pass


class NotFoundException(ServiceException):
    """资源未找到异常基类"""
    pass


class APIException(ZhaosToolsException):
    """API层异常"""
    pass


class ConfigurationException(ZhaosToolsException):
    """配置异常"""
    pass


class StudentNotFoundException(ServiceException):
    """学生未找到异常"""
    
    def __init__(self, student_id: str):
        super().__init__(f"学生未找到: {student_id}", "STUDENT_NOT_FOUND")


class DuplicateStudentException(ServiceException):
    """学生重复异常"""
    
    def __init__(self, student_id: str):
        super().__init__(f"学生学号已存在: {student_id}", "DUPLICATE_STUDENT")


class InvalidDataException(ValidationException):
    """无效数据异常"""
    
    def __init__(self, field: str, value: str):
        super().__init__(f"无效的{field}: {value}", "INVALID_DATA") 