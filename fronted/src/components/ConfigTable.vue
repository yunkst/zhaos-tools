<template>
  <el-table :data="configs" stripe style="width: 100%">
    <el-table-column prop="key" label="配置键" width="200" show-overflow-tooltip />
    <el-table-column prop="value" label="配置值" min-width="200" show-overflow-tooltip>
      <template #default="{ row }">
        <span v-if="isSecretKey(row.key)" class="secret-value">
          {{ maskSecretValue(row.value) }}
        </span>
        <span v-else>{{ row.value }}</span>
      </template>
    </el-table-column>
    <el-table-column prop="description" label="描述" min-width="200" show-overflow-tooltip />
    <el-table-column prop="updated_at" label="更新时间" width="180">
      <template #default="{ row }">
        {{ formatDateTime(row.updated_at) }}
      </template>
    </el-table-column>
    <el-table-column label="操作" width="150" fixed="right">
      <template #default="{ row }">
        <el-button type="primary" size="small" @click="$emit('edit', row)">
          编辑
        </el-button>
        <el-button type="danger" size="small" @click="$emit('delete', row)">
          删除
        </el-button>
      </template>
    </el-table-column>
  </el-table>
</template>

<script setup lang="ts">
interface Config {
  key: string
  value: string
  description?: string
  updated_at: string
}

defineProps<{
  configs: Config[]
}>()

defineEmits<{
  edit: [config: Config]
  delete: [config: Config]
}>()

// 判断是否为敏感配置
const isSecretKey = (key: string): boolean => {
  const secretKeys = ['API_KEY', 'SECRET_KEY', 'PASSWORD', 'TOKEN']
  return secretKeys.some(secretKey => key.toUpperCase().includes(secretKey))
}

// 遮蔽敏感值
const maskSecretValue = (value: string): string => {
  if (!value) return ''
  if (value.length <= 8) return '*'.repeat(value.length)
  return value.substring(0, 4) + '*'.repeat(value.length - 8) + value.substring(value.length - 4)
}

// 格式化日期时间
const formatDateTime = (dateTime: string): string => {
  return new Date(dateTime).toLocaleString('zh-CN')
}
</script>

<style scoped>
.secret-value {
  font-family: monospace;
  color: #909399;
}
</style>