import * as ElementPlusIconsVue from "@element-plus/icons-vue";
import axios from "axios";
import ElementPlus from "element-plus";
import "element-plus/dist/index.css";
import { createApp } from "vue";
import { createRouter, createWebHistory } from "vue-router";

import App from "./App.vue";
import AIKeyManagement from "./components/AIKeyManagement.vue";
import CheckinManagement from "./components/CheckinManagement.vue";
import ClassManagement from "./components/ClassManagement.vue";
import Dashboard from "./components/Dashboard.vue";
import StudentManagement from "./components/StudentManagement.vue";

// 配置axios
axios.defaults.baseURL = "http://localhost:8000";
axios.defaults.timeout = 10000;

// 请求拦截器
axios.interceptors.request.use(
  (config) => {
    // 可以在这里添加认证token等
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// 响应拦截器
axios.interceptors.response.use(
  (response) => {
    // 确保返回的是完整的response对象，而不仅仅是data
    return response;
  },
  (error) => {
    console.error("API请求错误:", error);
    return Promise.reject(error);
  }
);

// 路由配置
const routes = [
  { path: "/", redirect: "/dashboard" },
  {
    path: "/dashboard",
    component: Dashboard,
    name: "Dashboard",
    meta: { title: "仪表盘" },
  },
  {
    path: "/students",
    component: StudentManagement,
    name: "StudentManagement",
    meta: { title: "学生管理" },
  },
  {
    path: "/classes",
    component: ClassManagement,
    name: "ClassManagement",
    meta: { title: "班级管理" },
  },
  {
    path: "/checkins",
    component: CheckinManagement,
    name: "CheckinManagement",
    meta: { title: "打卡管理" },
  },
  {
    path: "/ai-keys",
    component: AIKeyManagement,
    name: "AIKeyManagement",
    meta: { title: "AI Key管理" },
  },
];

const router = createRouter({
  history: createWebHistory(),
  routes,
});

// 创建Vue应用
const app = createApp(App);

// 注册Element Plus
app.use(ElementPlus);

// 注册Element Plus图标
for (const [key, component] of Object.entries(ElementPlusIconsVue)) {
  app.component(key, component);
}

// 注册路由
app.use(router);

// 全局属性
app.config.globalProperties.$http = axios;

// 挂载应用
app.mount("#app");
