import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import tailwindcss from '@tailwindcss/vite'
import { execFileSync } from 'node:child_process'

let buildVersion = 'dev-unknown'
try {
  const sha = execFileSync('git', ['rev-parse', '--short', 'HEAD'], { cwd: '..', encoding: 'utf8' }).trim()
  const dirty = execFileSync('git', ['status', '--porcelain'], { cwd: '..', encoding: 'utf8' }).trim().length > 0
  let tag = ''
  try { tag = execFileSync('git', ['describe', '--tags', '--exact-match'], { cwd: '..', encoding: 'utf8' }).trim() } catch { /* untagged commit */ }
  buildVersion = tag && !dirty ? tag : `dev-${sha}${dirty ? '-dirty' : ''}`
} catch { /* source archive without Git metadata */ }

export default defineConfig({
  plugins: [vue(), tailwindcss()],
  define: { __BUILD_VERSION__: JSON.stringify(buildVersion) },
  server: { proxy: { '/api': 'http://127.0.0.1:8765' } },
})
