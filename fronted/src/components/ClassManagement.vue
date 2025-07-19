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
            <el-table-column prop="description" label="描述"  show-overflow-tooltip />
            <el-table-column prop="created_at" label="创建时间" width="180">
                <template #default="scope">
                    {{ formatDate(scope.row.created_at) }}
                </template>
            </el-table-column>
            <el-table-column label="操作" width="180" fixed="right">
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

        <!-- 学生管理对话框 -->
        <ClassStudentManagement 
            v-model="showStudentsDialog" 
            :class-data="currentClass"
            @student-updated="fetchClasses"
        />


    </div>
</template>

<script setup>
import { Plus } from '@element-plus/icons-vue'
import axios from 'axios'
import { ElMessage, ElMessageBox } from 'element-plus'
import { onMounted, reactive, ref } from 'vue'
import ClassStudentManagement from './ClassStudentManagement.vue'

// 响应式数据
const classes = ref([])
const loading = ref(false)
const submitting = ref(false)
const showCreateDialog = ref(false)
const editingClass = ref(null)
const currentPage = ref(1)
const pageSize = ref(20)
const total = ref(0)

// 学生管理对话框
const showStudentsDialog = ref(false)
const currentClass = ref(null)

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

const classFormRef = ref(null)

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
@import '@/assets/styles/components.css';
</style>