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
        <el-button type="success" @click="showImportDialogFunc">
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

    <!-- 视图模式选择 -->
    <div class="view-mode-selector">
      <el-radio-group v-model="viewMode" @change="handleViewModeChange">
        <el-radio-button value="class">按班级查看</el-radio-button>
        <el-radio-button value="all">查看全部学生</el-radio-button>
      </el-radio-group>
    </div>

    <!-- 按班级查看模式 -->
    <div v-if="viewMode === 'class'" class="class-view">
      <!-- 班级选择器 -->
      <div class="class-selector">
        <el-row :gutter="20">
          <el-col :span="8">
            <el-select v-model="selectedClassId" placeholder="请选择班级" @change="handleClassChange" size="large"
              style="width: 100%">
              <el-option v-for="classItem in classList" :key="classItem.id"
                :label="`${classItem.name} (${classItem.student_count}人)`" :value="classItem.id" />
            </el-select>
          </el-col>
          <el-col :span="4">
            <el-button @click="refreshClasses" icon="Refresh">刷新班级</el-button>
          </el-col>
        </el-row>
      </div>

      <!-- 选中班级的学生列表 -->
      <div v-if="selectedClassId" class="class-students">
        <div class="class-info">
          <h3>{{ selectedClassName }} - 学生列表</h3>
          <span class="student-count">共 {{ classStudentTotal }} 名学生</span>
        </div>

        <!-- 搜索栏 -->
        <div class="search-bar">
          <el-input v-model="classSearchKeyword" placeholder="在当前班级中搜索学生姓名、学号" @keyup.enter="searchClassStudents"
            clearable style="width: 300px">
            <template #append>
              <el-button @click="searchClassStudents" icon="Search" />
            </template>
          </el-input>
        </div>

        <!-- 学生表格组件 -->
        <StudentTable :students="classStudentList" :loading="classLoading" :total="classStudentTotal"
          :current-page="classCurrentPage" :page-size="classPageSize" :show-class-column="false"
          :show-score-columns="true" :class-list="classList" @edit-student="editStudent" @delete-student="deleteStudent"
          @page-change="handleClassPageChange" @size-change="handleClassSizeChange" @sort-change="handleClassSortChange"
          @batch-edit="handleBatchEdit" @batch-delete="handleBatchDelete" @refresh="loadClassStudents" />
      </div>

      <!-- 未选择班级时的提示 -->
      <div v-else class="no-class-selected">
        <el-empty description="请选择一个班级查看学生列表" />
      </div>
    </div>

    <!-- 查看全部学生模式 -->
    <div v-else class="all-students-view">
      <!-- 搜索栏 -->
      <div class="search-bar">
        <el-row :gutter="20">
          <el-col :span="8">
            <el-input v-model="allSearchKeyword" placeholder="搜索学生姓名、学号" @keyup.enter="searchAllStudents" clearable>
              <template #append>
                <el-button @click="searchAllStudents" icon="Search" />
              </template>
            </el-input>
          </el-col>
          <el-col :span="6">
            <el-select v-model="allClassFilter" placeholder="筛选班级" @change="searchAllStudents" clearable>
              <el-option v-for="classItem in classList" :key="classItem.id" :label="classItem.name"
                :value="classItem.name" />
            </el-select>
          </el-col>
        </el-row>
      </div>

      <!-- 学生表格组件 -->
      <StudentTable :students="allStudentList" :loading="allLoading" :total="allStudentTotal"
        :current-page="allCurrentPage" :page-size="allPageSize" :show-class-column="true" :show-score-columns="true"
        :class-list="classList" @edit-student="editStudent" @delete-student="deleteStudent"
        @page-change="handleAllPageChange" @size-change="handleAllSizeChange" @sort-change="handleAllSortChange"
        @batch-edit="handleBatchEdit" @batch-delete="handleBatchDelete" @refresh="loadAllStudents" />
    </div>

    <!-- 添加/编辑学生对话框 -->
    <el-dialog v-model="showStudentDialog" :title="isEditing ? '编辑学生' : '添加学生'" width="800px">
      <el-form ref="studentFormRef" :model="studentForm" :rules="studentRules" label-width="120px">
        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="学号" prop="student_id">
              <el-input v-model="studentForm.student_id" :disabled="isEditing" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="姓名" prop="name">
              <el-input v-model="studentForm.name" />
            </el-form-item>
          </el-col>
        </el-row>

        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="性别" prop="gender">
              <el-select v-model="studentForm.gender" placeholder="请选择性别">
                <el-option label="男" value="male" />
                <el-option label="女" value="female" />
                <el-option label="其他" value="other" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="年龄" prop="age">
              <el-input-number v-model="studentForm.age" :min="10" :max="100" />
            </el-form-item>
          </el-col>
        </el-row>

        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="班级" prop="class_name">
              <el-select v-model="studentForm.class_id" placeholder="请选择班级">
                <el-option v-for="classItem in classList" :key="classItem.id" :label="classItem.name"
                  :value="classItem.id" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="手机号" prop="phone">
              <el-input v-model="studentForm.phone" />
            </el-form-item>
          </el-col>
        </el-row>

        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="邮箱" prop="email">
              <el-input v-model="studentForm.email" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="身份证号" prop="id_card">
              <el-input v-model="studentForm.id_card" @blur="handleIdCardChange" placeholder="输入身份证号自动计算年龄和性别" />
            </el-form-item>
          </el-col>
        </el-row>

        <el-form-item label="备注" prop="notes">
          <el-input v-model="studentForm.notes" type="textarea" :rows="3" />
        </el-form-item>
      </el-form>
      <template #footer>
        <span class="dialog-footer">
          <el-button @click="showStudentDialog = false">取消</el-button>
          <el-button type="primary" @click="submitStudent" :loading="submitting">
            {{ isEditing ? '更新' : '创建' }}
          </el-button>
        </span>
      </template>
    </el-dialog>

    <!-- Excel导入对话框 -->
    <el-dialog v-model="showImportDialog" title="Excel导入" width="600px">
      <div class="import-content">
        <el-alert title="导入说明" type="info" :closable="false" style="margin-bottom: 20px">
          <p>1. 请先下载Excel模板</p>
          <p>2. 按照模板格式填写学生信息</p>
          <p>3. 选择填写好的Excel文件进行导入</p>
        </el-alert>

        <el-upload ref="uploadRef" :auto-upload="false" :limit="1" accept=".xlsx,.xls" :on-change="handleFileChange"
          :file-list="fileList">
          <el-button type="primary">选择Excel文件</el-button>
          <template #tip>
            <div class="el-upload__tip">只能上传xlsx/xls文件，且不超过10MB</div>
          </template>
        </el-upload>
      </div>
      <template #footer>
        <span class="dialog-footer">
          <el-button @click="showImportDialog = false">取消</el-button>
          <el-button type="primary" @click="startImport" :disabled="!selectedFile">
            开始导入
          </el-button>
        </span>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { Download, Plus, Upload } from '@element-plus/icons-vue'
import axios from 'axios'
import { ElMessage, ElMessageBox } from 'element-plus'
import { computed, onMounted, reactive, ref } from 'vue'
import StudentTable from './StudentTable.vue'

// 视图模式
const viewMode = ref('class') // 'class' 或 'all'

// 班级相关数据
const classList = ref([])
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
const classSearchKeyword = ref('')

// 全部学生查看的数据
const allStudentList = ref([])
const allLoading = ref(false)
const allCurrentPage = ref(1)
const allPageSize = ref(20)
const allStudentTotal = ref(0)
const allSearchKeyword = ref('')
const allClassFilter = ref('')

// 对话框状态
const showStudentDialog = ref(false)
const showImportDialog = ref(false)
const isEditing = ref(false)
const submitting = ref(false)

// 表单数据
const studentForm = reactive({
  id: null,
  name: '',
  student_id: '',
  gender: '',
  age: null,
  class_id: null,
  phone: '',
  email: '',
  id_card: '',
  notes: ''
})

// 表单验证规则
const studentRules = {
  name: [
    { required: true, message: '请输入学生姓名', trigger: 'blur' }
  ],
  student_id: [
    { required: true, message: '请输入学号', trigger: 'blur' }
  ]
}

// 文件上传相关
const fileList = ref([])
const selectedFile = ref(null)
const uploadRef = ref(null)

const studentFormRef = ref(null)

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

// 获取班级学生列表
const fetchClassStudents = async () => {
  if (!selectedClassId.value) return

  classLoading.value = true
  try {
    const params = {
      page: classCurrentPage.value,
      page_size: classPageSize.value
    }

    if (classSearchKeyword.value) {
      params.search = classSearchKeyword.value
    }

    const response = await axios.get(`/api/v1/students/by-class/${selectedClassId.value}`, { params })

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

// 搜索班级学生
const searchClassStudents = () => {
  fetchClassStudents()
}

// 获取全部学生列表
const fetchAllStudents = async () => {
  allLoading.value = true
  try {
    const params = {
      page: allCurrentPage.value,
      page_size: allPageSize.value
    }

    if (allSearchKeyword.value) {
      params.search = allSearchKeyword.value
    }

    if (allClassFilter.value) {
      params.class_name = allClassFilter.value
    }

    const response = await axios.get('/api/v1/students', { params })

    if (response.data.success) {
      allStudentList.value = response.data.data
      allStudentTotal.value = response.data.pagination.total
    }
  } catch (error) {
    console.error('获取学生列表失败:', error)
    ElMessage.error('获取学生列表失败')
  } finally {
    allLoading.value = false
  }
}

// 搜索全部学生
const searchAllStudents = () => {
  allCurrentPage.value = 1
  fetchAllStudents()
}

// 重置全部学生搜索
const resetAllSearch = () => {
  allSearchKeyword.value = ''
  allClassFilter.value = ''
  allCurrentPage.value = 1
  fetchAllStudents()
}

// 分页处理
const handleClassSizeChange = (size) => {
  classPageSize.value = size
  classCurrentPage.value = 1
  fetchClassStudents()
}

const handleClassCurrentChange = (page) => {
  classCurrentPage.value = page
  fetchClassStudents()
}

const handleAllSizeChange = (size) => {
  allPageSize.value = size
  allCurrentPage.value = 1
  fetchAllStudents()
}

const handleAllCurrentChange = (page) => {
  allCurrentPage.value = page
  fetchAllStudents()
}

const handleClassPageChange = (page) => {
  classCurrentPage.value = page
  fetchClassStudents()
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

// 性别显示
const getGenderText = (gender) => {
  const genderMap = {
    'male': '男',
    'female': '女',
    'other': '其他'
  }
  return genderMap[gender] || gender
}

const getGenderTagType = (gender) => {
  const typeMap = {
    'male': 'primary',
    'female': 'success',
    'other': 'info'
  }
  return typeMap[gender] || 'info'
}

// 格式化日期
const formatDate = (dateString) => {
  if (!dateString) return ''
  const date = new Date(dateString)
  return date.toLocaleString('zh-CN')
}

// 显示添加学生对话框
const showAddDialog = () => {
  isEditing.value = false
  resetStudentForm()
  showStudentDialog.value = true
}

// 编辑学生
const editStudent = (student) => {
  isEditing.value = true
  Object.keys(studentForm).forEach(key => {
    studentForm[key] = student[key] || (typeof studentForm[key] === 'number' ? null : '')
  })
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

    if (response.data.success) {
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

// 提交学生表单
const submitStudent = async () => {
  if (!studentFormRef.value) return

  try {
    await studentFormRef.value.validate()

    submitting.value = true

    let response
    if (isEditing.value) {
      response = await axios.put(`/api/v1/students/${studentForm.id}`, studentForm)
    } else {
      response = await axios.post('/api/v1/students', studentForm)
    }

    if (response.data.success) {
      ElMessage.success(isEditing.value ? '更新成功' : '创建成功')
      showStudentDialog.value = false
      // 刷新当前列表
      if (viewMode.value === 'class' && selectedClassId.value) {
        fetchClassStudents()
      } else if (viewMode.value === 'all') {
        fetchAllStudents()
      }
    }
  } catch (error) {
    console.error('提交失败:', error)
    ElMessage.error('操作失败')
  } finally {
    submitting.value = false
  }
}

// 重置学生表单
const resetStudentForm = () => {
  Object.keys(studentForm).forEach(key => {
    studentForm[key] = typeof studentForm[key] === 'number' ? null : ''
  })
}

// 身份证号变化处理
const handleIdCardChange = () => {
  const idCard = studentForm.id_card
  if (!idCard) return

  // 简单的身份证号解析
  if (idCard.length === 18) {
    const birthYear = parseInt(idCard.substring(6, 10))
    const birthMonth = parseInt(idCard.substring(10, 12))
    const birthDay = parseInt(idCard.substring(12, 14))
    const genderCode = parseInt(idCard.substring(16, 17))

    // 计算年龄
    const today = new Date()
    const birthDate = new Date(birthYear, birthMonth - 1, birthDay)
    let age = today.getFullYear() - birthYear
    if (today.getMonth() < birthMonth - 1 || (today.getMonth() === birthMonth - 1 && today.getDate() < birthDay)) {
      age--
    }

    studentForm.age = age
    studentForm.gender = genderCode % 2 === 0 ? 'female' : 'male'
  }
}

// 文件处理
const handleFileChange = (file) => {
  selectedFile.value = file
  fileList.value = [file]
}

// 显示导入对话框
const showImportDialogFunc = () => {
  showImportDialog.value = true
}

// 开始导入
const startImport = async () => {
  if (!selectedFile.value) return

  const formData = new FormData()
  formData.append('file', selectedFile.value.raw)

  try {
    const response = await axios.post('/api/v1/students/import/excel', formData, {
      headers: {
        'Content-Type': 'multipart/form-data'
      }
    })

    if (response.data.success) {
      ElMessage.success('导入成功')
      showImportDialog.value = false
      // 刷新列表
      if (viewMode.value === 'class' && selectedClassId.value) {
        fetchClassStudents()
      } else if (viewMode.value === 'all') {
        fetchAllStudents()
      }
    }
  } catch (error) {
    console.error('导入失败:', error)
    ElMessage.error('导入失败')
  }
}

// 下载模板
const downloadTemplate = async () => {
  try {
    const response = await axios.get('/api/v1/students/template/excel', {
      responseType: 'blob'
    })

    const blob = new Blob([response.data])
    const url = window.URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = '学生信息模板.xlsx'
    a.click()
    window.URL.revokeObjectURL(url)

    ElMessage.success('模板下载成功')
  } catch (error) {
    console.error('下载模板失败:', error)
    ElMessage.error('下载模板失败')
  }
}

// 新增的方法
const handleBatchEdit = (data) => {
  console.log('批量编辑:', data)
  // 刷新当前视图
  if (viewMode.value === 'class') {
    fetchClassStudents()
  } else {
    fetchAllStudents()
  }
}

const handleBatchDelete = (studentIds) => {
  console.log('批量删除:', studentIds)
  // 刷新当前视图
  if (viewMode.value === 'class') {
    fetchClassStudents()
  } else {
    fetchAllStudents()
  }
}

const loadClassStudents = () => {
  fetchClassStudents()
}

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
.student-management {
  padding: 20px;
}

.header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
}

.header h2 {
  margin: 0;
  color: #333;
}

.actions {
  display: flex;
  gap: 10px;
}

.view-mode-selector {
  margin-bottom: 20px;
}

.class-selector {
  margin-bottom: 20px;
}

.class-info {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 15px;
}

.class-info h3 {
  margin: 0;
  color: #333;
}

.student-count {
  color: #666;
  font-size: 14px;
}

.search-bar {
  margin-bottom: 20px;
}

.pagination {
  margin-top: 20px;
  display: flex;
  justify-content: center;
}

.no-class-selected {
  text-align: center;
  padding: 50px;
}

.import-content {
  padding: 20px 0;
}

.dialog-footer {
  display: flex;
  gap: 10px;
}
</style>