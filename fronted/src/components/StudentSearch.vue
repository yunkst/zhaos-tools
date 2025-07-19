<template>
  <div class="student-search">
    <!-- 视图模式选择 -->
    <div class="view-mode-selector">
      <el-radio-group v-model="viewMode" @change="handleViewModeChange">
        <el-radio-button value="class">按班级查看</el-radio-button>
        <el-radio-button value="all">查看全部学生</el-radio-button>
      </el-radio-group>
    </div>

    <!-- 按班级查看模式 -->
    <div v-if="viewMode === 'class'" class="class-view">
      <!-- 班级选择器 -->
      <div class="class-selector">
        <el-row :gutter="20">
          <el-col :span="8">
            <el-select 
              v-model="selectedClassId" 
              placeholder="请选择班级" 
              @change="handleClassChange" 
              size="large"
              style="width: 100%"
            >
              <el-option 
                v-for="classItem in classList" 
                :key="classItem.id"
                :label="`${classItem.name} (${classItem.student_count}人)`" 
                :value="classItem.id" 
              />
            </el-select>
          </el-col>
          <el-col :span="4">
            <el-button @click="refreshClasses" icon="Refresh">刷新班级</el-button>
          </el-col>
        </el-row>
      </div>

      <!-- 班级搜索栏 -->
      <div v-if="selectedClassId" class="search-bar">
        <el-input 
          v-model="classSearchKeyword" 
          placeholder="在当前班级中搜索学生姓名、学号" 
          @keyup.enter="searchClassStudents"
          clearable 
          style="width: 300px"
        >
          <template #append>
            <el-button @click="searchClassStudents" icon="Search" />
          </template>
        </el-input>
      </div>
    </div>

    <!-- 查看全部学生模式 -->
    <div v-else class="all-students-view">
      <!-- 搜索栏 -->
      <div class="search-bar">
        <el-row :gutter="20">
          <el-col :span="8">
            <el-input 
              v-model="allSearchKeyword" 
              placeholder="搜索学生姓名、学号" 
              @keyup.enter="searchAllStudents" 
              clearable
            >
              <template #append>
                <el-button @click="searchAllStudents" icon="Search" />
              </template>
            </el-input>
          </el-col>
          <el-col :span="6">
            <el-select 
              v-model="allClassFilter" 
              placeholder="筛选班级" 
              @change="searchAllStudents" 
              clearable
            >
              <el-option 
                v-for="classItem in classList" 
                :key="classItem.id" 
                :label="classItem.name"
                :value="classItem.name" 
              />
            </el-select>
          </el-col>
          <el-col :span="4">
            <el-button @click="resetAllSearch" icon="Refresh">重置搜索</el-button>
          </el-col>
        </el-row>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'

const props = defineProps({
  classList: {
    type: Array,
    default: () => []
  }
})

const emit = defineEmits([
  'view-mode-change',
  'class-change', 
  'refresh-classes',
  'search-class-students',
  'search-all-students',
  'reset-all-search'
])

// 视图模式
const viewMode = ref('class')

// 班级相关
const selectedClassId = ref(null)
const classSearchKeyword = ref('')

// 全部学生相关
const allSearchKeyword = ref('')
const allClassFilter = ref('')

// 计算属性
const selectedClassName = computed(() => {
  const classItem = props.classList.find(c => c.id === selectedClassId.value)
  return classItem ? classItem.name : ''
})

// 视图模式切换
const handleViewModeChange = (mode) => {
  viewMode.value = mode
  if (mode === 'class') {
    selectedClassId.value = null
  }
  emit('view-mode-change', mode)
}

// 班级选择变化
const handleClassChange = (classId) => {
  selectedClassId.value = classId
  emit('class-change', classId)
}

// 刷新班级列表
const refreshClasses = () => {
  emit('refresh-classes')
}

// 搜索班级学生
const searchClassStudents = () => {
  emit('search-class-students', {
    classId: selectedClassId.value,
    keyword: classSearchKeyword.value
  })
}

// 搜索全部学生
const searchAllStudents = () => {
  emit('search-all-students', {
    keyword: allSearchKeyword.value,
    classFilter: allClassFilter.value
  })
}

// 重置全部学生搜索
const resetAllSearch = () => {
  allSearchKeyword.value = ''
  allClassFilter.value = ''
  emit('reset-all-search')
}

// 暴露数据和方法
defineExpose({
  viewMode,
  selectedClassId,
  selectedClassName,
  classSearchKeyword,
  allSearchKeyword,
  allClassFilter
})
</script>

<style scoped>
@import '../assets/styles/components.css';
</style>