<script setup lang="ts">
import { computed, nextTick, onMounted, onUnmounted, ref, watch } from 'vue'
import MarkdownIt from 'markdown-it'
import UiSelect from './UiSelect.vue'
import { Activity, ArrowRight, Clock3, HardDrive, History, Play, RefreshCw, Settings2, ShieldAlert, Square, X, LogOut, LockKeyhole } from '@lucide/vue'

type Module = { name: string; timestamp: number; status: string; summary: string; deduction: number; issues: string; current: boolean }
type Link = { kind?: string; version?: string; sataVersion?: string; speed?: string; width?: string; maxSpeed?: string; maxVersion?: string; maxWidth?: string }
type Disk = { name: string; id: string; model: string; size: string; bytes?: number | null; serial?: string; vendor?: string; rotation: string; transport: string; link?: Link; temperature?: number | null; temperatureState?: string; temperatureWarning?: number | null; temperatureCritical?: number | null; score: number | null; coverage: string; grade: string; level: number; stale: number; modules: Module[] }
type Snapshot = { version: string; disks: Disk[]; storage?: { totalBytes: number; usedBytes: number | null } }
type Schedule = { enabled: boolean; hours: number; last: number; attempt: number; error: string }
type Auth = { authenticated: boolean; method: string | null; ipAllowed: boolean; canManageAccess: boolean }
type Smart = { available: boolean; error: string; model: string; serial: string; protocol: string; capacity: number | null; passed: boolean | null; temperature: number | null; temperatureState?: string; temperatureWarning?: number | null; temperatureCritical?: number | null; formFactor?: string; powerOnHours: number | null; writtenBytes?: number | null; writtenSource?: string; link?: Link; attributes: { key: string; value: string; id?: number; normalized?: number; threshold?: number }[] }
type Job = { id: string; state: 'accepted' | 'running' | 'completed' | 'failed' | 'stopped' | 'unconfirmed'; module: string; targets: string; started: number; finished: number; exitCode: number; output: string }
type PastJob = Omit<Job, 'output'>
type Lang = 'zh-CN' | 'zh-TW' | 'zh-HK' | 'en' | 'hi' | 'es' | 'ar' | 'fr'
import zhCN from '../../lang/web/zh-CN.json'
import zhTW from '../../lang/web/zh-TW.json'
import zhHK from '../../lang/web/zh-HK.json'
import en from '../../lang/web/en.json'
import hi from '../../lang/web/hi.json'
import es from '../../lang/web/es.json'
import ar from '../../lang/web/ar.json'
import fr from '../../lang/web/fr.json'
import logEn from '../../doc/LOG.md?raw'
import logZhCN from '../../doc/zh_cn/LOG.md?raw'
import logZhTW from '../../doc/zh_tw/LOG.md?raw'
import logZhHK from '../../doc/zh_hk/LOG.md?raw'
import logHi from '../../doc/hi/LOG.md?raw'
import logEs from '../../doc/es/LOG.md?raw'
import logAr from '../../doc/ar/LOG.md?raw'
import logFr from '../../doc/fr/LOG.md?raw'
const strings = { 'zh-CN': zhCN, 'zh-TW': zhTW, 'zh-HK': zhHK, en, hi, es, ar, fr }
const logs: Record<Lang, string> = { 'zh-CN': logZhCN, 'zh-TW': logZhTW, 'zh-HK': logZhHK, en: logEn, hi: logHi, es: logEs, ar: logAr, fr: logFr }
type Key = keyof typeof strings.en
const languages: { code: Lang; label: string }[] = [{code:'zh-CN',label:'简体中文'},{code:'zh-TW',label:'繁體中文（台灣）'},{code:'zh-HK',label:'繁體中文（香港）'},{code:'en',label:'English'},{code:'hi',label:'हिन्दी'},{code:'es',label:'Español'},{code:'ar',label:'العربية'},{code:'fr',label:'Français'}]
const lang = ref<Lang>('zh-CN')
try { const saved = localStorage.getItem('hdd-lang') as Lang | null; if (saved && saved in strings) lang.value = saved } catch { /* ignore */ }
const t = (key: string): string => (strings[lang.value] as Record<string,string>)[key] || (strings.en as Record<string,string>)[key] || key
const themes = ['slate-blue', 'sage', 'teal', 'plum'] as const
const theme = ref<string>(document.documentElement.dataset.theme || 'slate-blue')
const snapshot = ref<Snapshot | null>(null)
const schedule = ref<Schedule>({ enabled: false, hours: 24, last: 0, attempt: 0, error: '' })
const status = ref<{ running: boolean; text: string; job: Job | null }>({ running: false, text: '', job: null })
const selected = ref<string | null>(null)
const history = ref<number[][]>([])
const moduleChoice = ref('quick')
const busy = ref(false)
const editingSchedule = ref(false)
const loading = ref(true)
const error = ref('')
const message = ref('')
type Confirmation = { title: string; detail?: string; targets?: string[]; action: string }
const confirmation = ref<Confirmation | null>(null)
const confirmCancelButton = ref<HTMLButtonElement | null>(null)
const confirmDialog = ref<HTMLElement | null>(null)
let confirmResolve: ((accepted: boolean) => void) | null = null
let confirmReturnFocus: HTMLElement | null = null
function askConfirmation(request: Confirmation): Promise<boolean> {
  if (confirmation.value) return Promise.resolve(false)
  confirmReturnFocus = document.activeElement instanceof HTMLElement ? document.activeElement : null
  confirmation.value = request
  void nextTick(() => confirmCancelButton.value?.focus())
  return new Promise(resolve => { confirmResolve = resolve })
}
function answerConfirmation(accepted: boolean) {
  confirmation.value = null
  confirmResolve?.(accepted)
  confirmResolve = null
  void nextTick(() => confirmReturnFocus?.focus())
}
function onConfirmKeydown(event: KeyboardEvent) {
  if (event.key === 'Escape') { event.preventDefault(); answerConfirmation(false); return }
  if (event.key !== 'Tab' || !confirmDialog.value) return
  const buttons = Array.from(confirmDialog.value.querySelectorAll<HTMLButtonElement>('button:not([disabled])'))
  if (!buttons.length) return
  const first = buttons[0], last = buttons[buttons.length - 1]
  if (event.shiftKey && document.activeElement === first) { event.preventDefault(); last.focus() }
  else if (!event.shiftKey && document.activeElement === last) { event.preventDefault(); first.focus() }
}
const buildVersion = __BUILD_VERSION__
const previewMode = window.location.pathname === '/__backend/site-preview'
const markdown = new MarkdownIt({ html: false, linkify: true, breaks: false })
const changelogHtml = computed(() => {
  const source = logs[lang.value].replace(/^---\r?\n[\s\S]*?\r?\n---\r?\n/, '')
  const sections = [...source.matchAll(/^## .+$/gm)]
  const selected = sections.length ? source.slice(sections[sections.length - 1].index).replace(/^## .+\r?\n/, '') : source
  return markdown.render(selected)
})
const auth = ref<Auth | null>(null)
const password = ref('')
const loginError = ref('')
const loginBusy = ref(false)
type Page = 'disks' | 'attention' | 'tasks' | 'schedule' | 'settings' | 'changelog'
function pageFromPath(): Page { const segment = window.location.pathname.split('/')[1]; return (['attention','tasks','schedule','settings','changelog'].includes(segment) ? segment : 'disks') as Page }
const currentPage = ref<Page>(pageFromPath())
const smart = ref<Smart | null>(null)
const smartLoading = ref(false)
let detailRequest = 0
const detailTab = ref<'smart' | 'checks'>('smart')
const allowedIps = ref<string[]>([])
const newIp = ref('')
const accessError = ref('')
const wakeSleepingOnVisit = ref(false)
const savedWakeSleepingOnVisit = ref(false)
const preferencesLoaded = ref(false)
const preferencesBusy = ref(false)
const preferencesError = ref('')
let visitWakeRequested = false
const currentPassword = ref('')
const newPassword = ref('')
const confirmPassword = ref('')
const passwordChangeError = ref('')
const passwordChangeBusy = ref(false)
const taskDetailsOpen = ref(false)
const pastJobs = ref<PastJob[]>([])
const pastJobOpen = ref<string | null>(null)
const pastJobLog = ref('')
type Scope = 'sata' | 'hdd' | 'ssd' | 'nvme' | 'all'
const assessmentScope = ref<Scope>('all')
const assessmentModule = ref('full')
const assessmentBusy = ref(false)
const powerTimeExpanded = ref(false)
const capacityBinary = ref(false)
const scopeOptions: Scope[] = ['sata', 'hdd', 'ssd', 'nvme', 'all']
const assessmentModules = ['quick', 'short', 'long', 'speed', 'surface', 'badblocks', 'iface', 'full'] as const
const activeDisk = computed(() => snapshot.value?.disks.find(d => d.name === selected.value) || null)
const languageOptions = languages.map(item => ({ value: item.code, label: item.label }))
const scopeSelectOptions = computed(() => scopeOptions.map(value => ({ value, label: scopeLabel(value) })))
const assessmentSelectOptions = computed(() => assessmentModules.map(value => ({ value, label: moduleLabel(value) })))
const diskSelectOptions = computed(() => (activeDisk.value?.rotation === '1' ? assessmentModules : ['quick','full']).map(value => ({ value, label: moduleLabel(value) })))
function selectLanguage(value: string) { if (value in strings) lang.value = value as Lang }
function selectScope(value: string) { if (scopeOptions.includes(value as Scope)) assessmentScope.value = value as Scope }
const assessmentDisks = computed(() => (snapshot.value?.disks || []).filter(d => {
  const transport = d.transport?.toLowerCase()
  if (assessmentScope.value === 'sata') return transport === 'sata'
  if (assessmentScope.value === 'hdd') return d.rotation === '1'
  if (assessmentScope.value === 'ssd') return d.rotation === '0'
  if (assessmentScope.value === 'nvme') return transport === 'nvme' || d.name.startsWith('nvme')
  return true
}))
const relevantModules = (disk: Disk) => disk.score === null ? disk.modules : disk.modules.filter(m => m.current)
const attentionModules = (disk: Disk) => relevantModules(disk).filter(m => m.status === 'bad' || m.status === 'warn')
const attentionDisks = computed(() => snapshot.value?.disks.filter(d => attentionModules(d).length > 0) || [])
const attentionCount = computed(() => attentionDisks.value.length)
const visibleDisks = computed(() => currentPage.value === 'attention' ? attentionDisks.value : snapshot.value?.disks || [])
const bytesText = (bytes: number | null | undefined, binary = false) => {
  if (bytes == null || !Number.isFinite(bytes)) return '—'
  const base = binary ? 1024 : 1000
  const units = binary ? ['B', 'KiB', 'MiB', 'GiB', 'TiB', 'PiB', 'EiB'] : ['B', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB']
  if (bytes < base) return `${new Intl.NumberFormat(lang.value).format(bytes)} B`
  const power = Math.min(Math.floor(Math.log(bytes) / Math.log(base)), units.length - 1)
  return `${new Intl.NumberFormat(lang.value, { maximumFractionDigits: 2 }).format(bytes / base ** power)} ${units[power]}`
}
const capacityText = (bytes: number | null | undefined, fallback = '—') => bytes == null ? fallback : bytesText(bytes, capacityBinary.value)
const toggleCapacity = () => { capacityBinary.value = !capacityBinary.value }

const date = (stamp: number) => stamp ? new Intl.DateTimeFormat(lang.value, { dateStyle: 'medium', timeStyle: 'short' }).format(stamp * 1000) : t('noCheck')
const maskSerial = (serial?: string) => {
  if (!serial) return '—'
  const visible = serial.length >= 8 ? 4 : serial.length >= 4 ? 2 : 0
  return `${'•'.repeat(Math.min(Math.max(serial.length - visible, 4), 12))}${serial.slice(serial.length - visible)}`
}
const taskSummary = computed(() => {
  const job = status.value.job
  if (!job) return status.value.running ? t('taskSummaryRunningUnknown') : t('noRunning')
  const count = job.targets.split(' ').filter(Boolean).length
  const key = status.value.running || job.state === 'running' || job.state === 'accepted'
    ? 'taskSummaryRunning'
    : job.state === 'completed'
      ? (job.exitCode === 0 ? 'taskSummarySuccess' : 'taskSummaryWarning')
      : job.state === 'stopped' ? 'taskSummaryStopped'
        : job.state === 'unconfirmed' ? 'taskSummaryUnconfirmed' : 'taskSummaryFailed'
  return t(key).replace('{count}', String(count)).replace('{module}', moduleLabel(job.module))
})
const taskRawLog = computed(() => status.value.running ? [status.value.text, status.value.job?.output].filter(Boolean).join('\n\n') : status.value.job?.output || '')
async function togglePastJob(id: string) {
  if (pastJobOpen.value === id) { pastJobOpen.value = null; return }
  pastJobOpen.value = id; pastJobLog.value = ''
  try { const result = await api<{ output: string }>(`/api/jobs/history/${id}`); if (pastJobOpen.value === id) pastJobLog.value = result.output || t('noDetail') }
  catch (e) { if (pastJobOpen.value === id) pastJobLog.value = e instanceof Error ? e.message : t('error') }
}
const temperatureText = (value: number | null | undefined, state?: string) => value != null ? `${value} °C` : state === 'sleeping' ? t('sleeping') : state === 'checking' ? t('checkingTemperature') : '—'
const latest = (disk: Disk) => Math.max(0, ...disk.modules.map(m => m.timestamp))
const condition = (disk: Disk) => attentionModules(disk).some(m => m.status === 'bad') ? 'bad' : attentionModules(disk).length ? 'warn' : disk.modules.length ? 'good' : 'na'
const conditionLabel = (disk: Disk) => condition(disk) === 'na' ? t('coverageNone') : disk.score === null && condition(disk) === 'good' ? t('checkedPartial') : label(condition(disk))
const coverageText = (value: string) => t(({ '未评估': 'coverageNone', '完整': 'coverageFull', '标准': 'coverageStandard', '基础': 'coverageBasic', '部分': 'coveragePartial' }[value] || 'coveragePartial') as Key)
const gradeText = (disk: Disk) => disk.score === null ? t('partial') : disk.score >= 90 ? t('gradeGood') : disk.score >= 75 ? t('gradeAttention') : disk.score >= 50 ? t('gradeWarning') : t('gradeDanger')
const label = (status: string) => t((['good','warn','bad','na','incomplete'].includes(status) ? status : 'runningState') as Key)
const moduleLabel = (name: string) => {
  const key = ({ selftest_short: 'short', selftest_long: 'long' } as Record<string, string>)[name] || name
  return key in strings.en ? t(key) : name
}
const jobStateText = (job: Job) => t(({ accepted: 'taskAccepted', running: 'runningState', completed: job.exitCode === 0 ? 'taskCompleted' : 'taskCompletedWarning', failed: 'taskFailed', stopped: 'taskStopped', unconfirmed: 'taskUnconfirmed' }[job.state]))
function moduleSummary(item: Module) {
  if (item.issues?.trim()) return item.issues.split(';').filter(Boolean).join('；')
  if (item.deduction > 0) return `${t('unrecordedDeduction')} ${item.deduction}`
  if (['warn', 'bad'].includes(item.status) && item.summary === '无异常') return t('unrecordedWarning')
  return item.summary || t('noDetail')
}
async function showDisks() {
  if (currentPage.value !== 'disks') go('disks')
  await nextTick()
  document.getElementById('disk-list')?.scrollIntoView({ behavior: window.matchMedia('(prefers-reduced-motion: reduce)').matches ? 'instant' : 'smooth' })
}
function showAttention() { go('attention') }
function showTasks() { go('tasks') }
const themeLabel = (name: string) => t(({ 'slate-blue': 'themeSlateBlue', sage: 'themeSage', teal: 'themeTeal', plum: 'themePlum' }[name] || 'themeSlateBlue') as Key)
const scopeLabel = (name: Scope) => t(({ sata: 'scopeSata', hdd: 'scopeHdd', ssd: 'scopeSsd', nvme: 'scopeNvme', all: 'scopeAll' }[name]))
const assessmentNote = computed(() => t(`assessmentNote${assessmentModule.value[0].toUpperCase()}${assessmentModule.value.slice(1)}`))
function diskTypeText(disk: Disk) {
  const bus = disk.transport?.toLowerCase() || (disk.link?.kind === 'nvme' ? 'nvme' : disk.link?.kind === 'sata' ? 'sata' : '')
  const medium = disk.rotation === '1' ? t('hdd') : disk.rotation === '0' ? t('ssd') : ''
  if (!medium) return '—'
  if (bus === 'nvme' || disk.name.startsWith('nvme')) return `NVMe ${medium}`
  if (['sata', 'sas', 'usb'].includes(bus)) return `${bus.toUpperCase()} ${medium}`
  return medium
}
function temperatureClass(_disk: Disk, value: number | null | undefined) {
  if (value == null) return ''
  return value < 50 ? 'temp-normal' : value < 60 ? 'temp-blue' : 'temp-hot'
}
function linkText(link?: Link, fallback = '') {
  if (link?.kind === 'nvme') return [`PCIe${link.version ? ` ${link.version}` : ''}${link.width ? ` ×${link.width}` : ''}`, link.speed?.replace(/\s+PCIe$/i, '')].filter(Boolean).join(' · ')
  if (link?.kind === 'sata') return [link.sataVersion || 'SATA', link.speed || t('linkUnavailable')].join(' · ')
  if (['sata', 'nvme'].includes(fallback.toLowerCase())) return `${fallback.toUpperCase()} · ${t('linkUnavailable')}`
  return fallback || '—'
}
function maxLinkText(link?: Link) {
  if (!link?.maxSpeed) return ''
  if (link.kind === 'nvme') return [`PCIe${link.maxVersion ? ` ${link.maxVersion}` : ''}${link.maxWidth ? ` ×${link.maxWidth}` : ''}`, link.maxSpeed.replace(/\s+PCIe$/i, '')].join(' · ')
  return `SATA · ${link.maxSpeed}`
}
function powerTime(hours: number) {
  if (!powerTimeExpanded.value) return `${new Intl.NumberFormat(lang.value).format(hours)} ${t('hourUnit')}`
  const whole = Math.floor(hours)
  const years = Math.floor(whole / 8760)
  const days = Math.floor((whole % 8760) / 24)
  const remaining = whole % 24
  return `${years} ${t('yearUnit')} ${days} ${t('dayUnit')} ${remaining} ${t('hourUnit')}`
}

async function api<T>(path: string, body?: object): Promise<T> {
  const response = await fetch(path, body ? { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body) } : undefined)
  if (!response.headers.get('Content-Type')?.toLowerCase().includes('application/json')) throw new Error(t('unexpectedResponse'))
  let data: { error?: string }
  try { data = await response.json() } catch { throw new Error(t('unexpectedResponse')) }
  if (response.status === 401 && !['/api/auth/login', '/api/auth', '/api/auth/change-password'].includes(path)) auth.value = { authenticated: false, method: null, ipAllowed: auth.value?.ipAllowed || false, canManageAccess: false }
  if (!response.ok) throw new Error(data.error || `HTTP ${response.status}`)
  return data as T
}
async function loadAuth() {
  if (previewMode) { auth.value = { authenticated: true, method: 'local', ipAllowed: false, canManageAccess: true }; preferencesLoaded.value = true; return }
  try { auth.value = await api<Auth>('/api/auth'); if (auth.value.authenticated) { await refresh(); await loadAccess(); await loadPreferences(true); onPopState() } }
  catch (e) { loginError.value = e instanceof Error ? e.message : t('error') }
  finally { loading.value = false }
}
async function login(ip = false) {
  loginBusy.value = true; loginError.value = ''
  try { auth.value = await api<Auth>(ip ? '/api/auth/ip-login' : '/api/auth/login', ip ? {} : { password: password.value }); password.value = ''; await refresh(); await loadAccess(); await loadPreferences(true); onPopState() }
  catch (e) { loginError.value = e instanceof Error ? e.message : t('error') }
  finally { loginBusy.value = false }
}
async function logout() {
  try { await api('/api/auth/logout', {}) } finally { auth.value = { authenticated: false, method: null, ipAllowed: auth.value?.ipAllowed || false, canManageAccess: false }; snapshot.value = null; selected.value = null; password.value = ''; preferencesLoaded.value = false; visitWakeRequested = false; currentPage.value = 'disks'; window.history.replaceState({}, '', '/') }
}
async function requestWakeOnVisit() {
  try { await api('/api/disks/wake-on-visit', {}) }
  catch (e) { preferencesError.value = e instanceof Error ? e.message : t('error') }
}
async function loadPreferences(wakeOnVisit = false) {
  if (previewMode) return
  try {
    const result = await api<{wakeSleepingOnVisit:boolean}>('/api/preferences')
    wakeSleepingOnVisit.value = result.wakeSleepingOnVisit
    savedWakeSleepingOnVisit.value = result.wakeSleepingOnVisit
    preferencesLoaded.value = true
    preferencesError.value = ''
    if (wakeOnVisit && result.wakeSleepingOnVisit && !visitWakeRequested) {
      visitWakeRequested = true
      void requestWakeOnVisit()
    }
  } catch (e) { preferencesError.value = e instanceof Error ? e.message : t('error') }
}
async function savePreferences() {
  preferencesBusy.value = true; preferencesError.value = ''
  try {
    const previous = savedWakeSleepingOnVisit.value
    const result = await api<{wakeSleepingOnVisit:boolean}>('/api/preferences', { wakeSleepingOnVisit: wakeSleepingOnVisit.value })
    savedWakeSleepingOnVisit.value = result.wakeSleepingOnVisit
    message.value = t('save') + ' ✓'
    if (result.wakeSleepingOnVisit && !previous) { visitWakeRequested = true; void requestWakeOnVisit() }
  } catch (e) { preferencesError.value = e instanceof Error ? e.message : t('error') }
  finally { preferencesBusy.value = false }
}
async function loadAccess() {
  if (!auth.value?.authenticated || previewMode) return
  try { allowedIps.value = (await api<{ips:string[]}>('/api/access')).ips } catch (e) { accessError.value = e instanceof Error ? e.message : t('error') }
}
async function saveAccess(ips: string[]) {
  accessError.value = ''
  try { allowedIps.value = (await api<{ips:string[]}>('/api/access', { ips })).ips; newIp.value = ''; message.value = t('save') + ' ✓' }
  catch (e) { accessError.value = e instanceof Error ? e.message : t('error') }
}
async function changePassword() {
  passwordChangeError.value = ''
  if (newPassword.value !== confirmPassword.value) { passwordChangeError.value = t('passwordMismatch'); return }
  passwordChangeBusy.value = true
  try {
    await api('/api/auth/change-password', { currentPassword: currentPassword.value, newPassword: newPassword.value })
    currentPassword.value = ''; newPassword.value = ''; confirmPassword.value = ''
    auth.value = { authenticated: false, method: null, ipAllowed: auth.value?.ipAllowed || false, canManageAccess: false }
    snapshot.value = null; selected.value = null; currentPage.value = 'disks'
    window.history.replaceState({}, '', '/disks')
    loginError.value = t('passwordChangedLogin')
  } catch (e) { passwordChangeError.value = e instanceof Error ? e.message : t('error') }
  finally { passwordChangeBusy.value = false }
}
function go(page: Page) { detailRequest++; currentPage.value = page; selected.value = null; window.history.pushState({}, '', `/${page}`) }
function goDashboard() { if (currentPage.value === 'settings' || currentPage.value === 'changelog') go('disks') }
function closeDisk() { detailRequest++; selected.value = null; window.history.pushState({}, '', `/${currentPage.value}`) }
async function refresh() {
  if (previewMode || refreshPending) return
  refreshPending = true
  try {
    await Promise.allSettled([
      api<Snapshot>('/api/snapshot').then(next => {
        snapshot.value = next; error.value = ''
        if (selected.value && !next.disks.some(d => d.name === selected.value)) selected.value = null
      }).catch(e => { error.value = e instanceof Error ? e.message : t('error') }).finally(() => { loading.value = false }),
      api<typeof status.value>('/api/status').then(task => { status.value = task }),
      api<{ jobs: PastJob[] }>('/api/jobs/history').then(result => { pastJobs.value = result.jobs }),
      api<Schedule>('/api/schedule').then(settings => { if (!editingSchedule.value) schedule.value = settings })
    ])
  } finally { refreshPending = false }
}
async function openDisk(name: string, navigate = true) {
  const request = ++detailRequest
  selected.value = name; history.value = []; smart.value = null; detailTab.value = 'smart'; smartLoading.value = true; powerTimeExpanded.value = false; moduleChoice.value = 'quick'
  if (navigate) window.history.pushState({}, '', `/${currentPage.value}/${name}`)
  const results = await Promise.allSettled([api<{ rows: number[][] }>(`/api/history/${name}`), api<Smart>(`/api/disks/${name}/smart`)])
  if (request !== detailRequest || selected.value !== name) return
  if (results[0].status === 'fulfilled') history.value = results[0].value.rows
  if (results[1].status === 'fulfilled') smart.value = results[1].value
  else smart.value = { available: false, error: String(results[1].reason), model: '', serial: '', protocol: '', capacity: null, passed: null, temperature: null, powerOnHours: null, attributes: [] }
  smartLoading.value = false
}
async function launch() {
  if (!activeDisk.value || busy.value) return
  if (moduleChoice.value !== 'quick' && !await askConfirmation({ title: t('confirmStart'), detail: moduleLabel(moduleChoice.value), targets: [`/dev/${activeDisk.value.name}`], action: t('launch') })) return
  busy.value = true; message.value = ''
  try { await api('/api/jobs', { disk: activeDisk.value.name, module: moduleChoice.value }); await refresh() }
  catch (e) { message.value = e instanceof Error ? e.message : t('error') }
  finally { busy.value = false }
}
async function assess() {
  if (assessmentBusy.value || status.value.running || !assessmentDisks.value.length || previewMode) return
  const names = assessmentDisks.value.map(d => `/dev/${d.name}`)
  if (!await askConfirmation({ title: t('assessmentConfirm'), detail: `${moduleLabel(assessmentModule.value)} · ${assessmentNote.value}`, targets: names, action: t('assessmentStart') })) return
  assessmentBusy.value = true; message.value = ''
  try { const result = await api<{message:string;disks:string[]}>('/api/jobs/assess', { scope: assessmentScope.value, module: assessmentModule.value }); message.value = `${t('assessmentStarted')}: ${moduleLabel(assessmentModule.value)} · ${result.disks.length}`; await refresh() }
  catch (e) { message.value = e instanceof Error ? e.message : t('error') }
  finally { assessmentBusy.value = false }
}
async function stop() {
  if (!await askConfirmation({ title: t('confirmStop'), action: t('stop') })) return
  busy.value = true
  try { await api('/api/jobs/stop', {}); await refresh() }
  catch (e) { message.value = e instanceof Error ? e.message : t('error') }
  finally { busy.value = false }
}
async function saveSchedule() {
  busy.value = true; message.value = ''
  try { schedule.value = await api<Schedule>('/api/schedule', { enabled: schedule.value.enabled, hours: Number(schedule.value.hours) }); editingSchedule.value = false; message.value = t('save') + ' ✓' }
  catch (e) { message.value = e instanceof Error ? e.message : t('error') }
  finally { busy.value = false }
}
function setTheme(value: string) { theme.value = value; document.documentElement.dataset.theme = value; try { localStorage.setItem('hdd-theme', value) } catch { /* ignore */ } }
watch(lang, value => { document.documentElement.lang = value; document.documentElement.dir = value === 'ar' ? 'rtl' : 'ltr'; try { localStorage.setItem('hdd-lang', value) } catch { /* ignore */ } }, { immediate: true })
let timer: ReturnType<typeof setInterval> | undefined
let refreshPending = false
onMounted(() => { loadAuth(); timer = setInterval(() => { if (auth.value?.authenticated) refresh() }, 15000); window.addEventListener('popstate', onPopState) })
function onPopState() {
  currentPage.value = pageFromPath()
  const match = window.location.pathname.match(/^\/(?:disks|attention)\/([A-Za-z0-9_-]+)$/)
  if (match && snapshot.value?.disks.some(d => d.name === match[1])) { if (selected.value !== match[1]) void openDisk(match[1], false) }
  else selected.value = null
}
onUnmounted(() => { if (timer) clearInterval(timer); window.removeEventListener('popstate', onPopState); confirmResolve?.(false) })
</script>

<template>
  <div class="app-shell">
    <header class="topbar">
      <a class="brand" href="/disks"><span class="brand-icon"><HardDrive :size="22" /></span><span><strong>HDD Health</strong><small>{{ t('localMonitor') }}</small></span></a>
      <nav v-if="auth?.authenticated" class="main-nav" :aria-label="t('navigation')"><button :class="{active:['disks','attention','tasks','schedule'].includes(currentPage)}" :aria-current="['disks','attention','tasks','schedule'].includes(currentPage) ? 'page' : undefined" @click="goDashboard">{{ t('dashboard') }}</button><button :class="{active:currentPage==='changelog'}" :aria-current="currentPage==='changelog' ? 'page' : undefined" @click="go('changelog')">{{ t('changelog') }}</button><button :class="{active:currentPage==='settings'}" :aria-current="currentPage==='settings' ? 'page' : undefined" @click="go('settings')">{{ t('settingsPage') }}</button></nav>
      <div class="top-actions"><span v-if="auth?.authenticated" class="version">{{ buildVersion }}</span><button v-if="auth?.authenticated" class="icon-button" :aria-label="t('refresh')" :disabled="previewMode" @click="refresh"><RefreshCw :size="18" /></button><button v-if="auth?.authenticated && !previewMode" class="icon-button" :aria-label="t('logout')" :title="t('logout')" @click="logout"><LogOut :size="18" /></button></div>
    </header>
    <main v-if="!auth" class="container"><div class="empty">{{ t('refresh') }}…</div></main>
    <main v-else-if="!auth.authenticated" class="login-screen"><form class="panel login-card" @submit.prevent="login()"><div class="login-symbol"><LockKeyhole :size="25" /></div><div class="eyebrow">HDD HEALTH</div><h1>{{ t('loginTitle') }}</h1><p>{{ t('loginDescription') }}</p><label for="login-language">{{ t('language') }}</label><UiSelect id="login-language" :model-value="lang" :options="languageOptions" :aria-label="t('language')" @update:model-value="selectLanguage" /><label for="login-password">{{ t('password') }}</label><input id="login-password" v-model="password" type="password" autocomplete="current-password" required /><p v-if="loginError" class="login-error" role="alert">{{ loginError }}</p><button class="button primary" :disabled="loginBusy" type="submit">{{ t('login') }}</button><button v-if="auth.ipAllowed" class="button" type="button" :disabled="loginBusy" @click="login(true)">{{ t('ipLogin') }}</button></form></main>
    <main v-else class="container">
      <div v-if="previewMode" class="preview-note" role="status"><ShieldAlert :size="18" /><span>{{ t('previewOnly') }}</span></div>
      <div v-if="error" class="alert"><ShieldAlert :size="18" /><span>{{ error }}</span><button class="text-button" @click="refresh">{{ t('retry') }}</button></div>
      <template v-if="currentPage!=='settings' && currentPage!=='changelog'">
        <div class="page-heading"><div><div class="eyebrow"><Activity :size="14" /> {{ currentPage==='disks' ? t('systemOverview') : t('operations') }}</div><h1>{{ currentPage==='disks' ? t('overview') : currentPage==='attention' ? t('attention') : currentPage==='tasks' ? t('running') : t('schedule') }}</h1><p>{{ currentPage==='disks' ? t('subtitle') : currentPage==='attention' ? t('viewAttention') : currentPage==='tasks' ? t('task') : t('automation') }}</p></div><span v-if="!previewMode" class="live-pill"><span class="live-dot"></span>{{ t('local') }}</span></div>
        <div class="stats-grid"><button class="stat-card stat-action" type="button" :aria-current="currentPage==='disks' ? 'page' : undefined" @click="showDisks"><div class="stat-label"><HardDrive :size="18" />{{ t('disks') }}</div><strong>{{ snapshot?.disks.length ?? '—' }}</strong><span>{{ t('all') }} →</span></button><button class="stat-card stat-action" type="button" :aria-current="currentPage==='attention' ? 'page' : undefined" @click="showAttention"><div class="stat-label"><ShieldAlert :size="18" />{{ t('attention') }}</div><strong>{{ attentionCount }}</strong><span>{{ t('viewAttention') }} →</span></button><button class="stat-card stat-action" type="button" :aria-current="currentPage==='tasks' ? 'page' : undefined" @click="showTasks"><div class="stat-label"><Activity :size="18" />{{ t('running') }}</div><strong class="stat-word">{{ status.running ? t('runningState') : status.job ? jobStateText(status.job) : '—' }}</strong><span>{{ status.job ? `${status.job.targets.split(' ').filter(Boolean).length} ${t('disks')}` : t('noRunning') }} →</span></button><button class="stat-card stat-action" type="button" :aria-current="currentPage==='schedule' ? 'page' : undefined" @click="go('schedule')"><div class="stat-label"><Clock3 :size="18" />{{ t('schedule') }}</div><strong class="stat-word">{{ schedule.enabled ? `${schedule.hours}h` : '—' }}</strong><span>{{ schedule.enabled ? t('enabled') : t('noCheck') }} →</span></button></div>
        <section v-if="currentPage==='disks'" class="panel storage-summary"><div><small>{{ t('physicalCapacity') }}</small><button class="capacity-toggle" type="button" :title="t('toggleCapacity')" :aria-label="t('toggleCapacity')" @click="toggleCapacity">{{ capacityText(snapshot?.storage?.totalBytes) }}</button></div><div><small>{{ t('mountedUsed') }}</small><strong>{{ capacityText(snapshot?.storage?.usedBytes) }}</strong></div><p>{{ t('storageNote') }}</p></section>
        <section v-if="currentPage==='disks'" class="panel assessment-panel"><div><div class="eyebrow">{{ t('assessmentEyebrow') }}</div><h2>{{ t('assessmentTitle') }}</h2><p class="muted">{{ t('assessmentDescription') }}</p></div><div class="assessment-controls"><div class="assessment-field"><label for="assessment-scope">{{ t('assessmentScope') }}</label><UiSelect id="assessment-scope" :model-value="assessmentScope" :options="scopeSelectOptions" :aria-label="t('assessmentScope')" :disabled="assessmentBusy || status.running || previewMode" @update:model-value="selectScope" /></div><div class="assessment-field"><label for="assessment-module">{{ t('assessmentModule') }}</label><UiSelect id="assessment-module" v-model="assessmentModule" :options="assessmentSelectOptions" :aria-label="t('assessmentModule')" :disabled="assessmentBusy || status.running || previewMode" /></div><span class="assessment-count">{{ t('assessmentCount') }}: {{ assessmentDisks.length }}</span><button class="button primary" :disabled="assessmentBusy || status.running || !assessmentDisks.length || previewMode" @click="assess"><Play :size="15" />{{ assessmentBusy ? t('assessmentStarting') : t('assessmentStart') }}</button></div><p class="assessment-note">{{ assessmentNote }}</p></section>
        <section v-if="currentPage==='disks' || currentPage==='attention'" id="disk-list" class="panel disk-list"><div class="panel-heading"><div><div class="eyebrow">{{ t('drives') }}</div><h2>{{ currentPage==='attention' ? t('attention') : t('all') }}</h2></div><div class="list-actions"><button v-if="currentPage==='attention'" class="text-button" type="button" @click="go('disks')">{{ t('showAllDisks') }}</button><span class="count">{{ visibleDisks.length }}</span></div></div><div v-if="loading" class="empty">{{ t('refresh') }}…</div><div v-else-if="!visibleDisks.length" class="empty">{{ currentPage==='attention' ? t('noAttention') : previewMode ? t('previewOnly') : t('empty') }}</div><div class="disk-cards"><div v-for="disk in visibleDisks" :key="disk.name" class="disk-card"><div class="disk-icon"><HardDrive :size="24" /></div><div class="disk-card-main"><div class="disk-card-title"><strong>{{ disk.model || `/dev/${disk.name}` }}</strong><span class="badge" :class="condition(disk)">{{ conditionLabel(disk) }}</span></div><div class="disk-card-fields"><span><small>{{ t('capacity') }}</small><button class="capacity-toggle" type="button" :title="t('toggleCapacity')" :aria-label="t('toggleCapacity')" @click="toggleCapacity">{{ capacityText(disk.bytes, disk.size) }}</button></span><span><small>{{ t('diskType') }}</small>{{ diskTypeText(disk) }}</span><span><small>{{ t('devicePath') }}</small>/dev/{{ disk.name }}</span><span><small>{{ t('temp') }}</small><strong :class="temperatureClass(disk, disk.temperature)">{{ temperatureText(disk.temperature, disk.temperatureState) }}</strong></span><span><small>{{ t('interface') }}</small>{{ linkText(disk.link, disk.transport) }}</span><span><small>{{ t('serial') }}</small>{{ maskSerial(disk.serial) }}</span><span><small>{{ t('last') }}</small>{{ date(latest(disk)) }}</span></div><div v-if="currentPage==='attention' && attentionModules(disk).length" class="disk-card-reasons"><strong>{{ t('attentionReasons') }}</strong><ul><li v-for="item in attentionModules(disk)" :key="item.name">{{ moduleLabel(item.name) }}: {{ moduleSummary(item) }} <small>({{ item.current ? t('fresh') : t('stale') }})</small></li></ul></div></div><div class="disk-card-end"><span>{{ t('healthStatus') }}</span><strong :class="condition(disk)">{{ disk.score===null ? `${coverageText(disk.coverage)} / ${t('unknownScore')}` : gradeText(disk) }}</strong><button class="disk-detail-button" type="button" @click="openDisk(disk.name)">{{ t('details') }} →</button></div></div></div></section>
        <section v-if="currentPage==='tasks'" id="task-panel" class="panel task-panel task-overview"><div class="panel-heading"><div><div class="eyebrow">{{ t('operations') }}</div><h2>{{ t('task') }}</h2></div><Activity :size="19" /></div><div v-if="status.job" class="job-summary"><span class="badge" :class="status.job.state === 'failed' || status.job.state === 'unconfirmed' ? 'bad' : status.job.exitCode > 0 ? 'warn' : 'good'">{{ status.running ? t('runningState') : jobStateText(status.job) }}</span><strong>{{ moduleLabel(status.job.module) }} · {{ status.job.targets.split(' ').filter(Boolean).map(name => `/dev/${name}`).join(', ') }}</strong><small>{{ date(status.job.finished || status.job.started) }}</small></div><p class="task-natural" role="status">{{ taskSummary }}</p><div v-if="taskRawLog" class="task-log-controls"><button class="button" type="button" :aria-expanded="taskDetailsOpen" @click="taskDetailsOpen=!taskDetailsOpen">{{ taskDetailsOpen ? t('hideDetailedLog') : t('showDetailedLog') }}</button></div><pre v-if="taskDetailsOpen && taskRawLog" class="task-output">{{ taskRawLog }}</pre><button v-if="status.running" class="button danger" :disabled="busy" @click="stop"><Square :size="15" />{{ t('stop') }}</button></section>
        <section v-if="currentPage==='tasks'" class="panel task-history"><div class="panel-heading"><div><div class="eyebrow">{{ t('operations') }}</div><h2>{{ t('taskHistory') }}</h2></div><History :size="19" /></div><div v-if="!pastJobs.length" class="empty">{{ t('noTaskHistory') }}</div><div v-for="job in pastJobs" :key="job.id" class="past-job"><div class="past-job-head"><span class="badge" :class="job.state==='failed' ? 'bad' : job.state==='stopped' || job.exitCode > 0 ? 'warn' : 'good'">{{ jobStateText({ ...job, output: '' }) }}</span><strong>{{ moduleLabel(job.module) }} · {{ job.targets.split(' ').filter(Boolean).length }} {{ t('disks') }}</strong><small>{{ date(job.finished) }}</small></div><p>{{ job.targets.split(' ').filter(Boolean).map(name => `/dev/${name}`).join(', ') }}</p><button class="button" type="button" :aria-expanded="pastJobOpen===job.id" @click="togglePastJob(job.id)">{{ pastJobOpen===job.id ? t('hideDetailedLog') : t('showDetailedLog') }}</button><pre v-if="pastJobOpen===job.id" class="task-output">{{ pastJobLog || t('refresh') + '…' }}</pre></div></section>
        <section v-if="currentPage==='schedule'" class="panel schedule-panel"><div class="panel-heading"><div><div class="eyebrow">{{ t('automation') }}</div><h2>{{ t('schedule') }}</h2></div><Settings2 :size="19" /></div><label class="switch-line"><input v-model="schedule.enabled" type="checkbox" :disabled="previewMode" @change="editingSchedule = true" /><span>{{ t('enabled') }}</span></label><label class="field-label" for="hours">{{ t('interval') }}</label><div class="input-wrap"><input id="hours" v-model.number="schedule.hours" type="number" min="6" max="168" :disabled="previewMode" @input="editingSchedule = true" /><span>{{ t('hours') }}</span></div><p v-if="schedule.error" class="schedule-error" role="alert">{{ schedule.error }}</p><button class="button primary" :disabled="busy || previewMode" @click="saveSchedule">{{ t('save') }}</button></section>
        <p v-if="currentPage==='disks' || currentPage==='attention'" class="footnote">{{ t('scoreNote') }}</p>
      </template>
      <template v-else-if="currentPage==='changelog'"><div class="page-heading"><div><div class="eyebrow">{{ t('releaseNotes') }}</div><h1>{{ t('changelog') }}</h1></div></div><article class="panel changelog-page markdown-body" v-html="changelogHtml"></article></template>
      <template v-else>
        <div class="page-heading"><div><div class="eyebrow"><Settings2 :size="14" /> {{ t('preferences') }}</div><h1>{{ t('settingsPage') }}</h1><p>{{ t('settingsDescription') }}</p></div></div>
        <div class="settings-grid"><section class="panel settings-card"><div class="panel-heading"><div><div class="eyebrow">{{ t('preferences') }}</div><h2>{{ t('mode') }}</h2></div></div><div class="settings-body"><label for="lang">{{ t('language') }}</label><UiSelect id="lang" :model-value="lang" :options="languageOptions" :aria-label="t('language')" @update:model-value="selectLanguage" /><span class="settings-label">{{ t('theme') }}</span><div class="theme-options"><button v-for="item in themes" :key="item" class="theme-button" :class="{ selected: theme === item }" :aria-pressed="theme === item" @click="setTheme(item)"><span class="theme-swatch" :class="item"></span>{{ themeLabel(item) }}</button></div></div></section>
        <section class="panel settings-card access-card"><div class="panel-heading"><div><div class="eyebrow">{{ t('security') }}</div><h2>{{ t('ipAccess') }}</h2></div><LockKeyhole :size="19" /></div><div class="settings-body"><p class="muted">{{ t('ipAccessDescription') }}</p><p class="subtle-note">{{ t('ipAccessWarning') }}</p><div v-for="ip in allowedIps" :key="ip" class="ip-row"><code>{{ ip }}</code><button class="text-button" :aria-label="t('remove')+' '+ip" @click="saveAccess(allowedIps.filter(x=>x!==ip))">{{ t('remove') }}</button></div><div class="ip-add"><input v-model.trim="newIp" :placeholder="t('ipPlaceholder')" inputmode="decimal" :aria-label="t('ipAccess')" /><button class="button primary" :disabled="!newIp || previewMode" @click="saveAccess([...allowedIps,newIp])">{{ t('addIp') }}</button></div><p v-if="accessError" class="login-error" role="alert">{{ accessError }}</p></div></section><section class="panel settings-card power-card"><div class="panel-heading"><div><div class="eyebrow">{{ t('preferences') }}</div><h2>{{ t('diskPowerPolicy') }}</h2></div><HardDrive :size="19" /></div><div class="settings-body"><p class="muted">{{ t('diskPowerPolicyDescription') }}</p><fieldset class="power-options" :disabled="!preferencesLoaded || preferencesBusy || previewMode"><label><input v-model="wakeSleepingOnVisit" type="radio" :value="false" /><span><strong>{{ t('keepSleeping') }}</strong><small>{{ t('keepSleepingDescription') }}</small></span></label><label><input v-model="wakeSleepingOnVisit" type="radio" :value="true" /><span><strong>{{ t('wakeOnVisit') }}</strong><small>{{ t('wakeOnVisitDescription') }}</small></span></label></fieldset><p v-if="preferencesError" class="login-error" role="alert">{{ preferencesError }}</p><button class="button primary" type="button" :disabled="!preferencesLoaded || preferencesBusy || previewMode || wakeSleepingOnVisit===savedWakeSleepingOnVisit" @click="savePreferences">{{ t('savePowerPolicy') }}</button></div></section><section class="panel settings-card password-card"><div class="panel-heading"><div><div class="eyebrow">{{ t('security') }}</div><h2>{{ t('changePassword') }}</h2></div><LockKeyhole :size="19" /></div><form class="settings-body" @submit.prevent="changePassword"><p class="muted">{{ t('changePasswordDescription') }}</p><label for="current-password">{{ t('currentPassword') }}</label><input id="current-password" v-model="currentPassword" type="password" autocomplete="current-password" required /><label for="new-password">{{ t('newPassword') }}</label><input id="new-password" v-model="newPassword" type="password" autocomplete="new-password" minlength="12" maxlength="128" required /><label for="confirm-password">{{ t('confirmPassword') }}</label><input id="confirm-password" v-model="confirmPassword" type="password" autocomplete="new-password" minlength="12" maxlength="128" required /><p v-if="passwordChangeError" class="login-error" role="alert">{{ passwordChangeError }}</p><button class="button primary" type="submit" :disabled="passwordChangeBusy || previewMode">{{ t('savePassword') }}</button></form></section></div>
      </template>
    </main>
    <div v-if="activeDisk" class="drawer-backdrop" @click.self="closeDisk"><section class="drawer" role="dialog" aria-modal="true" :aria-label="activeDisk.name"><div class="drawer-header"><div><div class="eyebrow">{{ t('driveDetail') }}</div><h2>{{ activeDisk.model || `/dev/${activeDisk.name}` }}</h2><p>/dev/{{ activeDisk.name }} · {{ activeDisk.size }} · {{ activeDisk.transport }}</p></div><button class="icon-button" :aria-label="t('close')" @click="closeDisk"><X :size="21" /></button></div><div class="detail-tabs" role="tablist"><button role="tab" :aria-selected="detailTab==='smart'" :class="{active:detailTab==='smart'}" @click="detailTab='smart'">{{ t('smartInfo') }}</button><button role="tab" :aria-selected="detailTab==='checks'" :class="{active:detailTab==='checks'}" @click="detailTab='checks'">{{ t('checks') }}</button></div><div v-if="detailTab==='smart'" class="drawer-body"><div v-if="smartLoading" class="empty">{{ t('refresh') }}…</div><template v-else-if="smart"><div class="smart-status"><span>{{ t('healthStatus') }}</span><strong :class="smart.passed===true?'good':smart.passed===false?'bad':'na'">{{ smart.passed===true ? t('smartPassed') : smart.passed===false ? t('smartFailed') : smart.temperatureState==='sleeping' ? t('sleeping') : t('smartUnknown') }}</strong></div><p v-if="smart.temperatureState==='sleeping'" class="subtle-note">{{ t('sleepingSmartNote') }}</p><p v-else-if="smart.error && !smart.available" class="subtle-note">{{ smart.error }}</p><div class="smart-facts"><div><small>{{ t('model') }}</small><strong>{{ smart.model || activeDisk.model || '—' }}</strong></div><div><small>{{ t('serial') }}</small><strong>{{ smart.serial || activeDisk.serial || '—' }}</strong></div><div><small>{{ t('diskType') }}</small><strong>{{ diskTypeText(activeDisk) }}</strong></div><div v-if="smart.formFactor"><small>{{ t('formFactor') }}</small><strong>{{ smart.formFactor }}</strong></div><div><small>{{ t('currentLink') }}</small><strong>{{ linkText(smart.link || activeDisk.link, smart.protocol || activeDisk.transport) }}</strong></div><div v-if="maxLinkText(smart.link || activeDisk.link)"><small>{{ t('maxLink') }}</small><strong>{{ maxLinkText(smart.link || activeDisk.link) }}</strong></div><div><small>{{ t('temp') }}</small><strong :class="temperatureClass(activeDisk, smart.temperature)">{{ temperatureText(smart.temperature, smart.temperatureState) }}</strong></div><div v-if="activeDisk.rotation==='0'"><small>{{ t('hostWrites') }}</small><strong>{{ bytesText(smart.writtenBytes) }}</strong><small v-if="smart.writtenBytes==null">{{ t('writesUnavailable') }}</small></div><div><small>{{ t('powerOnHours') }}</small><button v-if="smart.powerOnHours!=null" class="time-toggle" type="button" :title="t('togglePowerTime')" :aria-label="t('togglePowerTime')" :aria-pressed="powerTimeExpanded" @click="powerTimeExpanded=!powerTimeExpanded">{{ powerTime(smart.powerOnHours) }}</button><strong v-else>{{ smart.temperatureState==='sleeping' ? t('sleeping') : '—' }}</strong></div></div><div class="section-head"><h3>{{ t('smartAttributes') }}</h3></div><div v-if="!smart.attributes.length" class="empty compact">{{ smart.temperatureState==='sleeping' ? t('sleepingSmartNote') : t('smartUnavailable') }}</div><div v-else class="table-scroll"><table><thead><tr><th>{{ t('attribute') }}</th><th>{{ t('value') }}</th><th>{{ t('normalized') }}</th><th>{{ t('threshold') }}</th></tr></thead><tbody><tr v-for="(item,index) in smart.attributes" :key="item.key+index"><td class="attr-name">{{ item.key }}</td><td>{{ item.value }}</td><td>{{ item.normalized ?? '—' }}</td><td>{{ item.threshold ?? '—' }}</td></tr></tbody></table></div></template></div><div v-else class="drawer-body"><div class="score-panel"><div><small>{{ t('current') }}</small><strong>{{ activeDisk.score === null ? '—' : activeDisk.score }}</strong><span>{{ gradeText(activeDisk) }}</span></div><div><small>{{ t('status') }}</small><span class="badge large" :class="condition(activeDisk)">{{ conditionLabel(activeDisk) }}</span><span>{{ coverageText(activeDisk.coverage) }}</span></div></div><p class="subtle-note">{{ t('scoreNote') }}</p><div v-if="attentionModules(activeDisk).length > 0" class="attention-detail"><strong>{{ t('attentionReasons') }}</strong><ul><li v-for="item in attentionModules(activeDisk)" :key="item.name">{{ moduleLabel(item.name) }}: {{ moduleSummary(item) }} <small>({{ item.current ? t('fresh') : t('stale') }})</small></li></ul></div><div class="section-head"><h3>{{ t('checks') }}</h3><History :size="17" /></div><div v-if="!activeDisk.modules.length" class="empty compact">{{ t('noCheck') }}</div><div v-for="item in activeDisk.modules" :key="item.name" class="module-row"><div><strong>{{ moduleLabel(item.name) }}</strong><small>{{ date(item.timestamp) }} · {{ item.current ? t('fresh') : t('stale') }}</small><p>{{ moduleSummary(item) }}</p><small v-if="item.deduction > 0">{{ t('deduction') }}: {{ item.deduction }}</small></div><span class="badge" :class="item.status">{{ label(item.status) }}</span></div><div class="section-head"><h3>{{ t('launch') }}</h3><Play :size="17" /></div><p class="subtle-note">{{ t('scanNote') }}</p><div class="launch-row"><UiSelect v-model="moduleChoice" :options="diskSelectOptions" :aria-label="t('checkType')" :disabled="busy || status.running" /><button class="button primary" :disabled="busy || status.running" @click="launch"><Play :size="15" />{{ t('launch') }}</button></div><div class="section-head"><h3>{{ t('history') }}</h3><History :size="17" /></div><div v-if="!history.length" class="empty compact">{{ t('noHistory') }}</div><div v-else class="table-scroll"><table><thead><tr><th>{{ t('date') }}</th><th>{{ t('realloc') }}</th><th>{{ t('pending') }}</th><th>{{ t('uncorrect') }}</th><th>{{ t('crc') }}</th><th>{{ t('temp') }}</th></tr></thead><tbody><tr v-for="(row, index) in history.slice().reverse()" :key="index"><td>{{ date(row[0]) }}</td><td>{{ row[2] }}</td><td>{{ row[3] }}</td><td>{{ row[4] }}</td><td>{{ row[6] }}</td><td>{{ row[7] }}°</td></tr></tbody></table></div></div></section></div>
    <div v-if="confirmation" class="confirm-backdrop" @click.self="answerConfirmation(false)"><section ref="confirmDialog" class="confirm-dialog" role="dialog" aria-modal="true" aria-labelledby="confirm-title" @keydown="onConfirmKeydown"><div class="confirm-heading"><div class="eyebrow">{{ t('checkType') }}</div><h2 id="confirm-title">{{ confirmation.title }}</h2></div><p v-if="confirmation.detail" class="confirm-detail">{{ confirmation.detail }}</p><div v-if="confirmation.targets?.length" class="confirm-targets"><strong>{{ t('assessmentCount') }}: {{ confirmation.targets.length }}</strong><div>{{ confirmation.targets.join(' · ') }}</div></div><div class="confirm-actions"><button ref="confirmCancelButton" class="button" type="button" @click="answerConfirmation(false)">{{ t('cancel') }}</button><button class="button primary" type="button" @click="answerConfirmation(true)">{{ confirmation.action }}</button></div></section></div>
    <div v-if="message" class="toast" role="status">{{ message }}<button :aria-label="t('close')" @click="message = ''"><X :size="16" /></button></div>
  </div>
</template>
