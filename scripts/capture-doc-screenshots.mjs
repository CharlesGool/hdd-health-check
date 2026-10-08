// Capture the built UI with synthetic data. The fixture blocks all disk subprocesses.
import assert from 'node:assert/strict'
import { spawn } from 'node:child_process'
import { createRequire } from 'node:module'
import { mkdir, readFile, writeFile } from 'node:fs/promises'
import { resolve } from 'node:path'
import { createInterface } from 'node:readline'
import { fileURLToPath } from 'node:url'

const root = fileURLToPath(new URL('../', import.meta.url))
const { chromium } = createRequire(new URL('../src/web/package.json', import.meta.url))('playwright')
const preview = spawn(process.env.PYTHON || 'python3', ['tests/fixtures/web-preview.py'], { cwd: root, stdio: ['ignore', 'pipe', 'inherit'] })
const lines = createInterface({ input: preview.stdout })
const build = JSON.parse(await readFile(resolve(root, 'dist/web/version.json'), 'utf8'))
const manifest = { build: build.version, data: 'synthetic', timezone: 'Asia/Singapore', screenshots: [] }
const summaries = { 'zh-CN': ['演示: 检查已完成', '演示: 记录需复查'], en: ['Demo: check completed', 'Demo: record needs review'], es: ['Demostración: prueba completada', 'Demostración: registro para revisar'] }
const stamp = Date.UTC(2026, 9, 8, 1, 0) / 1000
let browser
try {
  const port = await new Promise((accept, reject) => {
    const timer = setTimeout(() => reject(new Error('Preview startup timed out')), 10000)
    lines.once('line', value => { clearTimeout(timer); accept(Number(value)) })
    preview.once('exit', code => { clearTimeout(timer); reject(new Error(`Preview exited: ${code}`)) })
  })
  browser = await chromium.launch({ headless: true, ...(process.env.PLAYWRIGHT_EXECUTABLE_PATH ? { executablePath: process.env.PLAYWRIGHT_EXECUTABLE_PATH } : {}) })
  for (const locale of ['zh-CN', 'en', 'es']) {
    const context = await browser.newContext({ viewport: { width: 1440, height: 1000 }, locale, timezoneId: 'Asia/Singapore', hasTouch: true, reducedMotion: 'reduce' })
    await context.addInitScript(locale => { localStorage.setItem('hdd-lang', locale); localStorage.setItem('hdd-theme', 'slate-blue'); if (!localStorage.getItem('hdd-mode')) localStorage.setItem('hdd-mode', 'light') }, locale)
    const page = await context.newPage()
    const errors = []
    page.on('pageerror', error => errors.push(error.message))
    page.on('console', message => { if (message.type() === 'error') errors.push(message.text()) })
    const module = (name, warn = false) => ({ name, timestamp: stamp, status: warn ? 'warn' : 'good', summary: summaries[locale][warn ? 1 : 0], deduction: warn ? 5 : 0, issues: warn ? summaries[locale][1] : '', current: true })
    const disks = [
      { name: 'sda', model: 'Demo HDD 01', bytes: 8e12, size: '8 TB', rotation: '1', transport: 'sata', temperature: 34, score: 100, coverage: '完整', modules: ['quick', 'selftest_short', 'selftest_long', 'speed', 'surface'].map(name => module(name)) },
      { name: 'sdb', model: 'Demo HDD 02', bytes: 4e12, size: '4 TB', rotation: '1', transport: 'sata', temperature: 36, score: null, coverage: '部分', modules: [module('quick', true)] },
      { name: 'nvme0n1', model: 'Demo NVMe SSD', bytes: 2e12, size: '2 TB', rotation: '0', transport: 'nvme', temperature: 43, score: 100, coverage: '完整', modules: ['quick', 'selftest_short', 'selftest_long', 'surface'].map(name => module(name)) },
    ].map((disk, i) => ({ ...disk, serial: `••••D00${i + 1}`, grade: disk.score === 100 ? '良好' : '未知', level: i === 1 ? 1 : 0, stale: 0, temperatureState: 'available', link: disk.transport === 'sata' ? { kind: 'sata', sataVersion: 'SATA 3.3', speed: '6.0 Gb/s' } : { kind: 'nvme', version: '4.0', width: '4', speed: '16.0 GT/s' } }))
    await page.route('**/api/**', async route => {
      const path = new URL(route.request().url()).pathname
      if (path.startsWith('/api/auth') || path === '/api/build') return route.continue()
      const data = path === '/api/snapshot' ? { version: '4.1.0', disks, storage: { totalBytes: 14e12, usedBytes: 3.6e12 } }
        : path === '/api/status' ? { running: false, text: '', job: null }
        : path === '/api/schedule' ? { enabled: false, hours: 24, last: 0, attempt: 0, error: '' }
        : path === '/api/preferences' ? { wakeSleepingOnVisit: false }
        : path === '/api/access' ? { enabled: false, ips: [] }
        : path === '/api/jobs/history' ? { jobs: [] }
        : path === '/api/history/samples' ? { samples: [] }
        : path.endsWith('/smart') ? { available: true, model: 'Demo HDD 01', serial: '••••D001', protocol: 'ATA', capacity: 8e12, passed: true, temperature: 34, temperatureState: 'available', formFactor: '3.5 inches', powerOnHours: 12480, link: { kind: 'sata', sataVersion: 'SATA 3.3', speed: '6.0 Gb/s' }, attributes: [
          { key: 'Reallocated_Sector_Ct', id: 5, value: '0', normalized: 100, threshold: 10 },
          { key: 'Power_On_Hours', id: 9, value: '12480', normalized: 99, threshold: 0 },
          { key: 'Temperature_Celsius', id: 194, value: '34', normalized: 66, threshold: 0 },
          { key: 'Current_Pending_Sector', id: 197, value: '0', normalized: 100, threshold: 0 },
          { key: 'Offline_Uncorrectable', id: 198, value: '0', normalized: 100, threshold: 0 },
          { key: 'UDMA_CRC_Error_Count', id: 199, value: '0', normalized: 200, threshold: 0 },
        ] } : null
      assert.notEqual(data, null, `Unexpected API during screenshot capture: ${path}`)
      await route.fulfill({ json: data })
    })
    const base = `http://127.0.0.1:${port}`
    await page.goto(`${base}/disks`)
    await page.locator('#login-password').fill('synthetic-preview-password')
    await page.locator('form').getByRole('button', { name: JSON.parse(await readFile(resolve(root, `lang/web/${locale}.json`), 'utf8')).login, exact: true }).click()
    await page.locator('.dashboard-grid').waitFor()
    const directory = resolve(root, 'doc/resources', locale)
    await mkdir(directory, { recursive: true })
    const shots = [['dashboard', '/disks', 'light', 1440, 1000], ['smart-detail', '/disks/sda', 'light', 1440, 1000], ['settings', '/settings', 'dark', 1440, 1000], ['mobile', '/disks/sda', 'light', 375, 900]]
    for (const [name, path, mode, width, height] of shots) {
      await page.evaluate(mode => localStorage.setItem('hdd-mode', mode), mode)
      await page.setViewportSize({ width, height })
      const response = await page.goto(base + path)
      assert.equal(response.status(), 200)
      await page.locator('h1').waitFor()
      await page.waitForTimeout(700)
      await page.evaluate(() => document.fonts.ready)
      assert(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth), `${locale}/${name}: overflow`)
      assert.equal(await page.locator('[data-reflow] [data-reflow]').count(), 0, 'Nested reflow groups')
      assert.equal(await page.getByText('synthetic-preview-password', { exact: true }).count(), 0)
      await page.screenshot({ path: resolve(directory, `${name}.png`), fullPage: true })
      manifest.screenshots.push({ locale, file: `doc/resources/${locale}/${name}.png`, route: path, mode, viewport: { width, height } })
    }
    assert.deepEqual(errors, [])
    await context.close()
  }
  await mkdir(resolve(root, '.local/verification'), { recursive: true })
  await writeFile(resolve(root, '.local/verification/doc-screenshots.json'), JSON.stringify(manifest, null, 2) + '\n')
  console.log(`Captured ${manifest.screenshots.length} current-build screenshots with synthetic data; no browser errors`)
} finally {
  await browser?.close()
  lines.close()
  preview.kill('SIGTERM')
}
