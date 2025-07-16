"""
身份证号工具函数
"""

import re
from datetime import datetime
from typing import Optional, Tuple


def parse_id_card(id_card: str) -> Optional[Tuple[str, str, int]]:
    """
    解析身份证号，提取出生日期、性别和年龄
    
    Args:
        id_card: 身份证号
        
    Returns:
        tuple: (出生日期, 性别, 年龄) 或 None
    """
    if not id_card:
        return None
    
    id_card = id_card.strip()
    
    # 18位身份证号
    if len(id_card) == 18:
        # 验证格式
        if not re.match(r'^\d{17}[\dXx]$', id_card):
            return None
        
        # 提取出生日期
        birth_year = int(id_card[6:10])
        birth_month = int(id_card[10:12])
        birth_day = int(id_card[12:14])
        
        # 提取性别（第17位，奇数为男，偶数为女）
        gender_code = int(id_card[16])
        gender = "male" if gender_code % 2 == 1 else "female"
        
    # 15位身份证号
    elif len(id_card) == 15:
        # 验证格式
        if not re.match(r'^\d{15}$', id_card):
            return None
        
        # 提取出生日期（15位身份证年份前面加19）
        birth_year = 1900 + int(id_card[6:8])
        birth_month = int(id_card[8:10])
        birth_day = int(id_card[10:12])
        
        # 提取性别（第15位，奇数为男，偶数为女）
        gender_code = int(id_card[14])
        gender = "male" if gender_code % 2 == 1 else "female"
    else:
        return None
    
    # 验证日期是否有效
    try:
        birth_date = datetime(birth_year, birth_month, birth_day)
    except ValueError:
        return None
    
    # 计算年龄
    today = datetime.now()
    age = today.year - birth_year
    
    # 如果还没到生日，年龄减1
    if today.month < birth_month or (today.month == birth_month and today.day < birth_day):
        age -= 1
    
    birth_date_str = birth_date.strftime('%Y-%m-%d')
    
    return birth_date_str, gender, age


def calculate_age_from_id_card(id_card: str) -> Optional[int]:
    """
    根据身份证号计算年龄
    
    Args:
        id_card: 身份证号
        
    Returns:
        年龄或None
    """
    result = parse_id_card(id_card)
    if result:
        return result[2]
    return None


def get_gender_from_id_card(id_card: str) -> Optional[str]:
    """
    根据身份证号获取性别
    
    Args:
        id_card: 身份证号
        
    Returns:
        性别（"male"/"female"）或None
    """
    result = parse_id_card(id_card)
    if result:
        return result[1]
    return None


def get_birth_date_from_id_card(id_card: str) -> Optional[str]:
    """
    根据身份证号获取出生日期
    
    Args:
        id_card: 身份证号
        
    Returns:
        出生日期字符串（YYYY-MM-DD）或None
    """
    result = parse_id_card(id_card)
    if result:
        return result[0]
    return None 