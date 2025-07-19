<template>
  <el-dialog :model-value="dialogVisible" :title="isEdit ? '编辑班级' : '新建班级'" width="500px" @close="handleClose" @update:model-value="$emit('update:dialogVisible', $event)">
    <el-form :model="form" :rules="rules" ref="formRef" label-width="100px">
      <el-form-item label="班级名称" prop="name">
        <el-input v-model="form.name" placeholder="请输入班级名称" />
      </el-form-item>
      <el-form-item label="年级" prop="grade">
        <el-input v-model="form.grade" placeholder="请输入年级" />
      </el-form-item>
      <el-form-item label="班主任" prop="teacher_name">
        <el-input v-model="form.teacher_name" placeholder="请输入班主任姓名" />
      </el-form-item>
      <el-form-item label="描述" prop="description">
        <el-input v-model="form.description" type="textarea" :rows="3" placeholder="请输入班级描述" />
      </el-form-item>
    </el-form>
    <template #footer>
      <span class="dialog-footer">
        <el-button @click="handleClose">取消</el-button>
        <el-button type="primary" @click="handleSubmit" :loading="submitting">
          {{ isEdit ? '更新' : '创建' }}
        </el-button>
      </span>
    </template>
  </el-dialog>
</template>

<script setup>
import { ref, reactive, watch } from 'vue'
import { ElMessage } from 'element-plus'
import axios from 'axios'

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

const emit = defineEmits(['update:modelValue', 'success'])

const dialogVisible = ref(false)
const submitting = ref(false)
const formRef = ref(null)
const isEdit = ref(false)

const form = reactive({
  name: '',
  grade: '',
  teacher_name: '',
  description: ''
})

const rules = {
  name: [
    { required: true, message: '请输入班级名称', trigger: 'blur' },
    { min: 1, max: 100, message: '班级名称长度应在1-100个字符', trigger: 'blur' }
  ]
}

// 监听对话框显示状态
watch(() => props.modelValue, (val) => {
  dialogVisible.value = val
  if (val && props.classData) {
    isEdit.value = true
    Object.assign(form, {
      name: props.classData.name || '',
      grade: props.classData.grade || '',
      teacher_name: props.classData.teacher_name || '',
      description: props.classData.description || ''
    })
  } else if (val) {
    isEdit.value = false
    resetForm()
  }
})

// 监听内部对话框状态变化
watch(dialogVisible, (val) => {
  emit('update:modelValue', val)
})

// 提交表单
const handleSubmit = async () => {
  if (!formRef.value) return

  try {
    await formRef.value.validate()
    submitting.value = true

    const data = {
      name: form.name,
      grade: form.grade || null,
      teacher_name: form.teacher_name || null,
      description: form.description || null
    }

    let response
    if (isEdit.value && props.classData) {
      response = await axios.put(`/api/v1/classes/detail/${props.classData.id}`, data)
    } else {
      response = await axios.post('/api/v1/classes', data)
    }

    if (response.data.success) {
      ElMessage.success(isEdit.value ? '更新班级成功' : '创建班级成功')
      handleClose()
      emit('success')
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

// 关闭对话框
const handleClose = () => {
  dialogVisible.value = false
  resetForm()
}

// 重置表单
const resetForm = () => {
  Object.assign(form, {
    name: '',
    grade: '',
    teacher_name: '',
    description: ''
  })
  if (formRef.value) {
    formRef.value.resetFields()
  }
}
</script>

<style scoped>
@import '../assets/styles/components.css';
</style>