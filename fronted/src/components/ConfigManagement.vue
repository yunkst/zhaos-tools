<template>
  <div class="config-management">
    <div class="header">
      <h2>系统配置管理</h2>
      <div class="actions">
        <el-button type="primary" @click="showAddDialog = true">
          <el-icon><Plus /></el-icon>
          添加配置
        </el-button>
        <el-button type="success" @click="initializeAIConfigs">
          <el-icon><Setting /></el-icon>
          初始化AI配置
        </el-button>
        <el-button @click="fetchConfigs">
          <el-icon><Refresh /></el-icon>
          刷新
        </el-button>
      </div>
    </div>

    <!-- 配置分组标签 -->
    <el-tabs v-model="activeTab" @tab-click="handleTabClick">
      <el-tab-pane label="全部配置" name="all">
        <ConfigTable 
          :configs="allConfigs" 
          @edit="handleEdit" 
          @delete="handleDelete"
        />
      </el-tab-pane>
      <el-tab-pane label="AI配置" name="ai">
        <ConfigTable 
          :configs="aiConfigs" 
          @edit="handleEdit" 
          @delete="handleDelete"
        />
      </el-tab-pane>
    </el-tabs>

    <!-- 添加/编辑配置对话框 -->
    <el-dialog 
      v-model="showAddDialog" 
      :title="editingConfig ? '编辑配置' : '添加配置'"
      width="500px"
    >
      <el-form 
        ref="configFormRef" 
        :model="configForm" 
        :rules="configRules" 
        label-width="100px"
      >
        <el-form-item label="配置键" prop="key">
          <el-input 
            v-model="configForm.key" 
            :disabled="!!editingConfig"
            placeholder="请输入配置键，如：OPENAI_API_KEY"
          />
        </el-form-item>
        <el-form-item label="配置值" prop="value">
          <el-input 
            v-model="configForm.value" 
            type="textarea" 
            :rows="3"
            placeholder="请输入配置值"
          />
        </el-form-item>
        <el-form-item label="描述" prop="description">
          <el-input 
            v-model="configForm.description" 
            type="textarea" 
            :rows="2"
            placeholder="请输入配置描述（可选）"
          />
        </el-form-item>
      </el-form>
      
      <template #footer>
        <el-button @click="showAddDialog = false">取消</el-button>
        <el-button type="primary" @click="handleSave" :loading="saving">
          {{ editingConfig ? '更新' : '创建' }}
        </el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus, Setting, Refresh } from '@element-plus/icons-vue'
import axios from 'axios'
import ConfigTable from './ConfigTable.vue'

interface Config {
  key: string
  value: string
  description?: string
  updated_at: string
}

const activeTab = ref('all')
const showAddDialog = ref(false)
const saving = ref(false)
const editingConfig = ref<Config | null>(null)

const allConfigs = ref<Config[]>([])
const aiConfigs = ref<Config[]>([])

const configForm = reactive({
  key: '',
  value: '',
  description: ''
})

const configRules = {
  key: [
    { required: true, message: '请输入配置键', trigger: 'blur' },
    { min: 1, max: 100, message: '长度在 1 到 100 个字符', trigger: 'blur' }
  ],
  value: [
    { required: true, message: '请输入配置值', trigger: 'blur' }
  ]
}

const configFormRef = ref()

// 获取所有配置
const fetchConfigs = async () => {
  try {
    const response = await axios.get('/api/v1/configs')
    if (response.data.success) {
      allConfigs.value = response.data.data.configs
    }
  } catch (error) {
    console.error('获取配置失败:', error)
    ElMessage.error('获取配置失败')
  }
}

// 获取AI配置
const fetchAIConfigs = async () => {
  try {
    const response = await axios.get('/api/v1/configs/groups/ai')
    if (response.data.success) {
      aiConfigs.value = response.data.data.configs
    }
  } catch (error) {
    console.error('获取AI配置失败:', error)
    ElMessage.error('获取AI配置失败')
  }
}

// 标签切换
const handleTabClick = (tab: any) => {
  if (tab.name === 'ai') {
    fetchAIConfigs()
  } else {
    fetchConfigs()
  }
}

// 编辑配置
const handleEdit = (config: Config) => {
  editingConfig.value = config
  configForm.key = config.key
  configForm.value = config.value
  configForm.description = config.description || ''
  showAddDialog.value = true
}

// 删除配置
const handleDelete = async (config: Config) => {
  try {
    await ElMessageBox.confirm(
      `确定要删除配置 "${config.key}" 吗？`,
      '确认删除',
      {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }
    )
    
    const response = await axios.delete(`/api/v1/configs/${config.key}`)
    if (response.data.success) {
      ElMessage.success('删除成功')
      fetchConfigs()
      if (activeTab.value === 'ai') {
        fetchAIConfigs()
      }
    }
  } catch (error: any) {
    if (error !== 'cancel') {
      console.error('删除配置失败:', error)
      ElMessage.error('删除配置失败')
    }
  }
}

// 保存配置
const handleSave = async () => {
  try {
    await configFormRef.value.validate()
    saving.value = true
    
    let response
    if (editingConfig.value) {
      // 更新配置
      response = await axios.put(`/api/v1/configs/${configForm.key}`, {
        value: configForm.value,
        description: configForm.description
      })
    } else {
      // 创建配置
      response = await axios.post('/api/v1/configs', configForm)
    }
    
    if (response.data.success) {
      ElMessage.success(editingConfig.value ? '更新成功' : '创建成功')
      showAddDialog.value = false
      resetForm()
      fetchConfigs()
      if (activeTab.value === 'ai') {
        fetchAIConfigs()
      }
    }
  } catch (error) {
    console.error('保存配置失败:', error)
    ElMessage.error('保存配置失败')
  } finally {
    saving.value = false
  }
}

// 重置表单
const resetForm = () => {
  configForm.key = ''
  configForm.value = ''
  configForm.description = ''
  editingConfig.value = null
  configFormRef.value?.resetFields()
}

// 初始化AI配置
const initializeAIConfigs = async () => {
  try {
    const defaultConfigs = [
      {
        key: 'AI_ENABLED',
        value: 'true',
        description: '是否启用AI功能'
      },
      {
        key: 'OPENAI_API_KEY',
        value: '',
        description: 'OpenAI API密钥'
      },
      {
        key: 'OPENAI_BASE_URL',
        value: 'https://api.openai.com/v1',
        description: 'OpenAI API基础URL'
      },
      {
        key: 'LANGFUSE_ENABLED',
        value: 'false',
        description: '是否启用Langfuse追踪'
      },
      {
        key: 'LANGFUSE_SECRET_KEY',
        value: '',
        description: 'Langfuse密钥'
      },
      {
        key: 'LANGFUSE_PUBLIC_KEY',
        value: '',
        description: 'Langfuse公钥'
      },
      {
        key: 'LANGFUSE_HOST',
        value: 'https://cloud.langfuse.com',
        description: 'Langfuse服务器地址'
      }
    ]
    
    const response = await axios.post('/api/v1/configs/batch', {
      configs: defaultConfigs
    })
    
    if (response.data.success) {
      ElMessage.success('AI配置初始化成功')
      fetchConfigs()
      fetchAIConfigs()
    }
  } catch (error) {
    console.error('初始化AI配置失败:', error)
    ElMessage.error('初始化AI配置失败')
  }
}

// 监听对话框关闭
const handleDialogClose = () => {
  resetForm()
}

onMounted(() => {
  fetchConfigs()
})
</script>

<style scoped>
.config-management {
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
  color: #303133;
}

.actions {
  display: flex;
  gap: 10px;
}
</style>