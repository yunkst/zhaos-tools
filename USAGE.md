# 使用说明

## 快速启动

### 1. 环境准备

确保已安装依赖：
```bash
# 同步Python依赖
uv sync

# 安装前端依赖
cd fronted
yarn install
cd ..
```

### 2. 启动应用

#### 生产模式（推荐）
```bash
# 构建并启动应用
python run.py

# 或者强制重新构建前端
python run.py --build
```

#### 开发模式
```bash
# 启动开发模式（前端热重载）
python run.py --mode dev
```

#### 仅后端模式
```bash
# 仅启动后端，不启动前端
python run.py --no-frontend
```

### 3. 直接运行
```bash
# 直接运行主程序
python main.py
```

## 功能说明

### 主要功能

1. **学生档案管理**
   - 添加、编辑、删除学生信息
   - 支持姓名、学号、班级、联系方式等字段
   - 自动记录创建和更新时间

2. **打卡记录管理**
   - 记录学生打卡内容
   - 自动生成鼓励性回复
   - 支持按学生筛选查看记录

3. **自动回复生成**
   - 基于模板的智能回复
   - 支持自定义回复模板
   - 未来可集成Langflow实现AI回复

### API接口

前端可以通过以下接口与后端交互：

- `get_students()` - 获取学生列表
- `add_student(student_data)` - 添加学生
- `update_student(student_id, student_data)` - 更新学生信息
- `delete_student(student_id)` - 删除学生
- `get_check_in_records(student_id)` - 获取打卡记录
- `generate_auto_reply(content)` - 生成自动回复
- `get_system_info()` - 获取系统信息

### 配置说明

配置文件：`config.py`

主要配置项：
- 应用基本信息（名称、版本等）
- 数据库配置
- 窗口配置
- 前端路径配置
- 自动回复模板
- 日志配置

## 数据库结构

### 学生表 (students)
- id: 主键
- name: 姓名
- student_id: 学号（唯一）
- class_name: 班级
- contact_info: 联系方式
- notes: 备注
- created_at: 创建时间
- updated_at: 更新时间

### 打卡记录表 (check_in_records)
- id: 主键
- student_id: 学生学号（外键）
- check_in_date: 打卡日期
- content: 打卡内容
- auto_reply: 自动回复
- created_at: 创建时间

### 系统配置表 (system_config)
- key: 配置键
- value: 配置值
- description: 配置描述
- updated_at: 更新时间

## 开发说明

### 项目结构
```
zhaos-tools/
├── main.py          # 主程序
├── config.py        # 配置文件
├── run.py           # 启动脚本
├── fronted/         # 前端项目
├── .cursor/rules/   # Cursor规则
└── README.md        # 项目说明
```

### 开发规则

1. **Python包管理**
   - 使用 `uv add <package>` 添加依赖
   - 使用 `uv remove <package>` 移除依赖
   - 不要直接修改 `pyproject.toml`

2. **临时文件管理**
   - 临时文件使用 `temp_`、`test_`、`tmp_` 前缀
   - 使用完毕后及时删除
   - 在代码中标注临时文件用途

### 日志文件

应用运行时会生成日志文件：
- `zhaos-tools.log` - 应用日志
- 日志级别：INFO
- 包含时间戳、模块名、日志级别和消息

### 数据备份

- 数据库文件：`zhaos_tools.db`
- 建议定期备份数据库文件
- 可以配置自动备份（待实现）

## 故障排除

### 常见问题

1. **前端无法访问**
   - 检查前端是否已构建：`cd fronted && yarn build`
   - 检查前端依赖是否已安装：`cd fronted && yarn install`

2. **数据库错误**
   - 检查数据库文件权限
   - 查看日志文件获取详细错误信息

3. **端口冲突**
   - 开发模式下检查端口5173是否被占用
   - 修改 `config.py` 中的端口配置

### 获取帮助

查看启动脚本帮助：
```bash
python run.py --help
``` 