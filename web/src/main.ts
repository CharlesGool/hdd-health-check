import { createApp } from 'vue'
import App from './App.vue'
import './style.css'

try {
  const theme = localStorage.getItem('hdd-theme')
  if (['slate-blue', 'sage', 'teal', 'plum'].includes(theme || '')) document.documentElement.dataset.theme = theme || 'slate-blue'
} catch { /* Browser storage can be unavailable. */ }
createApp(App).mount('#app')
