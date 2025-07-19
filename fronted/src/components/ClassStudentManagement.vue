<template>
  <el-dialog :model-value="dialogVisible" :title="`${classData?.name} - 学生列表`" width="90%" top="5vh" @close="handleClose" @update:model-value="$emit('update:dialogVisible', $event)">
    <div class="dialog-content">
      <!-- 搜索栏 -->
      <div class="search-bar">
        <el-input 
          v-model="searchKeyword" 
          placeholder="搜索学生姓名、学号" 
          @keyup.enter="handleSearch"
          clearable 
          class="search-input"
        >
          <template #append>
            <el-button @click="handleSearch" icon="Search" />
          </template>
        </el-input>
        <el-button type="primary" @click="showAddStudentDialog">
          <el-icon><Plus /></el-icon>
          添加学生
        </el-button>
      </div>

      <!-- 学生表格组件 -->
      <StudentTable 
        :students="students" 
        :loading="loading" 
        :total="total"
        :current-page="currentPage" 
        :page-size="pageSize" 
        :show-class-column="false"
        :show-score-columns="true" 
        :class-list="[classData]"
        @edit-student="handleEditStudent"
        @delete-student="handleDeleteStudent" 
        @page-change="handlePageChange"
        @size-change="handleSizeChange" 
        @sort-change="handleSortChange"
        @batch-edit="handleBatchEdit" 
        @batch-delete="handleBatchDelete" 
        @refresh="loadStudents" 
      />
    </div>

    <!-- 学生表单对话框 -->
    <el-dialog :model-value="showStudentDialog" :title="editingStudent ? '编辑学生' : '添加学生'" width="800px" @update:model-value="showStudentDialog = $event">
      <el-form :model="studentForm" :rules="studentRules" ref="studentFormRef" label-width="120px">
        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="姓名" prop="name">
              <el-input v-model="studentForm.name" placeholder="请输入学生姓名" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="学号" prop="student_id">
              <el-input v-model="studentForm.student_id" placeholder="请输入学号" />
            </el-form-item>
          </el-col>
        </el-row>

        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="身份证号" prop="id_card">
              <el-input v-model="studentForm.id_card" placeholder="请输入身份证号" @blur="handleIdCardChange" />
            </el-form-item>
          </el-col>
          <el-col :span="6">
            <el-form-item label="性别" prop="gender">
              <el-radio-group v-model="studentForm.gender">
                <el-radio value="male">男</el-radio>
                <el-radio value="female">女</el-radio>
              </el-radio-group>
            </el-form-item>
          </el-col>
          <el-col :span="6">
            <el-form-item label="年龄" prop="age">
              <el-input-number v-model="studentForm.age" :min="10" :max="100" placeholder="年龄" />
            </el-form-item>
          </el-col>
        </el-row>

        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="联系电话" prop="phone">
              <el-input v-model="studentForm.phone" placeholder="请输入联系电话" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="邮箱" prop="email">
              <el-input v-model="studentForm.email" placeholder="请输入邮箱" />
            </el-form-item>
          </el-col>
        </el-row>

        <el-form-item label="备注" prop="notes">
          <el-input v-model="studentForm.notes" type="textarea" :rows="3" placeholder="请输入备注信息" />
        </el-form-item>
      </el-form>
      <template #footer>
        <span class="dialog-footer">
          <el-button @click="showStudentDialog = false">取消</el-button>
          <el-button type="primary" @click="submitStudent" :loading="submitting">
            {{ editingStudent ? '更新' : '添加' }}
          </el-button>
        </span>
      </template>
    </el-dialog>
  </el-dialog>
</template>

<script setup>
import { ref, reactive, watch } from 'vue'
import { Plus } from '@element-plus/icons-vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import axios from 'axios'
import StudentTable from './StudentTable.vue'

const props = defineProps({
  modelValue: {
    type: Boolean,
    default: false
  },
  classData: {
    type: Object,
    default: null
  }
})

const emit = defineEmits(['update:modelValue', 'student-updated'])

const dialogVisible = ref(false)
const showStudentDialog = ref(false)
const loading = ref(false)
const submitting = ref(false)
const searchKeyword = ref('')
const editingStudent = ref(null)
const studentFormRef = ref(null)

// 学生列表数据
const students = ref([])
const currentPage = ref(1)
const pageSize = ref(20)
const total = ref(0)

// 学生表单数据
const studentForm = reactive({
  name: '',
  student_id: '',
  gender: null,
  age: null,
  phone: '',
  email: '',
  notes: '',
  id_card: '',
  class_id: null
})

// 表单验证规则
const studentRules = {
  name: [
    { required: true, message: '请输入学生姓名', trigger: 'blur' },
    { min: 1, max: 100, message: '姓名长度在1到100个字符', trigger: 'blur' }
  ],
  student_id: [
    { required: true, message: '请输入学号', trigger: 'blur' },
    { min: 1, max: 50, message: '学号长度在1到50个字符', trigger: 'blur' }
  ],
  phone: [
    { pattern: /^1[3-9]\d{9}$/, message: '请输入正确的手机号码', trigger: 'blur' }
  ],
  email: [
    { type: 'email', message: '请输入正确的邮箱地址', trigger: 'blur' }
  ]
}

// 监听对话框显示状态
watch(() => props.modelValue, (val) => {
  dialogVisible.value = val
  if (val && props.classData) {
    currentPage.value = 1
    searchKeyword.value = ''
    loadStudents()
  }
})

// 监听内部对话框状态变化
watch(dialogVisible, (val) => {
  emit('update:modelValue', val)
})

// 加载学生列表
const loadStudents = async () => {
  if (!props.classData) return

  try {
    loading.value = true
    const params = {
      page: currentPage.value,
      page_size: pageSize.value
    }

    if (searchKeyword.value) {
      params.search = searchKeyword.value
    }

    const response = await axios.get(`/api/v1/students/by-class-id/${props.classData.id}`, { params })

    if (response.data.success) {
      students.value = response.data.data
      total.value = response.data.pagination.total
    }
  } catch (error) {
    console.error('加载学生列表失败:', error)
    ElMessage.error('加载学生列表失败')
  } finally {
    loading.value = false
  }
}

// 搜索学生
const handleSearch = () => {
  currentPage.value = 1
  loadStudents()
}

// 分页处理
const handlePageChange = (page) => {
  currentPage.value = page
  loadStudents()
}

const handleSizeChange = (size) => {
  pageSize.value = size
  currentPage.value = 1
  loadStudents()
}

const handleSortChange = (sortInfo) => {
  console.log('学生排序:', sortInfo)
}

// 批量操作处理
const handleBatchEdit = (data) => {
  console.log('批量编辑:', data)
  loadStudents()
  emit('student-updated')
}

const handleBatchDelete = (studentIds) => {
  console.log('批量删除:', studentIds)
  loadStudents()
  emit('student-updated')
}

// 显示添加学生对话框
const showAddStudentDialog = () => {
  editingStudent.value = null
  resetStudentForm()
  showStudentDialog.value = true
}

// 编辑学生
const handleEditStudent = (student) => {
  editingStudent.value = student
  Object.keys(studentForm).forEach(key => {
    studentForm[key] = student[key] || (key === 'class_id' ? props.classData.id : (key === 'age' ? null : ''))
  })
  showStudentDialog.value = true
}

// 删除学生
const handleDeleteStudent = async (studentId) => {
  try {
    await ElMessageBox.confirm('确定要删除这名学生吗？', '删除确认', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning'
    })

    await axios.delete(`/api/v1/students/detail/${studentId}`)
    ElMessage.success('删除成功')

    loadStudents()
    emit('student-updated')
  } catch (error) {
    if (error !== 'cancel') {
      console.error('删除学生失败:', error)
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

    const formData = { ...studentForm }
    formData.class_id = props.classData.id

    if (editingStudent.value) {
      await axios.put(`/api/v1/students/${editingStudent.value.id}`, formData)
      ElMessage.success('更新成功')
    } else {
      await axios.post('/api/v1/students', formData)
      ElMessage.success('添加成功')
    }

    showStudentDialog.value = false
    resetStudentForm()
    loadStudents()
    emit('student-updated')
  } catch (error) {
    console.error('提交失败:', error)
    ElMessage.error('提交失败')
  } finally {
    submitting.value = false
  }
}

// 重置学生表单
const resetStudentForm = () => {
  editingStudent.value = null
  Object.keys(studentForm).forEach(key => {
    studentForm[key] = key === 'class_id' ? null : (key === 'age' ? null : '')
  })
  studentFormRef.value?.resetFields()
}

// 身份证号变化处理
const handleIdCardChange = () => {
  if (!studentForm.id_card) return

  const idCard = studentForm.id_card.trim()

  // 验证身份证号格式
  if (!/^[1-9]\d{5}(18|19|20)\d{2}(0[1-9]|1[0-2])(0[1-9]|[12]\d|3[01])\d{3}[\dXx]$/.test(idCard) &&
      !/^[1-9]\d{5}\d{2}(0[1-9]|1[0-2])(0[1-9]|[12]\d|3[01])\d{3}$/.test(idCard)) {
    return
  }

  try {
    let year, month, day

    if (idCard.length === 18) {
      // 18位身份证
      year = parseInt(idCard.substring(6, 10))
      month = parseInt(idCard.substring(10, 12))
      day = parseInt(idCard.substring(12, 14))

      // 性别判断（第17位，奇数为男，偶数为女）
      const genderCode = parseInt(idCard.substring(16, 17))
      studentForm.gender = genderCode % 2 === 1 ? 'male' : 'female'
    } else if (idCard.length === 15) {
      // 15位身份证
      year = 1900 + parseInt(idCard.substring(6, 8))
      month = parseInt(idCard.substring(8, 10))
      day = parseInt(idCard.substring(10, 12))

      // 性别判断（第15位，奇数为男，偶数为女）
      const genderCode = parseInt(idCard.substring(14, 15))
      studentForm.gender = genderCode % 2 === 1 ? 'male' : 'female'
    }

    // 验证日期有效性
    const birthDate = new Date(year, month - 1, day)
    if (birthDate.getFullYear() === year &&
        birthDate.getMonth() === month - 1 &&
        birthDate.getDate() === day) {

      // 计算年龄
      const today = new Date()
      let age = today.getFullYear() - year

      if (today.getMonth() < month - 1 ||
          (today.getMonth() === month - 1 && today.getDate() < day)) {
        age--
      }

      if (age >= 0 && age <= 150) {
        studentForm.age = age
      }
    }
  } catch (error) {
    console.error('解析身份证失败:', error)
  }
}

// 关闭对话框
const handleClose = () => {
  dialogVisible.value = false
}
</script>

<style scoped>
@import '../assets/styles/components.css';
</style>