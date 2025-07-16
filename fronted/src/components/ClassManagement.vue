<template>
    <div class="class-management">
        <div class="header">
            <h2>班级管理</h2>
            <el-button type="primary" @click="showCreateDialog = true">
                <el-icon>
                    <Plus />
                </el-icon>
                新建班级
            </el-button>
        </div>

        <!-- 班级列表 -->
        <el-table :data="classes" v-loading="loading" stripe>
            <el-table-column prop="name" label="班级名称" width="200" />
            <el-table-column prop="grade" label="年级" width="120" />
            <el-table-column prop="teacher_name" label="班主任" width="150" />
            <el-table-column prop="student_count" label="学生人数" width="100" />
            <el-table-column prop="description" label="描述" show-overflow-tooltip />
            <el-table-column prop="created_at" label="创建时间" width="180">
                <template #default="scope">
                    {{ formatDate(scope.row.created_at) }}
                </template>
            </el-table-column>
            <el-table-column label="操作" width="200" fixed="right">
                <template #default="scope">
                    <el-button size="small" @click="editClass(scope.row)">编辑</el-button>
                    <el-button size="small" type="info" @click="viewStudents(scope.row)">查看学生</el-button>
                    <el-button size="small" type="danger" @click="deleteClass(scope.row)"
                        :disabled="scope.row.student_count > 0">
                        删除
                    </el-button>
                </template>
            </el-table-column>
        </el-table>

        <!-- 分页 -->
        <div class="pagination">
            <el-pagination :current-page="currentPage" :page-size="pageSize" :page-sizes="[10, 20, 50, 100]"
                :total="total" layout="total, sizes, prev, pager, next, jumper" @size-change="handleSizeChange"
                @current-change="handleCurrentChange" />
        </div>

        <!-- 创建/编辑班级对话框 -->
        <el-dialog v-model="showCreateDialog" :title="editingClass ? '编辑班级' : '新建班级'" width="500px">
            <el-form :model="classForm" :rules="classRules" ref="classFormRef" label-width="100px">
                <el-form-item label="班级名称" prop="name">
                    <el-input v-model="classForm.name" placeholder="请输入班级名称" />
                </el-form-item>
                <el-form-item label="年级" prop="grade">
                    <el-input v-model="classForm.grade" placeholder="请输入年级" />
                </el-form-item>
                <el-form-item label="班主任" prop="teacher_name">
                    <el-input v-model="classForm.teacher_name" placeholder="请输入班主任姓名" />
                </el-form-item>
                <el-form-item label="描述" prop="description">
                    <el-input v-model="classForm.description" type="textarea" :rows="3" placeholder="请输入班级描述" />
                </el-form-item>
            </el-form>
            <template #footer>
                <span class="dialog-footer">
                    <el-button @click="showCreateDialog = false">取消</el-button>
                    <el-button type="primary" @click="submitClass" :loading="submitting">
                        {{ editingClass ? '更新' : '创建' }}
                    </el-button>
                </span>
            </template>
        </el-dialog>

        <!-- 学生列表对话框 -->
        <el-dialog v-model="showStudentsDialog" :title="`${currentClass?.name} - 学生列表`" width="90%" top="5vh">
            <div class="students-dialog-content">
                <!-- 搜索栏 -->
                <div class="search-bar">
                    <el-input v-model="studentSearchKeyword" placeholder="搜索学生姓名、学号" @keyup.enter="searchStudents"
                        clearable style="width: 300px">
                        <template #append>
                            <el-button @click="searchStudents" icon="Search" />
                        </template>
                    </el-input>
                </div>

                <!-- 学生表格组件 -->
                <StudentTable :students="students" :loading="studentsLoading" :total="studentsTotal"
                    :current-page="studentsCurrentPage" :page-size="studentsPageSize" :show-class-column="false"
                    :show-score-columns="true" :class-list="classes" @edit-student="editStudent"
                    @delete-student="deleteStudent" @page-change="handleStudentsPageChange"
                    @size-change="handleStudentsSizeChange" @sort-change="handleStudentsSortChange"
                    @batch-edit="handleBatchEdit" @batch-delete="handleBatchDelete" @refresh="loadStudents" />
            </div>
        </el-dialog>

        <!-- 添加/编辑学生对话框 -->
        <el-dialog v-model="showStudentDialog" :title="editingStudent ? '编辑学生' : '添加学生'" width="800px">
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
                    <el-button type="primary" @click="submitStudent" :loading="studentSubmitting">
                        {{ editingStudent ? '更新' : '添加' }}
                    </el-button>
                </span>
            </template>
        </el-dialog>
    </div>
</template>

<script setup>
import { Plus } from '@element-plus/icons-vue'
import axios from 'axios'
import { ElMessage, ElMessageBox } from 'element-plus'
import { onMounted, reactive, ref } from 'vue'
import StudentTable from './StudentTable.vue'

// 响应式数据
const classes = ref([])
const loading = ref(false)
const submitting = ref(false)
const showCreateDialog = ref(false)
const editingClass = ref(null)
const currentPage = ref(1)
const pageSize = ref(20)
const total = ref(0)

// 学生相关数据
const showStudentsDialog = ref(false)
const showStudentDialog = ref(false)
const currentClass = ref(null)
const students = ref([])
const studentsLoading = ref(false)
const studentsCurrentPage = ref(1)
const studentsPageSize = ref(20)
const studentsTotal = ref(0)
const studentSearchKeyword = ref('')
const editingStudent = ref(null)
const studentSubmitting = ref(false)

// 表单数据
const classForm = reactive({
    name: '',
    grade: '',
    teacher_name: '',
    description: ''
})

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
const classRules = {
    name: [
        { required: true, message: '请输入班级名称', trigger: 'blur' },
        { min: 1, max: 100, message: '班级名称长度应在1-100个字符', trigger: 'blur' }
    ]
}

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

const classFormRef = ref(null)
const studentFormRef = ref(null)

// 获取班级列表
const fetchClasses = async () => {
    loading.value = true
    try {
        const response = await axios.get('/api/v1/classes', {
            params: {
                page: currentPage.value,
                page_size: pageSize.value
            }
        })

        if (response.data.success) {
            classes.value = response.data.data.classes
            total.value = response.data.data.total
        } else {
            ElMessage.error(response.data.message || '获取班级列表失败')
        }
    } catch (error) {
        console.error('获取班级列表失败:', error)
        ElMessage.error('获取班级列表失败')
    } finally {
        loading.value = false
    }
}

// 编辑班级
const editClass = (classItem) => {
    editingClass.value = classItem
    classForm.name = classItem.name
    classForm.grade = classItem.grade || ''
    classForm.teacher_name = classItem.teacher_name || ''
    classForm.description = classItem.description || ''
    showCreateDialog.value = true
}

// 查看学生
const viewStudents = (classItem) => {
    currentClass.value = classItem
    showStudentsDialog.value = true
    studentsCurrentPage.value = 1
    studentSearchKeyword.value = ''
    loadStudents()
}

// 加载学生列表
const loadStudents = async () => {
    if (!currentClass.value) return

    try {
        studentsLoading.value = true
        const params = {
            page: studentsCurrentPage.value,
            page_size: studentsPageSize.value
        }

        if (studentSearchKeyword.value) {
            params.search = studentSearchKeyword.value
        }

        const response = await axios.get(`/api/v1/students/by-class/${currentClass.value.id}`, { params })

        if (response.data.success) {
            students.value = response.data.data
            studentsTotal.value = response.data.pagination.total
        }
    } catch (error) {
        console.error('加载学生列表失败:', error)
        ElMessage.error('加载学生列表失败')
    } finally {
        studentsLoading.value = false
    }
}

// 搜索学生
const searchStudents = () => {
    studentsCurrentPage.value = 1
    loadStudents()
}

// 学生分页处理
const handleStudentsPageChange = (page) => {
    studentsCurrentPage.value = page
    loadStudents()
}

const handleStudentsSizeChange = (size) => {
    studentsPageSize.value = size
    studentsCurrentPage.value = 1
    loadStudents()
}

const handleStudentsSortChange = (sortInfo) => {
    console.log('学生排序:', sortInfo)
}

// 批量操作处理
const handleBatchEdit = (data) => {
    console.log('批量编辑:', data)
    loadStudents()
    fetchClasses() // 刷新班级列表以更新学生数量
}

const handleBatchDelete = (studentIds) => {
    console.log('批量删除:', studentIds)
    loadStudents()
    fetchClasses() // 刷新班级列表以更新学生数量
}

// 编辑学生
const editStudent = (student) => {
    editingStudent.value = student

    // 填充表单数据
    Object.keys(studentForm).forEach(key => {
        studentForm[key] = student[key] || (key === 'class_id' ? currentClass.value.id : (key === 'age' ? null : ''))
    })

    showStudentDialog.value = true
}

// 删除学生
const deleteStudent = async (studentId) => {
    try {
        await ElMessageBox.confirm('确定要删除这名学生吗？', '删除确认', {
            confirmButtonText: '确定',
            cancelButtonText: '取消',
            type: 'warning'
        })

        await axios.delete(`/api/v1/students/detail/${studentId}`)
        ElMessage.success('删除成功')

        loadStudents()
        fetchClasses() // 刷新班级列表以更新学生数量
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

        studentSubmitting.value = true

        const formData = { ...studentForm }
        formData.class_id = currentClass.value.id

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
        fetchClasses() // 刷新班级列表以更新学生数量
    } catch (error) {
        console.error('提交失败:', error)
        ElMessage.error('提交失败')
    } finally {
        studentSubmitting.value = false
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

// 删除班级
const deleteClass = async (classItem) => {
    if (classItem.student_count > 0) {
        ElMessage.warning('该班级还有学生，无法删除')
        return
    }

    try {
        await ElMessageBox.confirm(
            `确定要删除班级 "${classItem.name}" 吗？`,
            '确认删除',
            {
                confirmButtonText: '确定',
                cancelButtonText: '取消',
                type: 'warning'
            }
        )

        const response = await axios.delete(`/api/v1/classes/detail/${classItem.id}`)

        if (response.data.success) {
            ElMessage.success('删除班级成功')
            fetchClasses()
        } else {
            ElMessage.error(response.data.message || '删除班级失败')
        }
    } catch (error) {
        if (error !== 'cancel') {
            console.error('删除班级失败:', error)
            ElMessage.error('删除班级失败')
        }
    }
}

// 提交班级表单
const submitClass = async () => {
    if (!classFormRef.value) return

    try {
        await classFormRef.value.validate()

        submitting.value = true

        const data = {
            name: classForm.name,
            grade: classForm.grade || null,
            teacher_name: classForm.teacher_name || null,
            description: classForm.description || null
        }

        let response
        if (editingClass.value) {
            response = await axios.put(`/api/v1/classes/detail/${editingClass.value.id}`, data)
        } else {
            response = await axios.post('/api/v1/classes', data)
        }

        if (response.data.success) {
            ElMessage.success(editingClass.value ? '更新班级成功' : '创建班级成功')
            showCreateDialog.value = false
            resetForm()
            fetchClasses()
        } else {
            ElMessage.error(response.data.message || '操作失败')
        }
    } catch (error) {
        console.error('提交班级失败:', error)
        ElMessage.error('操作失败')
    } finally {
        submitting.value = false
    }
}

// 重置表单
const resetForm = () => {
    editingClass.value = null
    classForm.name = ''
    classForm.grade = ''
    classForm.teacher_name = ''
    classForm.description = ''
    if (classFormRef.value) {
        classFormRef.value.resetFields()
    }
}

// 分页处理
const handleSizeChange = (val) => {
    pageSize.value = val
    currentPage.value = 1
    fetchClasses()
}

const handleCurrentChange = (val) => {
    currentPage.value = val
    fetchClasses()
}

// 格式化日期
const formatDate = (dateString) => {
    if (!dateString) return ''
    const date = new Date(dateString)
    return date.toLocaleString('zh-CN')
}

// 监听对话框关闭
const handleDialogClose = () => {
    resetForm()
}

onMounted(() => {
    fetchClasses()
})
</script>

<style scoped>
.class-management {
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

.pagination {
    margin-top: 20px;
    display: flex;
    justify-content: center;
}

.dialog-footer {
    display: flex;
    gap: 10px;
}

.students-dialog-content {
    min-height: 400px;
}

.search-bar {
    margin-bottom: 20px;
}
</style>