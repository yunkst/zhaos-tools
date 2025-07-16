<template>
    <div class="student-table">
        <!-- 批量操作工具栏 -->
        <div v-if="selectedStudents.length > 0" class="batch-toolbar">
            <div class="batch-info">
                <span>已选择 {{ selectedStudents.length }} 名学生</span>
                <el-button size="small" @click="clearSelection">清空选择</el-button>
            </div>
            <div class="batch-actions">
                <el-button type="primary" size="small" @click="showBatchEditDialog">
                    <el-icon>
                        <Edit />
                    </el-icon>
                    批量编辑
                </el-button>
                <el-button type="danger" size="small" @click="showBatchDeleteDialog">
                    <el-icon>
                        <Delete />
                    </el-icon>
                    批量删除
                </el-button>
            </div>
        </div>

        <!-- 学生表格 -->
        <el-table ref="studentTableRef" :data="students" v-loading="loading" style="width: 100%"
            @selection-change="handleSelectionChange" @sort-change="handleSortChange">
            <!-- 选择列 -->
            <el-table-column type="selection" width="55" />

            <!-- 基本信息列 -->
            <el-table-column prop="name" label="姓名" width="120" sortable="custom" />
            <el-table-column prop="student_id" label="学号" width="150" sortable="custom" />
            <el-table-column prop="gender" label="性别" width="80">
                <template #default="scope">
                    <el-tag :type="getGenderTagType(scope.row.gender)" size="small">
                        {{ getGenderText(scope.row.gender) }}
                    </el-tag>
                </template>
            </el-table-column>
            <el-table-column prop="age" label="年龄" width="80" sortable="custom" />

            <!-- 班级信息 -->
            <el-table-column v-if="showClassColumn" prop="class_name" label="班级" width="120" />

            <!-- 联系信息 -->
            <el-table-column prop="phone" label="联系电话" width="130" />
            <el-table-column prop="email" label="邮箱" width="180" show-overflow-tooltip />

            <!-- 成绩信息（可选显示） -->
            <el-table-column v-if="showScoreColumns" prop="total_score" label="总分" width="100" sortable="custom" />

            <!-- 创建时间 -->
            <el-table-column prop="created_at" label="创建时间" width="180" sortable="custom">
                <template #default="scope">
                    {{ formatDate(scope.row.created_at) }}
                </template>
            </el-table-column>

            <!-- 操作列 -->
            <el-table-column label="操作" width="150" fixed="right">
                <template #default="scope">
                    <el-button size="small" @click="editStudent(scope.row)">编辑</el-button>
                    <el-button size="small" type="danger" @click="deleteStudent(scope.row.id)">删除</el-button>
                </template>
            </el-table-column>
        </el-table>

        <!-- 分页组件 -->
        <div class="pagination">
            <el-pagination :current-page="currentPage" :page-size="pageSize" :page-sizes="[10, 20, 50, 100]"
                :total="total" layout="total, sizes, prev, pager, next, jumper" @size-change="handleSizeChange"
                @current-change="handleCurrentChange" />
        </div>

        <!-- 批量编辑对话框 -->
        <el-dialog v-model="batchEditDialogVisible" title="批量编辑学生" width="500px">
            <el-form :model="batchEditForm" label-width="120px">
                <el-form-item label="班级">
                    <el-select v-model="batchEditForm.class_id" placeholder="请选择班级" clearable style="width: 100%">
                        <el-option v-for="classItem in classList" :key="classItem.id" :label="classItem.name"
                            :value="classItem.id" />
                    </el-select>
                </el-form-item>
                <el-form-item label="联系电话">
                    <el-input v-model="batchEditForm.phone" placeholder="留空表示不修改" />
                </el-form-item>
                <el-form-item label="邮箱">
                    <el-input v-model="batchEditForm.email" placeholder="留空表示不修改" />
                </el-form-item>
                <el-form-item label="备注">
                    <el-input v-model="batchEditForm.notes" type="textarea" placeholder="留空表示不修改" />
                </el-form-item>
            </el-form>
            <template #footer>
                <el-button @click="batchEditDialogVisible = false">取消</el-button>
                <el-button type="primary" @click="confirmBatchEdit" :loading="batchEditLoading">确定</el-button>
            </template>
        </el-dialog>

        <!-- 批量删除确认对话框 -->
        <el-dialog v-model="batchDeleteDialogVisible" title="批量删除确认" width="400px">
            <p>确定要删除选中的 {{ selectedStudents.length }} 名学生吗？</p>
            <p style="color: #f56c6c; font-size: 14px;">此操作不可撤销！</p>
            <template #footer>
                <el-button @click="batchDeleteDialogVisible = false">取消</el-button>
                <el-button type="danger" @click="confirmBatchDelete" :loading="batchDeleteLoading">确定删除</el-button>
            </template>
        </el-dialog>
    </div>
</template>

<script setup>
import { Delete, Edit } from '@element-plus/icons-vue'
import axios from 'axios'
import { ElMessage } from 'element-plus'
import { reactive, ref } from 'vue'

// Props
const props = defineProps({
    students: {
        type: Array,
        default: () => []
    },
    loading: {
        type: Boolean,
        default: false
    },
    total: {
        type: Number,
        default: 0
    },
    currentPage: {
        type: Number,
        default: 1
    },
    pageSize: {
        type: Number,
        default: 20
    },
    showClassColumn: {
        type: Boolean,
        default: true
    },
    showScoreColumns: {
        type: Boolean,
        default: false
    },
    classList: {
        type: Array,
        default: () => []
    }
})

// Emits
const emit = defineEmits([
    'edit-student',
    'delete-student',
    'page-change',
    'size-change',
    'sort-change',
    'batch-edit',
    'batch-delete',
    'refresh'
])

// 响应式数据
const studentTableRef = ref(null)
const selectedStudents = ref([])
const batchEditDialogVisible = ref(false)
const batchDeleteDialogVisible = ref(false)
const batchEditLoading = ref(false)
const batchDeleteLoading = ref(false)

// 批量编辑表单
const batchEditForm = reactive({
    class_id: null,
    phone: '',
    email: '',
    notes: ''
})

// 方法
const handleSelectionChange = (selection) => {
    selectedStudents.value = selection
}

const clearSelection = () => {
    studentTableRef.value.clearSelection()
    selectedStudents.value = []
}

const showBatchEditDialog = () => {
    // 重置表单
    Object.keys(batchEditForm).forEach(key => {
        batchEditForm[key] = key === 'class_id' ? null : ''
    })
    batchEditDialogVisible.value = true
}

const showBatchDeleteDialog = () => {
    batchDeleteDialogVisible.value = true
}

const confirmBatchEdit = async () => {
    try {
        batchEditLoading.value = true

        // 过滤掉空值
        const updateData = {}
        Object.keys(batchEditForm).forEach(key => {
            if (batchEditForm[key] !== null && batchEditForm[key] !== '') {
                updateData[key] = batchEditForm[key]
            }
        })

        if (Object.keys(updateData).length === 0) {
            ElMessage.warning('请至少选择一个要修改的字段')
            return
        }

        const studentIds = selectedStudents.value.map(s => s.id)

        // 调用批量更新API
        const response = await axios.patch('/api/v1/students/batch', {
            student_ids: studentIds,
            update_data: updateData
        })

        const result = response.data.data
        if (result.success_count > 0) {
            if (result.failed_count > 0) {
                ElMessage.warning(`编辑完成：成功 ${result.success_count} 名，失败 ${result.failed_count} 名`)
            } else {
                ElMessage.success(`成功批量编辑 ${result.success_count} 名学生`)
            }
        } else {
            ElMessage.error(`编辑失败：所有 ${result.failed_count} 名学生都编辑失败`)
        }

        batchEditDialogVisible.value = false
        clearSelection()
        emit('batch-edit', { studentIds, updateData })
        emit('refresh')

    } catch (error) {
        console.error('批量编辑失败:', error)
        ElMessage.error('批量编辑失败: ' + (error.response?.data?.message || error.message))
    } finally {
        batchEditLoading.value = false
    }
}

const confirmBatchDelete = async () => {
    try {
        batchDeleteLoading.value = true

        const studentIds = selectedStudents.value.map(s => s.id)

        // 调用批量删除API
        const response = await axios.delete('/api/v1/students/batch', {
            data: { student_ids: studentIds }
        })

        const result = response.data.data
        if (result.success_count > 0) {
            if (result.failed_count > 0) {
                ElMessage.warning(`删除完成：成功 ${result.success_count} 名，失败 ${result.failed_count} 名`)
            } else {
                ElMessage.success(`成功删除 ${result.success_count} 名学生`)
            }
        } else {
            ElMessage.error(`删除失败：所有 ${result.failed_count} 名学生都删除失败`)
        }

        batchDeleteDialogVisible.value = false
        clearSelection()
        emit('batch-delete', studentIds)
        emit('refresh')

    } catch (error) {
        console.error('批量删除失败:', error)
        ElMessage.error('批量删除失败: ' + (error.response?.data?.message || error.message))
    } finally {
        batchDeleteLoading.value = false
    }
}

const editStudent = (student) => {
    emit('edit-student', student)
}

const deleteStudent = (studentId) => {
    emit('delete-student', studentId)
}

const handleSizeChange = (size) => {
    emit('size-change', size)
}

const handleCurrentChange = (page) => {
    emit('page-change', page)
}

const handleSortChange = (sortInfo) => {
    emit('sort-change', sortInfo)
}

// 工具方法
const getGenderTagType = (gender) => {
    switch (gender) {
        case 'male': return 'primary'
        case 'female': return 'success'
        default: return 'info'
    }
}

const getGenderText = (gender) => {
    switch (gender) {
        case 'male': return '男'
        case 'female': return '女'
        default: return '未知'
    }
}

const formatDate = (dateString) => {
    if (!dateString) return ''
    return new Date(dateString).toLocaleString('zh-CN')
}

// 暴露方法给父组件
defineExpose({
    clearSelection,
    getSelectedStudents: () => selectedStudents.value
})
</script>

<style scoped>
.student-table {
    width: 100%;
}

.batch-toolbar {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 12px 16px;
    background: #f5f7fa;
    border: 1px solid #e4e7ed;
    border-radius: 4px;
    margin-bottom: 16px;
}

.batch-info {
    display: flex;
    align-items: center;
    gap: 12px;
    font-size: 14px;
    color: #606266;
}

.batch-actions {
    display: flex;
    gap: 8px;
}

.pagination {
    display: flex;
    justify-content: center;
    margin-top: 20px;
}

.el-table {
    border-radius: 4px;
}

.el-table th {
    background-color: #fafafa;
}
</style>