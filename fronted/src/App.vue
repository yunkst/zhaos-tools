<script setup lang="ts">
import { Calendar, DataBoard, Key, Refresh, School, User, Document, EditPen } from '@element-plus/icons-vue'
import { computed, onMounted } from 'vue'
import { useRoute } from 'vue-router'

const route = useRoute()

const appName = '赵老师的工具箱'

// 当前页面标题
const currentPageTitle = computed(() => {
  return route.meta?.title || '首页'
})

// 刷新数据
const refreshData = () => {
  window.location.reload()
}

onMounted(() => {
  console.log('应用已启动')
})
</script>

<template>
  <div id="app">
    <el-container class="app-container">
      <!-- 侧边栏 -->
      <el-aside width="250px" class="sidebar">
        <div class="logo">
          <h2>{{ appName }}</h2>
        </div>
        <el-menu :default-active="$route.path" class="sidebar-menu" background-color="#2c3e50" text-color="#ecf0f1"
          active-text-color="#3498db" router>
          <el-menu-item index="/dashboard">
            <el-icon>
              <DataBoard />
            </el-icon>
            <span>仪表盘</span>
          </el-menu-item>
          <el-menu-item index="/students">
            <el-icon>
              <User />
            </el-icon>
            <span>学生管理</span>
          </el-menu-item>
          <el-menu-item index="/classes">
            <el-icon>
              <School />
            </el-icon>
            <span>班级管理</span>
          </el-menu-item>
          <el-menu-item index="/checkins">
            <el-icon>
              <Calendar />
            </el-icon>
            <span>打卡管理</span>
          </el-menu-item>
          <el-menu-item index="/student-logs">
            <el-icon>
              <Document />
            </el-icon>
            <span>学生日志</span>
          </el-menu-item>
          <el-menu-item index="/teacher-diaries">
            <el-icon>
              <EditPen />
            </el-icon>
            <span>教师日记</span>
          </el-menu-item>
          <el-menu-item index="/ai-keys">
            <el-icon>
              <Key />
            </el-icon>
            <span>AI Key管理</span>
          </el-menu-item>
        </el-menu>
      </el-aside>

      <!-- 主内容区 -->
      <el-container>
        <!-- 头部 -->
        <el-header class="header">
          <div class="header-content">
            <h3>{{ currentPageTitle }}</h3>
            <div class="header-right">
              <el-button type="primary" @click="refreshData">
                <el-icon>
                  <Refresh />
                </el-icon>
                刷新
              </el-button>
            </div>
          </div>
        </el-header>

        <!-- 主内容 -->
        <el-main class="main-content">
          <router-view />
        </el-main>
      </el-container>
    </el-container>
  </div>
</template>

<style scoped>
.app-container {
  height: 100vh;
}

.sidebar {
  background-color: #2c3e50;
  color: #ecf0f1;
}

.logo {
  padding: 20px;
  text-align: center;
  border-bottom: 1px solid #34495e;
}

.logo h2 {
  margin: 0;
  color: #3498db;
  font-size: 18px;
}

.sidebar-menu {
  border: none;
}

.sidebar-menu .el-menu-item {
  height: 50px;
  line-height: 50px;
}

.sidebar-menu .el-menu-item:hover {
  background-color: #34495e;
}

.header {
  background-color: #fff;
  border-bottom: 1px solid #e6e6e6;
  padding: 0 20px;
}

.header-content {
  display: flex;
  justify-content: space-between;
  align-items: center;
  height: 100%;
}

.header-content h3 {
  margin: 0;
  color: #2c3e50;
}

.header-right {
  display: flex;
  align-items: center;
  gap: 10px;
}

.main-content {
  background-color: #f5f5f5;
  padding: 20px;
  overflow-y: auto;
}

/* 全局样式重置 */
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

body {
  font-family: 'Helvetica Neue', Arial, sans-serif;
}

/* 卡片样式 */
.content-card {
  background: #fff;
  border-radius: 8px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  padding: 20px;
  margin-bottom: 20px;
}

/* 表格样式 */
.el-table {
  border-radius: 8px;
  overflow: hidden;
}

.el-table th {
  background-color: #f8f9fa;
  color: #495057;
  font-weight: 600;
}

/* 按钮样式 */
.el-button {
  border-radius: 6px;
}

/* 表单样式 */
.el-form-item {
  margin-bottom: 20px;
}

.el-input,
.el-select,
.el-textarea {
  border-radius: 6px;
}

/* 分页样式 */
.el-pagination {
  margin-top: 20px;
  text-align: center;
}

/* 响应式设计 */
@media (max-width: 768px) {
  .sidebar {
    width: 60px !important;
  }

  .logo h2 {
    display: none;
  }

  .sidebar-menu .el-menu-item span {
    display: none;
  }

  .header-content h3 {
    font-size: 16px;
  }

  .main-content {
    padding: 10px;
  }
}
</style>
