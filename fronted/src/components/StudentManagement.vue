<template>
  <div class="student-management">
    <!-- 顶部操作栏 -->
    <div class="header">
      <h2>学生管理</h2>
      <div class="actions">
        <el-button type="primary" @click="showAddDialog">
          <el-icon>
            <Plus />
          </el-icon>
          添加学生
        </el-button>
        <el-button type="success" @click="showImportDialog = true">
          <el-icon>
            <Upload />
          </el-icon>
          Excel导入
        </el-button>
        <el-button type="info" @click="downloadTemplate">
          <el-icon>
            <Download />
          </el-icon>
          下载模板
        </el-button>
      </div>
    </div>

    <!-- 搜索组件 -->
    <StudentSearch 
      ref="searchRef"
      :class-list="classList"
      @view-mode-change="handleViewModeChange"
      @class-change="handleClassChange"
      @refresh-classes="refreshClasses"
      @search-class-students="handleSearchClassStudents"
      @search-all-students="handleSearchAllStudents"
      @reset-all-search="handleResetAllSearch"
    />

    <!-- 按班级查看模式 -->
    <div v-if="viewMode === 'class'" class="class-view">
      <!-- 选中班级的学生列表 -->
      <div v-if="selectedClassId" class="class-students">
        <div class="class-info">
          <h3>{{ selectedClassName }} - 学生列表</h3>
          <span class="student-count">共 {{ classStudentTotal }} 名学生</span>
        </div>

        <!-- 学生表格组件 -->
        <StudentTable 
          :students="classStudentList" 
          :loading="classLoading" 
          :total="classStudentTotal"
          :current-page="classCurrentPage" 
          :page-size="classPageSize" 
          :show-class-column="false"
          :show-score-columns="true" 
          :class-list="classList" 
          @edit-student="editStudent" 
          @delete-student="deleteStudent"
          @page-change="handleClassPageChange" 
          @size-change="handleClassSizeChange" 
          @sort-change="handleClassSortChange"
          @batch-edit="handleBatchEdit" 
          @batch-delete="handleBatchDelete" 
          @refresh="loadClassStudents" 
        />
      </div>

      <!-- 未选择班级时的提示 -->
      <div v-else class="no-class-selected">
        <el-empty description="请选择一个班级查看学生列表" />
      </div>
    </div>

    <!-- 查看全部学生模式 -->
    <div v-else class="all-students-view">
      <!-- 学生表格组件 -->
      <StudentTable 
        :students="allStudentList" 
        :loading="allLoading" 
        :total="allStudentTotal"
        :current-page="allCurrentPage" 
        :page-size="allPageSize" 
        :show-class-column="true" 
        :show-score-columns="true"
        :class-list="classList" 
        @edit-student="editStudent" 
        @delete-student="deleteStudent"
        @page-change="handleAllPageChange" 
        @size-change="handleAllSizeChange" 
        @sort-change="handleAllSortChange"
        @batch-edit="handleBatchEdit" 
        @batch-delete="handleBatchDelete" 
        @refresh="loadAllStudents" 
      />
    </div>

    <!-- 学生表单组件 -->
    <StudentForm
      v-model:visible="showStudentDialog"
      :is-editing="isEditing"
      :student-data="currentStudent"
      :class-list="classList"
      @success="handleStudentFormSuccess"
    />

    <!-- 学生导入组件 -->
    <StudentImport
      ref="importRef"
      v-model:visible="showImportDialog"
      @success="handleImportSuccess"
    />
  </div>
</template>

<script setup>
import { Download, Plus, Upload } from '@element-plus/icons-vue'
import axios from 'axios'
import { ElMessage, ElMessageBox } from 'element-plus'
import { computed, onMounted, ref } from 'vue'
import StudentTable from './StudentTable.vue'
import StudentForm from './StudentForm.vue'
import StudentImport from './StudentImport.vue'
import StudentSearch from './StudentSearch.vue'

// 组件引用
const searchRef = ref(null)
const importRef = ref(null)

// 班级相关数据
const classList = ref([])

// 视图模式和选择状态
const viewMode = ref('class')
const selectedClassId = ref(null)
const selectedClassName = computed(() => {
  const classItem = classList.value.find(c => c.id === selectedClassId.value)
  return classItem ? classItem.name : ''
})

// 按班级查看的数据
const classStudentList = ref([])
const classLoading = ref(false)
const classCurrentPage = ref(1)
const classPageSize = ref(20)
const classStudentTotal = ref(0)

// 全部学生查看的数据
const allStudentList = ref([])
const allLoading = ref(false)
const allCurrentPage = ref(1)
const allPageSize = ref(20)
const allStudentTotal = ref(0)

// 对话框状态
const showStudentDialog = ref(false)
const showImportDialog = ref(false)
const isEditing = ref(false)
const currentStudent = ref({})

// 获取班级列表
const fetchClasses = async () => {
  try {
    const response = await axios.get('/api/v1/classes/all')
    if (response.data.success) {
      classList.value = response.data.data
    }
  } catch (error) {
    console.error('获取班级列表失败:', error)
    ElMessage.error('获取班级列表失败')
  }
}

// 刷新班级列表
const refreshClasses = () => {
  fetchClasses()
}

// 视图模式切换
const handleViewModeChange = (mode) => {
  viewMode.value = mode
  if (mode === 'class') {
    selectedClassId.value = null
    classStudentList.value = []
  } else {
    fetchAllStudents()
  }
}

// 班级选择变化
const handleClassChange = (classId) => {
  selectedClassId.value = classId
  if (classId) {
    classCurrentPage.value = 1
    fetchClassStudents()
  } else {
    classStudentList.value = []
  }
}

// 搜索事件处理
const handleSearchClassStudents = (searchData) => {
  classCurrentPage.value = 1
  fetchClassStudents(searchData.keyword)
}

const handleSearchAllStudents = (searchData) => {
  allCurrentPage.value = 1
  fetchAllStudents(searchData.keyword, searchData.classFilter)
}

const handleResetAllSearch = () => {
  allCurrentPage.value = 1
  fetchAllStudents()
}

// 获取班级学生列表
const fetchClassStudents = async (searchKeyword = '') => {
  if (!selectedClassId.value) return

  classLoading.value = true
  try {
    const params = {
      page: classCurrentPage.value,
      page_size: classPageSize.value
    }

    if (searchKeyword) {
      params.search = searchKeyword
    }

    const response = await axios.get(`/api/v1/students/by-class-id/${selectedClassId.value}`, { params })

    if (response.data.success) {
      classStudentList.value = response.data.data
      classStudentTotal.value = response.data.pagination.total
    }
  } catch (error) {
    console.error('获取班级学生列表失败:', error)
    ElMessage.error('获取班级学生列表失败')
  } finally {
    classLoading.value = false
  }
}

// 获取全部学生列表
const fetchAllStudents = async (searchKeyword = '', classFilter = '') => {
  allLoading.value = true
  try {
    const params = {
      page: allCurrentPage.value,
      page_size: allPageSize.value
    }

    if (searchKeyword) {
      params.search = searchKeyword
    }

    if (classFilter) {
      params.class_name = classFilter
    }

    const response = await axios.get('/api/v1/students', { params })

    if (response.data.code === 200) {
      allStudentList.value = response.data.data.students
      allStudentTotal.value = response.data.data.total
    }
  } catch (error) {
    console.error('获取学生列表失败:', error)
    ElMessage.error('获取学生列表失败')
  } finally {
    allLoading.value = false
  }
}

// 分页处理
const handleClassSizeChange = (size) => {
  classPageSize.value = size
  classCurrentPage.value = 1
  fetchClassStudents()
}

const handleClassPageChange = (page) => {
  classCurrentPage.value = page
  fetchClassStudents()
}

const handleAllSizeChange = (size) => {
  allPageSize.value = size
  allCurrentPage.value = 1
  fetchAllStudents()
}

const handleAllPageChange = (page) => {
  allCurrentPage.value = page
  fetchAllStudents()
}

const handleClassSortChange = (sortInfo) => {
  console.log('班级学生排序:', sortInfo)
}

const handleAllSortChange = (sortInfo) => {
  console.log('全部学生排序:', sortInfo)
}

// 显示添加学生对话框
const showAddDialog = () => {
  isEditing.value = false
  currentStudent.value = {}
  showStudentDialog.value = true
}

// 编辑学生
const editStudent = (student) => {
  isEditing.value = true
  currentStudent.value = { ...student }
  showStudentDialog.value = true
}

// 删除学生
const deleteStudent = async (studentId) => {
  try {
    await ElMessageBox.confirm('确定要删除这个学生吗？', '确认删除', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning'
    })

    const response = await axios.delete(`/api/v1/students/${studentId}`)

    if (response.data.code === 200) {
      ElMessage.success('删除成功')
      // 刷新当前列表
      if (viewMode.value === 'class' && selectedClassId.value) {
        fetchClassStudents()
      } else if (viewMode.value === 'all') {
        fetchAllStudents()
      }
    }
  } catch (error) {
    if (error !== 'cancel') {
      console.error('删除失败:', error)
      ElMessage.error('删除失败')
    }
  }
}

// 学生表单成功回调
const handleStudentFormSuccess = () => {
  // 刷新当前列表
  if (viewMode.value === 'class' && selectedClassId.value) {
    fetchClassStudents()
  } else if (viewMode.value === 'all') {
    fetchAllStudents()
  }
}

// 导入成功回调
const handleImportSuccess = () => {
  // 刷新列表
  if (viewMode.value === 'class' && selectedClassId.value) {
    fetchClassStudents()
  } else if (viewMode.value === 'all') {
    fetchAllStudents()
  }
}

// 下载模板
const downloadTemplate = () => {
  // 创建模板数据
  const templateData = [
    {
      '学号': 'S001',
      '姓名': '张三',
      '性别': '男',
      '年龄': 18,
      '班级': '计算机1班',
      '电话': '13800138000',
      '邮箱': 'zhangsan@example.com'
    }
  ]
  
  // 这里可以实现Excel下载逻辑
  ElMessage.info('模板下载功能开发中')
}

// 批量编辑学生
const handleBatchEdit = (selectedStudents) => {
  if (selectedStudents.length === 0) {
    ElMessage.warning('请选择要编辑的学生')
    return
  }
  ElMessage.info('批量编辑功能开发中')
}

// 批量删除学生
const handleBatchDelete = async (selectedStudents) => {
  if (selectedStudents.length === 0) {
    ElMessage.warning('请选择要删除的学生')
    return
  }
  
  try {
    await ElMessageBox.confirm(`确定要删除选中的 ${selectedStudents.length} 个学生吗？`, '确认删除', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning'
    })
    
    const studentIds = selectedStudents.map(student => student.id)
    const response = await axios.delete('/api/v1/students/batch', {
      data: { student_ids: studentIds }
    })
    
    if (response.data.code === 200) {
      ElMessage.success('批量删除成功')
      // 刷新当前列表
      if (viewMode.value === 'class' && selectedClassId.value) {
        fetchClassStudents()
      } else if (viewMode.value === 'all') {
        fetchAllStudents()
      }
    }
  } catch (error) {
    if (error !== 'cancel') {
      console.error('批量删除失败:', error)
      ElMessage.error('批量删除失败')
    }
  }
}

// 加载班级学生列表（用于刷新）
const loadClassStudents = () => {
  if (selectedClassId.value) {
    fetchClassStudents()
  }
}

// 加载全部学生列表（用于刷新）
const loadAllStudents = () => {
  fetchAllStudents()
}

// 组件挂载时初始化
onMounted(() => {
  fetchClasses()
  if (viewMode.value === 'all') {
    fetchAllStudents()
  }
})
</script>

<style scoped>
@import '../assets/styles/components.css';

.student-management {
  @apply management-container;
}

.header {
  @apply management-header;
}

.pagination {
  @apply management-pagination;
}
</style>