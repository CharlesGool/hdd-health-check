import { createApp } from 'vue'
import App from './App.vue'
import './styles/main.css'
import './style.css'

try {
  const theme = localStorage.getItem('hdd-theme')
  if (
    ['slate-blue', 'sage', 'teal', 'plum', 'ocean', 'olive', 'terracotta', 'indigo'].includes(
      theme || '',
    )
  )
    document.documentElement.dataset.theme = theme || 'slate-blue'
  else document.documentElement.dataset.theme = 'slate-blue'
  document.documentElement.classList.toggle('dark', localStorage.getItem('hdd-mode') === 'dark')
} catch {
  /* Browser storage can be unavailable. */
}
createApp(App).mount('#app')
