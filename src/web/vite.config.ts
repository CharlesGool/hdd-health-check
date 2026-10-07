import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import tailwindcss from '@tailwindcss/vite'
import { execFileSync } from 'node:child_process'
import { fileURLToPath } from 'node:url'
import { readFileSync } from 'node:fs'

const packageVersion = JSON.parse(readFileSync(new URL('./package.json', import.meta.url), 'utf8'))
  .version as string
let buildVersion = `test-archive-${packageVersion}`
try {
  const gitOptions = {
    cwd: fileURLToPath(new URL('../..', import.meta.url)),
    encoding: 'utf8' as const,
    stdio: ['ignore', 'pipe', 'ignore'] as ['ignore', 'pipe', 'ignore'],
  }
  const sha = execFileSync('git', ['rev-parse', '--short', 'HEAD'], gitOptions).trim()
  const dirty = execFileSync('git', ['status', '--porcelain'], gitOptions).trim().length > 0
  let tag = ''
  try {
    tag = execFileSync('git', ['describe', '--tags', '--exact-match'], gitOptions).trim()
  } catch {
    /* untagged commit */
  }
  buildVersion = tag && !dirty ? tag : `test-${sha}${dirty ? '-dirty' : ''}`
} catch {
  /* source archive without Git metadata uses its package version */
}

export default defineConfig({
  resolve: { alias: { '@': fileURLToPath(new URL('./src', import.meta.url)) } },
  plugins: [
    vue(),
    tailwindcss(),
    {
      name: 'build-version',
      generateBundle() {
        this.emitFile({
          type: 'asset',
          fileName: 'version.json',
          source: JSON.stringify({ version: buildVersion }),
        })
      },
    },
  ],
  build: {
    outDir: '../../dist/web',
    emptyOutDir: true,
    rolldownOptions: {
      output: {
        codeSplitting: { groups: [{ name: 'vendor', test: /node_modules/ }] },
      },
    },
  },
  define: { __BUILD_VERSION__: JSON.stringify(buildVersion) },
  server: { proxy: { '/api': 'http://127.0.0.1:8765' } },
})
