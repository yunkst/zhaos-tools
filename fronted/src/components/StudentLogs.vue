<template>
  <div class="student-logs">
    <el-card class="box-card">
      <template #header>
        <div class="card-header">
          <span>学生日志管理</span>
          <el-button type="primary" @click="showAddDialog = true">
            <el-icon><Plus /></el-icon>
            添加日志
          </el-button>
        </div>
      </template>

      <!-- 搜索栏 -->
      <div class="search-bar">
        <el-row :gutter="20">
          <el-col :span="8">
            <el-input
              v-model="searchKeyword"
              placeholder="搜索标题或内容"
              clearable
              @keyup.enter="searchLogs"
            >
              <template #append>
                <el-button @click="searchLogs">
                  <el-icon><Search /></el-icon>
                </el-button>
              </template>
            </el-input>
          </el-col>
          <el-col :span="6">
            <el-select
              v-model="selectedStudentId"
              placeholder="选择学生"
              clearable
              filterable
              @change="searchLogs"
            >
              <el-option
                v-for="student in students"
                :key="student.student_id"
                :label="`${student.name} (${student.student_id})`"
                :value="student.student_id"
              />
            </el-select>
          </el-col>
          <el-col :span="4">
            <el-button @click="resetSearch">重置</el-button>
          </el-col>
        </el-row>
      </div>

      <!-- 日志列表 -->
      <el-table
        :data="logs"
        style="width: 100%"
        v-loading="loading"
        empty-text="暂无日志数据"
      >
        <el-table-column prop="id" label="ID" width="80" />
        <el-table-column prop="title" label="标题" min-width="200" />
        <el-table-column prop="student_id" label="学生ID" width="120" />
        <el-table-column prop="content" label="内容" min-width="300">
          <template #default="scope">
            <div class="content-preview">
              {{ scope.row.content.length > 100 ? scope.row.content.substring(0, 100) + '...' : scope.row.content }}
            </div>
          </template>
        </el-table-column>
        <el-table-column prop="created_at" label="创建时间" width="180">
          <template #default="scope">
            {{ formatDateTime(scope.row.created_at) }}
          </template>
        </el-table-column>
        <el-table-column prop="updated_at" label="更新时间" width="180">
          <template #default="scope">
            {{ formatDateTime(scope.row.updated_at) }}
          </template>
        </el-table-column>
        <el-table-column label="操作" width="200" fixed="right">
          <template #default="scope">
            <el-button size="small" @click="viewLog(scope.row)">查看</el-button>
            <el-button size="small" type="primary" @click="editLog(scope.row)">编辑</el-button>
            <el-button size="small" type="danger" @click="deleteLog(scope.row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>

      <!-- 分页 -->
      <div class="pagination">
        <el-pagination
          v-model:current-page="currentPage"
          v-model:page-size="pageSize"
          :page-sizes="[10, 20, 50, 100]"
          :total="total"
          layout="total, sizes, prev, pager, next, jumper"
          @size-change="handleSizeChange"
          @current-change="handleCurrentChange"
        />
      </div>
    </el-card>

    <!-- 添加/编辑日志对话框 -->
    <el-dialog
      v-model="showAddDialog"
      :title="editingLog ? '编辑日志' : '添加日志'"
      width="600px"
      @close="resetForm"
    >
      <el-form
        ref="logFormRef"
        :model="logForm"
        :rules="logFormRules"
        label-width="80px"
      >
        <el-form-item label="学生" prop="student_id">
          <el-select
            v-model="logForm.student_id"
            placeholder="选择学生"
            filterable
            style="width: 100%"
          >
            <el-option
              v-for="student in students"
              :key="student.student_id"
              :label="`${student.name} (${student.student_id})`"
              :value="student.student_id"
            />
          </el-select>
        </el-form-item>
        <el-form-item label="标题" prop="title">
          <el-input v-model="logForm.title" placeholder="请输入日志标题" />
        </el-form-item>
        <el-form-item label="内容" prop="content">
          <el-input
            v-model="logForm.content"
            type="textarea"
            :rows="8"
            placeholder="请输入日志内容"
          />
        </el-form-item>
      </el-form>
      <template #footer>
        <span class="dialog-footer">
          <el-button @click="showAddDialog = false">取消</el-button>
          <el-button type="primary" @click="saveLog">保存</el-button>
        </span>
      </template>
    </el-dialog>

    <!-- 查看日志对话框 -->
    <el-dialog
      v-model="showViewDialog"
      title="查看日志"
      width="600px"
    >
      <div v-if="viewingLog">
        <el-descriptions :column="1" border>
          <el-descriptions-item label="标题">{{ viewingLog.title }}</el-descriptions-item>
          <el-descriptions-item label="学生ID">{{ viewingLog.student_id }}</el-descriptions-item>
          <el-descriptions-item label="创建时间">{{ formatDateTime(viewingLog.created_at) }}</el-descriptions-item>
          <el-descriptions-item label="更新时间">{{ formatDateTime(viewingLog.updated_at) }}</el-descriptions-item>
        </el-descriptions>
        <div class="content-section">
          <h4>内容：</h4>
          <div class="content-text">{{ viewingLog.content }}</div>
        </div>
      </div>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus, Search } from '@element-plus/icons-vue'
import axios from 'axios'

// 响应式数据
const loading = ref(false)
const logs = ref([])
const students = ref([])
const total = ref(0)
const currentPage = ref(1)
const pageSize = ref(20)
const searchKeyword = ref('')
const selectedStudentId = ref('')

// 对话框状态
const showAddDialog = ref(false)
const showViewDialog = ref(false)
const editingLog = ref(null)
const viewingLog = ref(null)

// 表单数据
const logForm = reactive({
  student_id: '',
  title: '',
  content: ''
})

// 表单验证规则
const logFormRules = {
  student_id: [{ required: true, message: '请选择学生', trigger: 'change' }],
  title: [{ required: true, message: '请输入标题', trigger: 'blur' }],
  content: [{ required: true, message: '请输入内容', trigger: 'blur' }]
}

const logFormRef = ref()

// 格式化日期时间
const formatDateTime = (dateTime) => {
  if (!dateTime) return ''
  return new Date(dateTime).toLocaleString('zh-CN')
}

// 加载学生列表
const loadStudents = async () => {
  try {
    const response = await axios.get('/api/v1/students')
    students.value = response.data.students || []
  } catch (error) {
    console.error('加载学生列表失败:', error)
    ElMessage.error('加载学生列表失败')
  }
}

// 加载日志列表
const loadLogs = async () => {
  loading.value = true
  try {
    let url = `/api/v1/student-logs/?page=${currentPage.value}&page_size=${pageSize.value}`
    
    // 如果有搜索条件，使用搜索接口
    if (searchKeyword.value || selectedStudentId.value) {
      url = `/api/v1/student-logs/search/?page=${currentPage.value}&page_size=${pageSize.value}`
      if (searchKeyword.value) {
        url += `&keyword=${encodeURIComponent(searchKeyword.value)}`
      }
      if (selectedStudentId.value) {
        url += `&student_id=${selectedStudentId.value}`
      }
    }
    
    const response = await axios.get(url)
    logs.value = response.data.logs || []
    total.value = response.data.total || 0
  } catch (error) {
    console.error('加载日志列表失败:', error)
    ElMessage.error('加载日志列表失败')
  } finally {
    loading.value = false
  }
}

// 搜索日志
const searchLogs = () => {
  currentPage.value = 1
  loadLogs()
}

// 重置搜索
const resetSearch = () => {
  searchKeyword.value = ''
  selectedStudentId.value = ''
  currentPage.value = 1
  loadLogs()
}

// 分页处理
const handleSizeChange = (val) => {
  pageSize.value = val
  currentPage.value = 1
  loadLogs()
}

const handleCurrentChange = (val) => {
  currentPage.value = val
  loadLogs()
}

// 查看日志
const viewLog = (log) => {
  viewingLog.value = log
  showViewDialog.value = true
}

// 编辑日志
const editLog = (log) => {
  editingLog.value = log
  logForm.student_id = log.student_id
  logForm.title = log.title
  logForm.content = log.content
  showAddDialog.value = true
}

// 删除日志
const deleteLog = async (log) => {
  try {
    await ElMessageBox.confirm(
      `确定要删除日志"${log.title}"吗？`,
      '确认删除',
      {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }
    )
    
    await axios.delete(`/api/v1/student-logs/${log.id}`)
    ElMessage.success('删除成功')
    loadLogs()
  } catch (error) {
    if (error !== 'cancel') {
      console.error('删除日志失败:', error)
      ElMessage.error('删除日志失败')
    }
  }
}

// 保存日志
const saveLog = async () => {
  try {
    await logFormRef.value.validate()
    
    if (editingLog.value) {
      // 编辑模式
      await axios.put(`/api/v1/student-logs/${editingLog.value.id}`, {
        title: logForm.title,
        content: logForm.content
      })
      ElMessage.success('更新成功')
    } else {
      // 新增模式
      await axios.post('/api/v1/student-logs/', logForm)
      ElMessage.success('添加成功')
    }
    
    showAddDialog.value = false
    resetForm()
    loadLogs()
  } catch (error) {
    console.error('保存日志失败:', error)
    ElMessage.error('保存日志失败')
  }
}

// 重置表单
const resetForm = () => {
  editingLog.value = null
  logForm.student_id = ''
  logForm.title = ''
  logForm.content = ''
  if (logFormRef.value) {
    logFormRef.value.resetFields()
  }
}

// 组件挂载时加载数据
onMounted(() => {
  loadStudents()
  loadLogs()
})
</script>

<style scoped>
.student-logs {
  padding: 20px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.search-bar {
  margin-bottom: 20px;
}

.content-preview {
  word-break: break-word;
  line-height: 1.4;
}

.pagination {
  margin-top: 20px;
  text-align: center;
}

.content-section {
  margin-top: 20px;
}

.content-section h4 {
  margin-bottom: 10px;
  color: #303133;
}

.content-text {
  padding: 12px;
  background-color: #f5f7fa;
  border-radius: 4px;
  line-height: 1.6;
  white-space: pre-wrap;
  word-break: break-word;
}

.dialog-footer {
  text-align: right;
}
</style>