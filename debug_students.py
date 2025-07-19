#!/usr/bin/env python3
"""
调试学生列表查询问题
"""

from app.core.database import db_manager
from app.services.student import student_search_service

def debug_students():
    print("=== 调试学生列表查询问题 ===")
    
    # 1. 检查数据库中的学生总数
    try:
        result = db_manager.execute_query('SELECT COUNT(*) as count FROM students')
        total_students = result[0]['count'] if result else 0
        print(f"1. 数据库中学生总数: {total_students}")
    except Exception as e:
        print(f"1. 查询学生总数失败: {e}")
        return
    
    # 2. 检查班级表
    try:
        result = db_manager.execute_query('SELECT COUNT(*) as count FROM classes')
        total_classes = result[0]['count'] if result else 0
        print(f"2. 数据库中班级总数: {total_classes}")
        
        if total_classes > 0:
            classes = db_manager.execute_query('SELECT * FROM classes LIMIT 3')
            print(f"   前3个班级: {classes}")
    except Exception as e:
        print(f"2. 查询班级失败: {e}")
    
    # 3. 测试JOIN查询
    try:
        query = '''
            SELECT COUNT(*) as total 
            FROM students s
            LEFT JOIN classes c ON s.class_id = c.id
        '''
        result = db_manager.execute_query(query)
        join_count = result[0]['total'] if result else 0
        print(f"3. JOIN查询结果总数: {join_count}")
    except Exception as e:
        print(f"3. JOIN查询失败: {e}")
    
    # 4. 测试完整的学生查询
    try:
        query = '''
            SELECT s.id, s.name, s.student_id, s.gender, s.age, s.class_id, c.name as class_name
            FROM students s
            LEFT JOIN classes c ON s.class_id = c.id
            LIMIT 3
        '''
        result = db_manager.execute_query(query)
        print(f"4. 完整查询前3条结果: {result}")
    except Exception as e:
        print(f"4. 完整查询失败: {e}")
    
    # 5. 测试服务层查询
    try:
        result = student_search_service.get_students(page=1, page_size=5)
        print(f"5. 服务层查询结果:")
        print(f"   - 总数: {result['total']}")
        print(f"   - 学生数量: {len(result['students'])}")
        if result['students']:
            print(f"   - 第一个学生: {result['students'][0]}")
    except Exception as e:
        print(f"5. 服务层查询失败: {e}")
    
    # 6. 检查数据库文件路径
    try:
        from app.core.config import settings
        print(f"6. 数据库文件路径: {settings.database_path}")
        import os
        if os.path.exists(settings.database_path):
            size = os.path.getsize(settings.database_path)
            print(f"   数据库文件大小: {size} bytes")
        else:
            print(f"   数据库文件不存在!")
    except Exception as e:
        print(f"6. 检查数据库文件失败: {e}")

if __name__ == "__main__":
    debug_students()