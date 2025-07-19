<template>
  <div class="ai-key-management">
    <!-- 页面头部 -->
    <div class="content-card">
      <div class="header">
        <h2>AI Key 管理</h2>
        <div class="actions">
          <el-button type="primary" @click="showAddDialog = true">
            <el-icon><Plus /></el-icon>
            添加 AI Key
          </el-button>
          <el-button @click="fetchAIKeys">
            <el-icon><Refresh /></el-icon>
            刷新
          </el-button>
        </div>
      </div>
    </div>

    <!-- 筛选器 -->
    <div class="content-card">
      <el-row :gutter="20">
        <el-col :span="6">
          <el-select v-model="filterProvider" placeholder="选择服务商" clearable @change="fetchAIKeys">
            <el-option label="全部" value="" />
            <el-option 
              v-for="provider in providerTypes" 
              :key="provider.value" 
              :label="provider.label" 
              :value="provider.value" 
            />
          </el-select>
        </el-col>
        <el-col :span="6">
          <el-select v-model="filterActive" placeholder="选择状态" clearable @change="fetchAIKeys">
            <el-option label="全部" value="" />
            <el-option label="启用" :value="true" />
            <el-option label="禁用" :value="false" />
          </el-select>
        </el-col>
      </el-row>
    </div>

    <!-- AI Key 列表 -->
    <div class="content-card">
      <el-table :data="aiKeys" v-loading="loading" stripe>
        <el-table-column prop="name" label="Key名称" width="150" />
        <el-table-column prop="provider_type" label="服务商" width="120">
          <template #default="{ row }">
            <el-tag :type="getProviderTagType(row.provider_type)">
              {{ getProviderLabel(row.provider_type) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="api_key_masked" label="API Key" width="200" show-overflow-tooltip />
        <el-table-column prop="base_url" label="服务地址" min-width="200" show-overflow-tooltip />
        <el-table-column prop="description" label="描述" min-width="150" show-overflow-tooltip />
        <el-table-column prop="is_active" label="状态" width="80">
          <template #default="{ row }">
            <el-tag :type="row.is_active ? 'success' : 'danger'" size="small">
              {{ row.is_active ? '启用' : '禁用' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="created_at" label="创建时间" width="160">
          <template #default="{ row }">
            {{ formatDateTime(row.created_at) }}
          </template>
        </el-table-column>
        <el-table-column label="操作" width="200" fixed="right">
          <template #default="{ row }">
            <el-button type="primary" size="small" @click="viewDetail(row)">
              查看
            </el-button>
            <el-button type="warning" size="small" @click="editAIKey(row)">
              编辑
            </el-button>
            <el-button type="danger" size="small" @click="deleteAIKey(row)">
              删除
            </el-button>
          </template>
        </el-table-column>
      </el-table>
    </div>

    <!-- 添加/编辑对话框 -->
    <el-dialog 
      :title="editingKey ? '编辑 AI Key' : '添加 AI Key'" 
      v-model="showAddDialog" 
      width="600px"
      @close="resetForm"
    >
      <el-form :model="keyForm" :rules="formRules" ref="formRef" label-width="100px">
        <el-form-item label="Key名称" prop="name">
          <el-input v-model="keyForm.name" placeholder="请输入Key名称" />
        </el-form-item>
        <el-form-item label="服务商类型" prop="provider_type">
          <el-select v-model="keyForm.provider_type" placeholder="请选择服务商类型" style="width: 100%">
            <el-option 
              v-for="provider in providerTypes" 
              :key="provider.value" 
              :label="provider.label" 
              :value="provider.value" 
            />
          </el-select>
        </el-form-item>
        <el-form-item label="API Key" prop="api_key">
          <el-input 
            v-model="keyForm.api_key" 
            type="password" 
            show-password 
            placeholder="请输入API Key"
          />
        </el-form-item>
        <el-form-item label="服务地址" prop="base_url">
          <el-input 
            v-model="keyForm.base_url" 
            placeholder="请输入服务地址（可选）"
          />
        </el-form-item>
        <el-form-item label="描述" prop="description">
          <el-input 
            v-model="keyForm.description" 
            type="textarea" 
            :rows="3" 
            placeholder="请输入描述信息（可选）"
          />
        </el-form-item>
        <el-form-item label="状态" prop="is_active">
          <el-switch v-model="keyForm.is_active" active-text="启用" inactive-text="禁用" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="showAddDialog = false">取消</el-button>
        <el-button type="primary" @click="saveAIKey" :loading="saving">
          {{ editingKey ? '更新' : '创建' }}
        </el-button>
      </template>
    </el-dialog>

    <!-- 详情对话框 -->
    <el-dialog title="AI Key 详情" v-model="showDetailDialog" width="600px">
      <div v-if="currentKeyDetail">
        <el-descriptions :column="1" border>
          <el-descriptions-item label="Key名称">{{ currentKeyDetail.name }}</el-descriptions-item>
          <el-descriptions-item label="服务商类型">
            <el-tag :type="getProviderTagType(currentKeyDetail.provider_type)">
              {{ getProviderLabel(currentKeyDetail.provider_type) }}
            </el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="API Key">
            <div class="api-key-display">
              <el-input 
                v-model="currentKeyDetail.api_key" 
                :type="showFullKey ? 'text' : 'password'" 
                readonly
              />
              <el-button 
                text 
                @click="showFullKey = !showFullKey"
                style="margin-left: 10px;"
              >
                {{ showFullKey ? '隐藏' : '显示' }}
              </el-button>
              <el-button text @click="copyToClipboard(currentKeyDetail.api_key)">
                复制
              </el-button>
            </div>
          </el-descriptions-item>
          <el-descriptions-item label="服务地址">{{ currentKeyDetail.base_url || '未设置' }}</el-descriptions-item>
          <el-descriptions-item label="描述">{{ currentKeyDetail.description || '无' }}</el-descriptions-item>
          <el-descriptions-item label="状态">
            <el-tag :type="currentKeyDetail.is_active ? 'success' : 'danger'">
              {{ currentKeyDetail.is_active ? '启用' : '禁用' }}
            </el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="创建时间">{{ formatDateTime(currentKeyDetail.created_at) }}</el-descriptions-item>
          <el-descriptions-item label="更新时间">{{ formatDateTime(currentKeyDetail.updated_at) }}</el-descriptions-item>
        </el-descriptions>
      </div>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { Plus, Refresh } from '@element-plus/icons-vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import axios from 'axios'
import { onMounted, reactive, ref } from 'vue'

// 类型定义
interface AIKey {
  id: number
  name: string
  provider_type: string
  api_key_masked: string
  base_url?: string
  description?: string
  is_active: boolean
  created_at: string
  updated_at: string
}

interface AIKeyDetail extends AIKey {
  api_key: string
}

interface ProviderType {
  value: string
  label: string
}

// 响应式数据
const loading = ref(false)
const saving = ref(false)
const showAddDialog = ref(false)
const showDetailDialog = ref(false)
const showFullKey = ref(false)
const editingKey = ref<AIKey | null>(null)
const currentKeyDetail = ref<AIKeyDetail | null>(null)

const aiKeys = ref<AIKey[]>([])
const providerTypes = ref<ProviderType[]>([])
const filterProvider = ref('')
const filterActive = ref<boolean | ''>('')

const formRef = ref()
const keyForm = reactive({
  name: '',
  provider_type: '',
  api_key: '',
  base_url: '',
  description: '',
  is_active: true
})

// 表单验证规则
const formRules = {
  name: [{ required: true, message: '请输入Key名称', trigger: 'blur' }],
  provider_type: [{ required: true, message: '请选择服务商类型', trigger: 'change' }],
  api_key: [{ required: true, message: '请输入API Key', trigger: 'blur' }]
}

// 获取AI Key列表
const fetchAIKeys = async () => {
  try {
    loading.value = true
    const params: any = {}
    if (filterProvider.value) params.provider_type = filterProvider.value
    if (filterActive.value !== '') params.is_active = filterActive.value
    
    const response = await axios.get('/api/v1/ai-keys', { params })
    if (response.data.success) {
      aiKeys.value = response.data.data.keys
    }
  } catch (error) {
    console.error('获取AI Key列表失败:', error)
    ElMessage.error('获取AI Key列表失败')
  } finally {
    loading.value = false
  }
}

// 获取服务商类型
const fetchProviderTypes = async () => {
  try {
    const response = await axios.get('/api/v1/ai-keys/providers/types')
    if (response.data.success) {
      providerTypes.value = response.data.data
    }
  } catch (error) {
    console.error('获取服务商类型失败:', error)
  }
}

// 保存AI Key
const saveAIKey = async () => {
  try {
    await formRef.value.validate()
    saving.value = true
    
    let response
    if (editingKey.value) {
      // 更新
      const updateData: any = {}
      if (keyForm.name !== editingKey.value.name) updateData.name = keyForm.name
      if (keyForm.provider_type !== editingKey.value.provider_type) updateData.provider_type = keyForm.provider_type
      if (keyForm.api_key) updateData.api_key = keyForm.api_key
      if (keyForm.base_url !== editingKey.value.base_url) updateData.base_url = keyForm.base_url
      if (keyForm.description !== editingKey.value.description) updateData.description = keyForm.description
      if (keyForm.is_active !== editingKey.value.is_active) updateData.is_active = keyForm.is_active
      
      response = await axios.put(`/api/v1/ai-keys/${editingKey.value.id}`, updateData)
    } else {
      // 创建
      response = await axios.post('/api/v1/ai-keys', keyForm)
    }
    
    if (response.data.success) {
      ElMessage.success(editingKey.value ? '更新成功' : '创建成功')
      showAddDialog.value = false
      resetForm()
      fetchAIKeys()
    }
  } catch (error) {
    console.error('保存AI Key失败:', error)
    ElMessage.error('保存失败')
  } finally {
    saving.value = false
  }
}

// 编辑AI Key
const editAIKey = (key: AIKey) => {
  editingKey.value = key
  keyForm.name = key.name
  keyForm.provider_type = key.provider_type
  keyForm.api_key = '' // 不显示原密码
  keyForm.base_url = key.base_url || ''
  keyForm.description = key.description || ''
  keyForm.is_active = key.is_active
  showAddDialog.value = true
}

// 查看详情
const viewDetail = async (key: AIKey) => {
  try {
    const response = await axios.get(`/api/v1/ai-keys/${key.id}/detail`)
    if (response.data.success) {
      currentKeyDetail.value = response.data.data
      showFullKey.value = false
      showDetailDialog.value = true
    }
  } catch (error) {
    console.error('获取AI Key详情失败:', error)
    ElMessage.error('获取详情失败')
  }
}

// 删除AI Key
const deleteAIKey = async (key: AIKey) => {
  try {
    await ElMessageBox.confirm(
      `确定要删除 AI Key "${key.name}" 吗？`,
      '确认删除',
      {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }
    )
    
    const response = await axios.delete(`/api/v1/ai-keys/${key.id}`)
    if (response.data.success) {
      ElMessage.success('删除成功')
      fetchAIKeys()
    }
  } catch (error) {
    if (error !== 'cancel') {
      console.error('删除AI Key失败:', error)
      ElMessage.error('删除失败')
    }
  }
}

// 重置表单
const resetForm = () => {
  editingKey.value = null
  keyForm.name = ''
  keyForm.provider_type = ''
  keyForm.api_key = ''
  keyForm.base_url = ''
  keyForm.description = ''
  keyForm.is_active = true
  formRef.value?.resetFields()
}

// 获取服务商标签类型
const getProviderTagType = (provider: string) => {
  const typeMap: Record<string, string> = {
    openai: 'primary',
    claude: 'success',
    qwen: 'warning',
    baidu: 'info',
    zhipu: 'danger',
    kimi: 'info',
    custom: 'info'
  }
  return typeMap[provider] || 'info'
}

// 获取服务商标签
const getProviderLabel = (provider: string) => {
  const labelMap: Record<string, string> = {
    openai: 'OpenAI',
    claude: 'Claude',
    qwen: '通义千问',
    baidu: '百度文心',
    zhipu: '智谱AI',
    kimi: 'Kimi',
    custom: '自定义'
  }
  return labelMap[provider] || provider.toUpperCase()
}

// 格式化日期时间
const formatDateTime = (dateStr: string) => {
  if (!dateStr) return ''
  const date = new Date(dateStr)
  return date.toLocaleString('zh-CN')
}

// 复制到剪贴板
const copyToClipboard = async (text: string) => {
  try {
    await navigator.clipboard.writeText(text)
    ElMessage.success('已复制到剪贴板')
  } catch (error) {
    console.error('复制失败:', error)
    ElMessage.error('复制失败')
  }
}

// 组件挂载时获取数据
onMounted(() => {
  fetchProviderTypes()
  fetchAIKeys()
})
</script>

<style scoped>
.ai-key-management {
  padding: 0;
}

.header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 0;
}

.header h2 {
  margin: 0;
  color: #2c3e50;
}

.actions {
  display: flex;
  gap: 10px;
}

.api-key-display {
  display: flex;
  align-items: center;
}

.api-key-display .el-input {
  flex: 1;
}

/* 表格样式优化 */
.el-table {
  font-size: 14px;
}

.el-table .el-button {
  margin-right: 5px;
}

.el-table .el-button:last-child {
  margin-right: 0;
}

/* 对话框样式 */
.el-dialog {
  border-radius: 8px;
}

.el-descriptions {
  margin-top: 20px;
}

/* 筛选器样式 */
.el-select {
  width: 100%;
}
</style>