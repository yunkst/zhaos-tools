import pandas as pd
import sys

try:
    sys.stdout.reconfigure(encoding='utf-8')
except:
    pass

# 读取 Excel 文件
df = pd.read_excel('708.xlsx')

print('表格形状:', df.shape)
print('总行数:', df.shape[0])
print('总列数:', df.shape[1])
print('\n' + '='*80)

print('\n当前列名 (共 {} 列):'.format(len(df.columns)))
for i, col in enumerate(df.columns):
    print(f'  列 {i+1}: {col}')

print('\n' + '='*80)
print('\n前3行数据预览:')
pd.set_option('display.max_columns', None)
pd.set_option('display.width', None)
pd.set_option('display.max_colwidth', 50)
print(df.head(3).to_string())

print('\n' + '='*80)
print('\n所有唯一的第一行值（判断实际的表头位置）:')
first_row = df.iloc[0]
for i, val in enumerate(first_row):
    if pd.notna(val):
        print(f'  列 {i+1}: {val}')
