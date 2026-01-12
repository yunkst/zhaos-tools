import pandas as pd
import json

# 检查两个Excel文件的Sheet名称
file1_path = r'D:\myspace\teacher_tools\app\2025-7-2.xlsx'
file2_path = r'D:\myspace\teacher_tools\app\2025-7-3.xlsx'

# 代码期望的Sheet名称
expected_sheets = {'总', '语', '数', '英', '科', '社'}

print('=' * 60)
print('Excel Sheet 名称对比')
print('=' * 60)

f1 = pd.ExcelFile(file1_path)
f2 = pd.ExcelFile(file2_path)

print(f'\n2025-7-2.xlsx (失败的文件):')
print(f'  Sheet名称: {f1.sheet_names}')

print(f'\n2025-7-3.xlsx (成功的文件):')
print(f'  Sheet名称: {f2.sheet_names}')

print(f'\n代码期望的Sheet名称:')
print(f'  {list(expected_sheets)}')

print('\n' + '=' * 60)
print('问题分析')
print('=' * 60)

f1_sheets = set(f1.sheet_names)
f2_sheets = set(f2.sheet_names)

print(f'\n2025-7-2.xlsx: Sheet名称 {"匹配" if f1_sheets == expected_sheets else "不匹配"}')
print(f'\n2025-7-3.xlsx: Sheet名称 {"匹配" if f2_sheets == expected_sheets else "不匹配"}')

if f1_sheets != expected_sheets:
    missing = expected_sheets - f1_sheets
    extra = f1_sheets - expected_sheets
    if missing:
        print(f'  [缺少]: {missing}')
    if extra:
        print(f'  [多余]: {extra}')

print('\n' + '=' * 60)
print('结论')
print('=' * 60)
print('\n失败原因: 2025-7-2.xlsx 的 Sheet 名称与代码期望不符')
print('  - 失败文件使用: "总分", "语文", "数学", "英语", "科学", "道德"')
print('  - 期望名称:     "总",  "语",  "数",  "英",  "科",  "社"')
