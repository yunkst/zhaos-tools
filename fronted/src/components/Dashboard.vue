<template>
  <div class="dashboard">
    <!-- 统计卡片 -->
    <el-row :gutter="20" class="stats-row">
      <el-col :span="6">
        <div class="stat-card">
          <div class="stat-icon students">
            <el-icon><User /></el-icon>
          </div>
          <div class="stat-content">
            <h3>{{ stats.totalStudents }}</h3>
            <p>学生总数</p>
          </div>
        </div>
      </el-col>
      <el-col :span="6">
        <div class="stat-card">
          <div class="stat-icon checkins">
            <el-icon><Calendar /></el-icon>
          </div>
          <div class="stat-content">
            <h3>{{ stats.totalCheckins }}</h3>
            <p>打卡总数</p>
          </div>
        </div>
      </el-col>
      <el-col :span="6">
        <div class="stat-card">
          <div class="stat-icon today">
            <el-icon><Clock /></el-icon>
          </div>
          <div class="stat-content">
            <h3>{{ stats.todayCheckins }}</h3>
            <p>今日打卡</p>
          </div>
        </div>
      </el-col>
      <el-col :span="6">
        <div class="stat-card">
          <div class="stat-icon reply">
            <el-icon><ChatDotRound /></el-icon>
          </div>
          <div class="stat-content">
            <h3>{{ stats.replyRate }}%</h3>
            <p>回复率</p>
          </div>
        </div>
      </el-col>
    </el-row>

    <!-- 主要内容区域 -->
    <el-row :gutter="20">
      <!-- 最近打卡记录 -->
      <el-col :span="14">
        <div class="content-card">
          <div class="card-header">
            <h4>最近打卡记录</h4>
            <el-button text @click="goToCheckins">查看全部</el-button>
          </div>
          <el-table :data="recentCheckins" style="width: 100%" v-loading="loading">
            <el-table-column prop="student_name" label="学生姓名" width="100" />
            <el-table-column prop="student_id" label="学号" width="120" />
            <el-table-column prop="content" label="打卡内容" show-overflow-tooltip />
            <el-table-column prop="check_in_date" label="打卡日期" width="120" />
            <el-table-column label="状态" width="80">
              <template #default="scope">
                <el-tag :type="scope.row.auto_reply ? 'success' : 'warning'" size="small">
                  {{ scope.row.auto_reply ? '已回复' : '未回复' }}
                </el-tag>
              </template>
            </el-table-column>
          </el-table>
        </div>
      </el-col>

      <!-- 活跃学生排行 -->
      <el-col :span="10">
        <div class="content-card">
          <div class="card-header">
            <h4>活跃学生排行</h4>
          </div>
          <div class="ranking-list">
            <div v-for="(student, index) in topStudents" :key="student.student_id" class="ranking-item">
              <div class="rank-badge" :class="getRankClass(index)">
                {{ index + 1 }}
              </div>
              <div class="student-info">
                <div class="student-name">{{ student.name || student.student_id }}</div>
                <div class="student-id">{{ student.student_id }}</div>
              </div>
              <div class="checkin-count">
                {{ student.checkin_count }}次
              </div>
            </div>
          </div>
        </div>
      </el-col>
    </el-row>

    <!-- 打卡趋势图 -->
    <el-row>
      <el-col :span="24">
        <div class="content-card">
          <div class="card-header">
            <h4>最近7天打卡趋势</h4>
          </div>
          <div class="trend-chart">
            <div v-for="item in trendData" :key="item.date" class="trend-item">
              <div class="trend-bar">
                <div class="bar" :style="{ height: getBarHeight(item.count) + 'px' }"></div>
              </div>
              <div class="trend-date">{{ formatDate(item.check_in_date) }}</div>
              <div class="trend-count">{{ item.count }}</div>
            </div>
          </div>
        </div>
      </el-col>
    </el-row>
  </div>
</template>

<script setup lang="ts">
import { Calendar, ChatDotRound, Clock, User } from '@element-plus/icons-vue'
import axios from 'axios'
import { onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'

const router = useRouter()

// 数据
const loading = ref(false)
const stats = ref({
  totalStudents: 0,
  totalCheckins: 0,
  todayCheckins: 0,
  replyRate: 0
})
const recentCheckins = ref([])
const topStudents = ref([])
const trendData = ref([])

// 获取统计数据
const fetchStats = async () => {
  try {
    loading.value = true
    
    // 获取学生总数
    const studentsRes = await axios.get('/api/v1/students?page=1&page_size=1')
    if (studentsRes.data.code === 200) {
      stats.value.totalStudents = studentsRes.data.data?.total || 0
    }
    
    // 获取打卡统计
    const checkinStatsRes = await axios.get('/api/v1/checkins/stats/summary')
    if (checkinStatsRes.data.success) {
      const checkinStats = checkinStatsRes.data.data
      stats.value.totalCheckins = checkinStats.basic_stats?.total_checkins || 0
      stats.value.todayCheckins = checkinStats.basic_stats?.today_checkins || 0
      stats.value.replyRate = Math.round((checkinStats.basic_stats?.reply_rate || 0) * 100)
      topStudents.value = checkinStats.student_ranking || []
      trendData.value = checkinStats.daily_stats || []
    }
    
    // 获取最近打卡记录
    const recentCheckinsRes = await axios.get('/api/v1/checkins?page=1&page_size=8')
    if (recentCheckinsRes.data.success) {
      recentCheckins.value = recentCheckinsRes.data.data || []
    }
    
  } catch (error) {
    console.error('获取统计数据失败:', error)
  } finally {
    loading.value = false
  }
}

// 跳转到打卡管理页面
const goToCheckins = () => {
  router.push('/checkins')
}

// 获取排名样式
const getRankClass = (index: number) => {
  if (index === 0) return 'gold'
  if (index === 1) return 'silver'
  if (index === 2) return 'bronze'
  return 'normal'
}

// 格式化日期
const formatDate = (dateStr: string) => {
  if (!dateStr) return ''
  const date = new Date(dateStr)
  return `${date.getMonth() + 1}/${date.getDate()}`
}

// 计算柱状图高度
const getBarHeight = (count: number) => {
  if (!count) return 0
  const maxCount = Math.max(...trendData.value.map(item => item.count))
  return Math.max(10, (count / maxCount) * 100)
}

onMounted(() => {
  fetchStats()
})
</script>

<style scoped>
.dashboard {
  padding: 0;
}

.stats-row {
  margin-bottom: 20px;
}

.stat-card {
  background: #fff;
  border-radius: 8px;
  padding: 20px;
  display: flex;
  align-items: center;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  transition: transform 0.2s;
}

.stat-card:hover {
  transform: translateY(-2px);
}

.stat-icon {
  width: 60px;
  height: 60px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-right: 15px;
  font-size: 24px;
  color: #fff;
}

.stat-icon.students {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}

.stat-icon.checkins {
  background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
}

.stat-icon.today {
  background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%);
}

.stat-icon.reply {
  background: linear-gradient(135deg, #43e97b 0%, #38f9d7 100%);
}

.stat-content h3 {
  margin: 0 0 5px 0;
  font-size: 28px;
  font-weight: bold;
  color: #2c3e50;
}

.stat-content p {
  margin: 0;
  color: #7f8c8d;
  font-size: 14px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
  padding-bottom: 10px;
  border-bottom: 1px solid #e6e6e6;
}

.card-header h4 {
  margin: 0;
  color: #2c3e50;
  font-size: 16px;
}

.ranking-list {
  max-height: 300px;
  overflow-y: auto;
}

.ranking-item {
  display: flex;
  align-items: center;
  padding: 12px 0;
  border-bottom: 1px solid #f0f0f0;
}

.ranking-item:last-child {
  border-bottom: none;
}

.rank-badge {
  width: 30px;
  height: 30px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: bold;
  color: #fff;
  margin-right: 15px;
  font-size: 14px;
}

.rank-badge.gold {
  background: linear-gradient(135deg, #ffd700 0%, #ffed4e 100%);
}

.rank-badge.silver {
  background: linear-gradient(135deg, #c0c0c0 0%, #e5e5e5 100%);
}

.rank-badge.bronze {
  background: linear-gradient(135deg, #cd7f32 0%, #d4a574 100%);
}

.rank-badge.normal {
  background: linear-gradient(135deg, #95a5a6 0%, #bdc3c7 100%);
}

.student-info {
  flex: 1;
}

.student-name {
  font-weight: 500;
  color: #2c3e50;
  margin-bottom: 2px;
}

.student-id {
  font-size: 12px;
  color: #7f8c8d;
}

.checkin-count {
  font-weight: bold;
  color: #3498db;
}

.trend-chart {
  display: flex;
  justify-content: space-around;
  align-items: flex-end;
  height: 200px;
  padding: 20px 0;
}

.trend-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  min-width: 60px;
}

.trend-bar {
  height: 120px;
  display: flex;
  align-items: flex-end;
  margin-bottom: 10px;
}

.bar {
  width: 30px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  border-radius: 4px 4px 0 0;
  transition: height 0.3s ease;
}

.trend-date {
  font-size: 12px;
  color: #7f8c8d;
  margin-bottom: 5px;
}

.trend-count {
  font-size: 14px;
  font-weight: bold;
  color: #2c3e50;
}

/* 响应式设计 */
@media (max-width: 768px) {
  .stats-row .el-col {
    margin-bottom: 15px;
  }
  
  .stat-card {
    padding: 15px;
  }
  
  .stat-icon {
    width: 50px;
    height: 50px;
    font-size: 20px;
  }
  
  .stat-content h3 {
    font-size: 24px;
  }
  
  .trend-chart {
    height: 150px;
  }
  
  .trend-bar {
    height: 80px;
  }
}
</style>