import pandas as pd
import json

def analyze_excel(filepath, name):
    result = {
        'name': name,
        'success': False,
        'sheets': [],
        'error': None
    }

    try:
        excel_file = pd.ExcelFile(filepath)
        sheets = excel_file.sheet_names
        result['sheet_names'] = sheets
        result['sheet_count'] = len(sheets)

        for sheet in sheets:
            df = pd.read_excel(filepath, sheet_name=sheet)
            sheet_info = {
                'name': sheet,
                'rows': len(df),
                'columns': len(df.columns),
                'column_names': list(df.columns),
                'has_data': len(df) > 0
            }

            # 获取前3行数据
            if len(df) > 0:
                sheet_info['preview'] = df.head(3).fillna('').to_dict('records')

            result['sheets'].append(sheet_info)

        result['success'] = True

    except Exception as e:
        result['error'] = str(e)

    return result

# 分析两个文件
file1 = analyze_excel(r'D:\myspace\teacher_tools\app\2025-7-2.xlsx', '2025-7-2.xlsx (失败)')
file2 = analyze_excel(r'D:\myspace\teacher_tools\app\2025-7-3.xlsx', '2025-7-3.xlsx (成功)')

# 打印结果
print('=' * 80)
print('EXCEL 文件分析结果')
print('=' * 80)

for f in [file1, file2]:
    print(f"\n文件: {f['name']}")
    print(f"状态: {'成功' if f['success'] else '失败'}")

    if f['success']:
        print(f"Sheet数量: {f['sheet_count']}")
        print(f"Sheet名称: {f['sheet_names']}")

        for sheet in f['sheets']:
            print(f"\n  Sheet: {sheet['name']}")
            print(f"    行数: {sheet['rows']}, 列数: {sheet['columns']}")
            print(f"    列名: {sheet['column_names']}")

            if not sheet['has_data']:
                print(f"    [警告] 该Sheet为空!")

            if sheet.get('preview'):
                print(f"    前3行预览:")
                for i, row in enumerate(sheet['preview'], 1):
                    print(f"      行{i}: {row}")
    else:
        print(f"错误: {f['error']}")

# 检查是否符合成绩导入要求
print('\n' + '=' * 80)
print('成绩导入格式检查')
print('=' * 80)

required_sheets = {'总', '语', '数', '英', '科', '社'}
required_columns = {'学号', '姓名', '总分', '名次', '系数'}

for f in [file1, file2]:
    print(f"\n文件: {f['name']}")

    if not f['success']:
        print("  [失败] 文件无法打开")
        continue

    # 检查Sheet名称
    sheet_names = set(f['sheet_names'])
    missing_sheets = required_sheets - sheet_names
    extra_sheets = sheet_names - required_sheets

    print(f"  Sheet检查:")
    if missing_sheets:
        print(f"    [缺少] {missing_sheets}")
    if extra_sheets:
        print(f"    [多余] {extra_sheets}")
    if not missing_sheets and not extra_sheets:
        print(f"    [通过] Sheet名称正确")

    # 检查每个Sheet的列
    for sheet in f['sheets']:
        cols = set(str(c).strip() for c in sheet['column_names'])
        missing_cols = required_columns - cols

        if missing_cols:
            print(f"  Sheet [{sheet['name']}]: 缺少列 {missing_cols}")
        elif sheet['rows'] == 0:
            print(f"  Sheet [{sheet['name']}]: 没有数据")
        else:
            print(f"  Sheet [{sheet['name']}]: 格式正确，有{sheet['rows']}行数据")
