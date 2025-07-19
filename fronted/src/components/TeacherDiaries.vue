<template>
  <div class="teacher-diaries">
    <el-card class="box-card">
      <template #header>
        <div class="card-header">
          <span>教师日记管理</span>
          <el-button type="primary" @click="showAddDialog = true">
            <el-icon><Plus /></el-icon>
            写日记
          </el-button>
        </div>
      </template>

      <!-- 搜索栏 -->
      <div class="search-bar">
        <el-row :gutter="20">
          <el-col :span="8">
            <el-input
              v-model="searchKeyword"
              placeholder="搜索标题或内容"
              clearable
              @keyup.enter="searchDiaries"
            >
              <template #append>
                <el-button @click="searchDiaries">
                  <el-icon><Search /></el-icon>
                </el-button>
              </template>
            </el-input>
          </el-col>
          <el-col :span="6">
            <el-input
              v-model="searchTags"
              placeholder="搜索标签"
              clearable
              @keyup.enter="searchDiaries"
            />
          </el-col>
          <el-col :span="4">
            <el-button @click="resetSearch">重置</el-button>
          </el-col>
        </el-row>
      </div>

      <!-- 日记列表 -->
      <el-table
        :data="diaries"
        style="width: 100%"
        v-loading="loading"
        empty-text="暂无日记数据"
      >
        <el-table-column prop="id" label="ID" width="80" />
        <el-table-column prop="title" label="标题" min-width="200" />
        <el-table-column prop="tags" label="标签" width="150">
          <template #default="scope">
            <el-tag
              v-for="tag in getTagList(scope.row.tags)"
              :key="tag"
              size="small"
              style="margin-right: 5px"
            >
              {{ tag }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="content" label="内容" min-width="300">
          <template #default="scope">
            <div class="content-preview">
              {{ scope.row.content.length > 100 ? scope.row.content.substring(0, 100) + '...' : scope.row.content }}
            </div>
          </template>
        </el-table-column>
        <el-table-column prop="created_at" label="创建时间" width="180">
          <template #default="scope">
            {{ formatDateTime(scope.row.created_at) }}
          </template>
        </el-table-column>
        <el-table-column prop="updated_at" label="更新时间" width="180">
          <template #default="scope">
            {{ formatDateTime(scope.row.updated_at) }}
          </template>
        </el-table-column>
        <el-table-column label="操作" width="200" fixed="right">
          <template #default="scope">
            <el-button size="small" @click="viewDiary(scope.row)">查看</el-button>
            <el-button size="small" type="primary" @click="editDiary(scope.row)">编辑</el-button>
            <el-button size="small" type="danger" @click="deleteDiary(scope.row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>

      <!-- 分页 -->
      <div class="pagination">
        <el-pagination
          v-model:current-page="currentPage"
          v-model:page-size="pageSize"
          :page-sizes="[10, 20, 50, 100]"
          :total="total"
          layout="total, sizes, prev, pager, next, jumper"
          @size-change="handleSizeChange"
          @current-change="handleCurrentChange"
        />
      </div>
    </el-card>

    <!-- 添加/编辑日记对话框 -->
    <el-dialog
      v-model="showAddDialog"
      :title="editingDiary ? '编辑日记' : '写日记'"
      width="80%"
      @close="resetForm"
      :close-on-click-modal="false"
    >
      <el-form
        ref="diaryFormRef"
        :model="diaryForm"
        :rules="diaryFormRules"
        label-width="80px"
      >
        <el-form-item label="标题" prop="title">
          <el-input v-model="diaryForm.title" placeholder="请输入日记标题" />
        </el-form-item>
        <el-form-item label="标签" prop="tags">
          <el-input
            v-model="diaryForm.tags"
            placeholder="请输入标签，用逗号分隔"
          />
        </el-form-item>
        <el-form-item label="编辑模式">
          <el-radio-group v-model="editorMode">
            <el-radio label="rich">富文本编辑器</el-radio>
            <el-radio label="markdown">Markdown编辑器</el-radio>
          </el-radio-group>
        </el-form-item>
        
        <!-- 富文本编辑器 -->
        <el-form-item v-if="editorMode === 'rich'" label="内容" prop="content">
          <div class="rich-editor">
            <div class="editor-toolbar">
              <el-button-group>
                <el-button size="small" @click="insertImage">插入图片</el-button>
                <el-button size="small" @click="formatText('bold')">粗体</el-button>
                <el-button size="small" @click="formatText('italic')">斜体</el-button>
                <el-button size="small" @click="formatText('underline')">下划线</el-button>
              </el-button-group>
            </div>
            <div
              ref="richEditor"
              class="rich-editor-content"
              contenteditable="true"
              @input="onRichEditorInput"
              @paste="onPaste"
            ></div>
          </div>
        </el-form-item>
        
        <!-- Markdown编辑器 -->
        <el-form-item v-if="editorMode === 'markdown'" label="Markdown" prop="markdown_content">
          <div class="markdown-editor">
            <el-row :gutter="10">
              <el-col :span="12">
                <div class="markdown-toolbar">
                  <el-button-group>
                    <el-button size="small" @click="insertMarkdown('**粗体**')">粗体</el-button>
                    <el-button size="small" @click="insertMarkdown('*斜体*')">斜体</el-button>
                    <el-button size="small" @click="insertMarkdown('# 标题')">标题</el-button>
                    <el-button size="small" @click="insertMarkdown('![图片](url)')">图片</el-button>
                    <el-button size="small" @click="insertMarkdown('- 列表项')">列表</el-button>
                  </el-button-group>
                </div>
                <el-input
                  v-model="diaryForm.markdown_content"
                  type="textarea"
                  :rows="15"
                  placeholder="请输入Markdown内容"
                  @input="updateMarkdownPreview"
                />
              </el-col>
              <el-col :span="12">
                <div class="markdown-preview-label">预览：</div>
                <div class="markdown-preview" v-html="markdownPreview"></div>
              </el-col>
            </el-row>
          </div>
        </el-form-item>
      </el-form>
      
      <!-- 图片上传 -->
      <input
        ref="imageInput"
        type="file"
        accept="image/*"
        style="display: none"
        @change="handleImageUpload"
      />
      
      <template #footer>
        <span class="dialog-footer">
          <el-button @click="showAddDialog = false">取消</el-button>
          <el-button type="primary" @click="saveDiary">保存</el-button>
        </span>
      </template>
    </el-dialog>

    <!-- 查看日记对话框 -->
    <el-dialog
      v-model="showViewDialog"
      title="查看日记"
      width="70%"
    >
      <div v-if="viewingDiary">
        <el-descriptions :column="2" border>
          <el-descriptions-item label="标题">{{ viewingDiary.title }}</el-descriptions-item>
          <el-descriptions-item label="标签">
            <el-tag
              v-for="tag in getTagList(viewingDiary.tags)"
              :key="tag"
              size="small"
              style="margin-right: 5px"
            >
              {{ tag }}
            </el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="创建时间">{{ formatDateTime(viewingDiary.created_at) }}</el-descriptions-item>
          <el-descriptions-item label="更新时间">{{ formatDateTime(viewingDiary.updated_at) }}</el-descriptions-item>
        </el-descriptions>
        <div class="content-section">
          <h4>内容：</h4>
          <div v-if="viewingDiary.markdown_content" class="markdown-content" v-html="renderMarkdown(viewingDiary.markdown_content)"></div>
          <div v-else class="content-text" v-html="viewingDiary.content"></div>
        </div>
      </div>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted, nextTick } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus, Search } from '@element-plus/icons-vue'
import axios from 'axios'

// 响应式数据
const loading = ref(false)
const diaries = ref([])
const total = ref(0)
const currentPage = ref(1)
const pageSize = ref(20)
const searchKeyword = ref('')
const searchTags = ref('')
const editorMode = ref('rich')
const markdownPreview = ref('')

// 对话框状态
const showAddDialog = ref(false)
const showViewDialog = ref(false)
const editingDiary = ref(null)
const viewingDiary = ref(null)

// 编辑器引用
const richEditor = ref(null)
const imageInput = ref(null)

// 表单数据
const diaryForm = reactive({
  title: '',
  content: '',
  markdown_content: '',
  images: '',
  tags: ''
})

// 表单验证规则
const diaryFormRules = {
  title: [{ required: true, message: '请输入标题', trigger: 'blur' }]
}

const diaryFormRef = ref()

// 格式化日期时间
const formatDateTime = (dateTime) => {
  if (!dateTime) return ''
  return new Date(dateTime).toLocaleString('zh-CN')
}

// 获取标签列表
const getTagList = (tags) => {
  if (!tags) return []
  return tags.split(',').filter(tag => tag.trim())
}

// 简单的Markdown渲染
const renderMarkdown = (markdown) => {
  if (!markdown) return ''
  return markdown
    .replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>')
    .replace(/\*(.*?)\*/g, '<em>$1</em>')
    .replace(/^# (.*$)/gim, '<h1>$1</h1>')
    .replace(/^## (.*$)/gim, '<h2>$1</h2>')
    .replace(/^### (.*$)/gim, '<h3>$1</h3>')
    .replace(/^- (.*$)/gim, '<li>$1</li>')
    .replace(/!\[([^\]]*)\]\(([^\)]*)\)/g, '<img alt="$1" src="$2" style="max-width: 100%;" />')
    .replace(/\n/g, '<br>')
}

// 更新Markdown预览
const updateMarkdownPreview = () => {
  markdownPreview.value = renderMarkdown(diaryForm.markdown_content)
}

// 加载日记列表
const loadDiaries = async () => {
  loading.value = true
  try {
    let url = `/api/v1/teacher-diaries/?page=${currentPage.value}&page_size=${pageSize.value}`
    
    // 如果有搜索条件，使用搜索接口
    if (searchKeyword.value || searchTags.value) {
      url = `/api/v1/teacher-diaries/search/?page=${currentPage.value}&page_size=${pageSize.value}`
      if (searchKeyword.value) {
        url += `&keyword=${encodeURIComponent(searchKeyword.value)}`
      }
      if (searchTags.value) {
        url += `&tags=${encodeURIComponent(searchTags.value)}`
      }
    }
    
    const response = await axios.get(url)
    diaries.value = response.data.diaries || []
    total.value = response.data.total || 0
  } catch (error) {
    console.error('加载日记列表失败:', error)
    ElMessage.error('加载日记列表失败')
  } finally {
    loading.value = false
  }
}

// 搜索日记
const searchDiaries = () => {
  currentPage.value = 1
  loadDiaries()
}

// 重置搜索
const resetSearch = () => {
  searchKeyword.value = ''
  searchTags.value = ''
  currentPage.value = 1
  loadDiaries()
}

// 分页处理
const handleSizeChange = (val) => {
  pageSize.value = val
  currentPage.value = 1
  loadDiaries()
}

const handleCurrentChange = (val) => {
  currentPage.value = val
  loadDiaries()
}

// 查看日记
const viewDiary = (diary) => {
  viewingDiary.value = diary
  showViewDialog.value = true
}

// 编辑日记
const editDiary = (diary) => {
  editingDiary.value = diary
  diaryForm.title = diary.title
  diaryForm.content = diary.content
  diaryForm.markdown_content = diary.markdown_content || ''
  diaryForm.images = diary.images || ''
  diaryForm.tags = diary.tags || ''
  
  // 根据内容类型设置编辑模式
  editorMode.value = diary.markdown_content ? 'markdown' : 'rich'
  
  showAddDialog.value = true
  
  nextTick(() => {
    if (editorMode.value === 'rich' && richEditor.value) {
      richEditor.value.innerHTML = diary.content
    }
    if (editorMode.value === 'markdown') {
      updateMarkdownPreview()
    }
  })
}

// 删除日记
const deleteDiary = async (diary) => {
  try {
    await ElMessageBox.confirm(
      `确定要删除日记"${diary.title}"吗？`,
      '确认删除',
      {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }
    )
    
    await axios.delete(`/api/v1/teacher-diaries/${diary.id}`)
    ElMessage.success('删除成功')
    loadDiaries()
  } catch (error) {
    if (error !== 'cancel') {
      console.error('删除日记失败:', error)
      ElMessage.error('删除日记失败')
    }
  }
}

// 富文本编辑器相关
const onRichEditorInput = () => {
  if (richEditor.value) {
    diaryForm.content = richEditor.value.innerHTML
  }
}

const formatText = (command) => {
  document.execCommand(command, false, null)
  onRichEditorInput()
}

const insertImage = () => {
  imageInput.value.click()
}

const handleImageUpload = (event) => {
  const file = event.target.files[0]
  if (file) {
    const reader = new FileReader()
    reader.onload = (e) => {
      const img = `<img src="${e.target.result}" style="max-width: 100%; height: auto;" />`
      if (editorMode.value === 'rich' && richEditor.value) {
        richEditor.value.focus()
        document.execCommand('insertHTML', false, img)
        onRichEditorInput()
      } else if (editorMode.value === 'markdown') {
        const markdownImg = `![图片](${e.target.result})`
        diaryForm.markdown_content += markdownImg
        updateMarkdownPreview()
      }
    }
    reader.readAsDataURL(file)
  }
}

const onPaste = (event) => {
  const items = event.clipboardData.items
  for (let item of items) {
    if (item.type.indexOf('image') !== -1) {
      event.preventDefault()
      const file = item.getAsFile()
      const reader = new FileReader()
      reader.onload = (e) => {
        const img = `<img src="${e.target.result}" style="max-width: 100%; height: auto;" />`
        document.execCommand('insertHTML', false, img)
        onRichEditorInput()
      }
      reader.readAsDataURL(file)
    }
  }
}

// Markdown编辑器相关
const insertMarkdown = (text) => {
  diaryForm.markdown_content += text
  updateMarkdownPreview()
}

// 保存日记
const saveDiary = async () => {
  try {
    await diaryFormRef.value.validate()
    
    // 根据编辑模式设置内容
    if (editorMode.value === 'rich') {
      diaryForm.content = richEditor.value ? richEditor.value.innerHTML : ''
      diaryForm.markdown_content = ''
    } else {
      diaryForm.content = diaryForm.markdown_content
    }
    
    if (editingDiary.value) {
      // 编辑模式
      await axios.put(`/api/v1/teacher-diaries/${editingDiary.value.id}`, {
        title: diaryForm.title,
        content: diaryForm.content,
        markdown_content: diaryForm.markdown_content,
        images: diaryForm.images,
        tags: diaryForm.tags
      })
      ElMessage.success('更新成功')
    } else {
      // 新增模式
      await axios.post('/api/v1/teacher-diaries/', diaryForm)
      ElMessage.success('添加成功')
    }
    
    showAddDialog.value = false
    resetForm()
    loadDiaries()
  } catch (error) {
    console.error('保存日记失败:', error)
    ElMessage.error('保存日记失败')
  }
}

// 重置表单
const resetForm = () => {
  editingDiary.value = null
  diaryForm.title = ''
  diaryForm.content = ''
  diaryForm.markdown_content = ''
  diaryForm.images = ''
  diaryForm.tags = ''
  editorMode.value = 'rich'
  markdownPreview.value = ''
  
  if (richEditor.value) {
    richEditor.value.innerHTML = ''
  }
  
  if (diaryFormRef.value) {
    diaryFormRef.value.resetFields()
  }
}

// 组件挂载时加载数据
onMounted(() => {
  loadDiaries()
})
</script>

<style scoped>
.teacher-diaries {
  padding: 20px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.search-bar {
  margin-bottom: 20px;
}

.content-preview {
  word-break: break-word;
  line-height: 1.4;
}

.pagination {
  margin-top: 20px;
  text-align: center;
}

.content-section {
  margin-top: 20px;
}

.content-section h4 {
  margin-bottom: 10px;
  color: #303133;
}

.content-text {
  padding: 12px;
  background-color: #f5f7fa;
  border-radius: 4px;
  line-height: 1.6;
  white-space: pre-wrap;
  word-break: break-word;
}

.markdown-content {
  padding: 12px;
  background-color: #f5f7fa;
  border-radius: 4px;
  line-height: 1.6;
}

.dialog-footer {
  text-align: right;
}

/* 富文本编辑器样式 */
.rich-editor {
  border: 1px solid #dcdfe6;
  border-radius: 4px;
}

.editor-toolbar {
  padding: 8px;
  border-bottom: 1px solid #dcdfe6;
  background-color: #f5f7fa;
}

.rich-editor-content {
  min-height: 200px;
  padding: 12px;
  outline: none;
  line-height: 1.6;
}

.rich-editor-content:focus {
  border-color: #409eff;
}

/* Markdown编辑器样式 */
.markdown-editor {
  border: 1px solid #dcdfe6;
  border-radius: 4px;
  padding: 12px;
}

.markdown-toolbar {
  margin-bottom: 10px;
}

.markdown-preview-label {
  margin-bottom: 10px;
  font-weight: bold;
  color: #303133;
}

.markdown-preview {
  min-height: 300px;
  padding: 12px;
  border: 1px solid #dcdfe6;
  border-radius: 4px;
  background-color: #f5f7fa;
  line-height: 1.6;
  overflow-y: auto;
}

.markdown-preview h1,
.markdown-preview h2,
.markdown-preview h3 {
  margin: 10px 0;
}

.markdown-preview img {
  max-width: 100%;
  height: auto;
}

.markdown-preview li {
  margin-left: 20px;
}
</style>