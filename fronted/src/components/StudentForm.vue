<template>
  <el-dialog :model-value="visible" :title="isEditing ? '编辑学生' : '添加学生'" width="800px" @close="handleClose" @update:model-value="$emit('update:visible', $event)">
    <el-form ref="formRef" :model="form" :rules="rules" label-width="120px">
      <el-row :gutter="20">
        <el-col :span="12">
          <el-form-item label="学号" prop="student_id">
            <el-input v-model="form.student_id" :disabled="isEditing" />
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="姓名" prop="name">
            <el-input v-model="form.name" />
          </el-form-item>
        </el-col>
      </el-row>

      <el-row :gutter="20">
        <el-col :span="12">
          <el-form-item label="性别" prop="gender">
            <el-select v-model="form.gender" placeholder="请选择性别">
              <el-option label="男" value="male" />
              <el-option label="女" value="female" />
              <el-option label="其他" value="other" />
            </el-select>
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="年龄" prop="age">
            <el-input-number v-model="form.age" :min="10" :max="100" />
          </el-form-item>
        </el-col>
      </el-row>

      <el-row :gutter="20">
        <el-col :span="12">
          <el-form-item label="班级" prop="class_name">
            <el-select v-model="form.class_id" placeholder="请选择班级">
              <el-option 
                v-for="classItem in classList" 
                :key="classItem.id" 
                :label="classItem.name"
                :value="classItem.id" 
              />
            </el-select>
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="手机号" prop="phone">
            <el-input v-model="form.phone" />
          </el-form-item>
        </el-col>
      </el-row>

      <el-row :gutter="20">
        <el-col :span="12">
          <el-form-item label="邮箱" prop="email">
            <el-input v-model="form.email" />
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="身份证号" prop="id_card">
            <el-input 
              v-model="form.id_card" 
              @blur="handleIdCardChange" 
              placeholder="输入身份证号自动计算年龄和性别" 
            />
          </el-form-item>
        </el-col>
      </el-row>

      <el-form-item label="备注" prop="notes">
        <el-input v-model="form.notes" type="textarea" :rows="3" />
      </el-form-item>
    </el-form>
    
    <template #footer>
      <span class="dialog-footer">
        <el-button @click="handleClose">取消</el-button>
        <el-button type="primary" @click="handleSubmit" :loading="submitting">
          {{ isEditing ? '更新' : '创建' }}
        </el-button>
      </span>
    </template>
  </el-dialog>
</template>

<script setup>
import { reactive, ref, watch } from 'vue'
import { ElMessage } from 'element-plus'
import axios from 'axios'

const props = defineProps({
  visible: {
    type: Boolean,
    default: false
  },
  isEditing: {
    type: Boolean,
    default: false
  },
  studentData: {
    type: Object,
    default: () => ({})
  },
  classList: {
    type: Array,
    default: () => []
  }
})

const emit = defineEmits(['update:visible', 'success'])

const formRef = ref(null)
const submitting = ref(false)

const form = reactive({
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

const rules = {
  name: [
    { required: true, message: '请输入学生姓名', trigger: 'blur' }
  ],
  student_id: [
    { required: true, message: '请输入学号', trigger: 'blur' }
  ]
}

// 重置表单
const resetForm = () => {
  Object.keys(form).forEach(key => {
    form[key] = typeof form[key] === 'number' ? null : ''
  })
}

// 监听学生数据变化
watch(() => props.studentData, (newData) => {
  if (newData && Object.keys(newData).length > 0) {
    Object.keys(form).forEach(key => {
      form[key] = newData[key] || (typeof form[key] === 'number' ? null : '')
    })
  } else {
    resetForm()
  }
}, { immediate: true, deep: true })

// 身份证号变化处理
const handleIdCardChange = () => {
  const idCard = form.id_card
  if (!idCard || idCard.length !== 18) return

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

  form.age = age
  form.gender = genderCode % 2 === 0 ? 'female' : 'male'
}

// 提交表单
const handleSubmit = async () => {
  if (!formRef.value) return

  try {
    await formRef.value.validate()
    submitting.value = true

    let response
    if (props.isEditing) {
      response = await axios.put(`/api/v1/students/${form.id}`, form)
    } else {
      response = await axios.post('/api/v1/students', form)
    }

    if (response.data.code === 200) {
      ElMessage.success(props.isEditing ? '更新成功' : '创建成功')
      emit('success')
      handleClose()
    }
  } catch (error) {
    console.error('提交失败:', error)
    ElMessage.error('操作失败')
  } finally {
    submitting.value = false
  }
}

// 关闭对话框
const handleClose = () => {
  emit('update:visible', false)
  resetForm()
}
</script>

<style scoped>
@import '../assets/styles/components.css';
</style>