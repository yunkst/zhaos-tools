<template>
  <el-dialog :model-value="visible" title="Excel导入" width="600px" @close="handleClose" @update:model-value="$emit('update:visible', $event)">
    <div class="import-content">
      <el-alert title="导入说明" type="info" :closable="false" style="margin-bottom: 20px">
        <p>1. 请先下载Excel模板</p>
        <p>2. 按照模板格式填写学生信息</p>
        <p>3. 选择填写好的Excel文件进行导入</p>
      </el-alert>

      <el-upload 
        ref="uploadRef" 
        :auto-upload="false" 
        :limit="1" 
        accept=".xlsx,.xls" 
        :on-change="handleFileChange"
        :file-list="fileList"
      >
        <el-button type="primary">选择Excel文件</el-button>
        <template #tip>
          <div class="el-upload__tip">只能上传xlsx/xls文件，且不超过10MB</div>
        </template>
      </el-upload>
    </div>
    
    <template #footer>
      <span class="dialog-footer">
        <el-button @click="handleClose">取消</el-button>
        <el-button type="primary" @click="startImport" :disabled="!selectedFile" :loading="importing">
          开始导入
        </el-button>
      </span>
    </template>
  </el-dialog>
</template>

<script setup>
import { ref } from 'vue'
import { ElMessage } from 'element-plus'
import axios from 'axios'

const props = defineProps({
  visible: {
    type: Boolean,
    default: false
  }
})

const emit = defineEmits(['update:visible', 'success'])

const uploadRef = ref(null)
const fileList = ref([])
const selectedFile = ref(null)
const importing = ref(false)

// 文件选择处理
const handleFileChange = (file) => {
  selectedFile.value = file
  fileList.value = [file]
}

// 开始导入
const startImport = async () => {
  if (!selectedFile.value) return

  const formData = new FormData()
  formData.append('file', selectedFile.value.raw)

  try {
    importing.value = true
    const response = await axios.post('/api/v1/students/import/excel', formData, {
      headers: {
        'Content-Type': 'multipart/form-data'
      }
    })

    if (response.data.code === 200) {
      ElMessage.success('导入成功')
      emit('success')
      handleClose()
    }
  } catch (error) {
    console.error('导入失败:', error)
    ElMessage.error('导入失败')
  } finally {
    importing.value = false
  }
}

// 关闭对话框
const handleClose = () => {
  emit('update:visible', false)
  fileList.value = []
  selectedFile.value = null
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

// 暴露下载模板方法
defineExpose({
  downloadTemplate
})
</script>

<style scoped>
@import '../assets/styles/components.css';
</style>