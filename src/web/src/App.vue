<script setup lang="ts">
import { computed, nextTick, onMounted, onUnmounted, ref, watch } from 'vue'
import MarkdownIt from 'markdown-it'
import UiSelect from './UiSelect.vue'
import PasswordField from './PasswordField.vue'
import { installResizeMotion, refreshResizeBaseline, routeUrl } from './uiMotion'
import { Activity, ArrowLeft, ArrowRight, Check, CircleHelp, Clock3, Copy, HardDrive, History, Play, RefreshCw, Settings2, ShieldAlert, Square, X, LogOut, LockKeyhole } from '@lucide/vue'

type Module = { name: string; timestamp: number; status: string; summary: string; deduction: number; issues: string; current: boolean }
type Link = { kind?: string; version?: string; sataVersion?: string; speed?: string; width?: string; maxSpeed?: string; maxVersion?: string; maxWidth?: string }
type Disk = { name: string; model: string; size: string; bytes?: number | null; serial?: string; vendor?: string; rotation: string; transport: string; link?: Link; temperature?: number | null; temperatureState?: string; temperatureWarning?: number | null; temperatureCritical?: number | null; score: number | null; coverage: string; grade: string; level: number; stale: number; modules: Module[] }
type Snapshot = { version: string; disks: Disk[]; storage?: { totalBytes: number; usedBytes: number | null } }
type Schedule = { enabled: boolean; hours: number; last: number; attempt: number; error: string }
type Auth = { authenticated: boolean; method: string | null; ipAllowed: boolean; canManageAccess: boolean }
type Smart = { available: boolean; error: string; model: string; serial: string; protocol: string; capacity: number | null; passed: boolean | null; temperature: number | null; temperatureState?: string; temperatureWarning?: number | null; temperatureCritical?: number | null; formFactor?: string; powerOnHours: number | null; writtenBytes?: number | null; writtenSource?: string; readBytes?: number | null; readSource?: string; link?: Link; attributes: { key: string; value: string; id?: number; normalized?: number; threshold?: number }[] }
type Job = { id: string; state: 'accepted' | 'running' | 'completed' | 'failed' | 'stopped' | 'unconfirmed'; module: string; targets: string; started: number; finished: number; exitCode: number; output: string }
type PastJob = Omit<Job, 'output'>
type SmartSample = { disk: string; index: number; values: number[] }
type Lang = 'zh-CN' | 'zh-TW' | 'zh-HK' | 'en' | 'hi' | 'es' | 'ar' | 'fr'
import zhCN from '../../../lang/web/zh-CN.json'
import zhTW from '../../../lang/web/zh-TW.json'
import zhHK from '../../../lang/web/zh-HK.json'
import en from '../../../lang/web/en.json'
import hi from '../../../lang/web/hi.json'
import es from '../../../lang/web/es.json'
import ar from '../../../lang/web/ar.json'
import fr from '../../../lang/web/fr.json'
import logEn from '../../../doc/LOG.md?raw'
import logZhCN from '../../../doc/zh-CN/LOG.md?raw'
import logZhTW from '../../../doc/zh-TW/LOG.md?raw'
import logZhHK from '../../../doc/zh-HK/LOG.md?raw'
import logHi from '../../../doc/hi/LOG.md?raw'
import logEs from '../../../doc/es/LOG.md?raw'
import logAr from '../../../doc/ar/LOG.md?raw'
import logFr from '../../../doc/fr/LOG.md?raw'
const strings = { 'zh-CN': zhCN, 'zh-TW': zhTW, 'zh-HK': zhHK, en, hi, es, ar, fr }
const logs: Record<Lang, string> = { 'zh-CN': logZhCN, 'zh-TW': logZhTW, 'zh-HK': logZhHK, en: logEn, hi: logHi, es: logEs, ar: logAr, fr: logFr }
const changelogHeadings: Record<Lang, string> = { 'zh-CN': '变更日志', 'zh-TW': '變更紀錄', 'zh-HK': '變更記錄', en: 'Changelog', hi: 'परिवर्तन सूची', es: 'Historial de cambios', ar: 'سجل التغييرات', fr: 'Historique des modifications' }
type Key = keyof typeof strings.en
const languages: { code: Lang; label: string }[] = [{code:'zh-CN',label:'简体中文'},{code:'zh-TW',label:'繁體中文（台灣）'},{code:'zh-HK',label:'繁體中文（香港）'},{code:'en',label:'English'},{code:'hi',label:'हिन्दी'},{code:'es',label:'Español'},{code:'ar',label:'العربية'},{code:'fr',label:'Français'}]
const lang = ref<Lang>('zh-CN')
try { const saved = localStorage.getItem('hdd-lang') as Lang | null; if (saved && saved in strings) lang.value = saved } catch { /* ignore */ }
const t = (key: string): string => (strings[lang.value] as Record<string,string>)[key] || (strings.en as Record<string,string>)[key] || key
const themes = ['slate-blue', 'sage', 'teal', 'plum', 'ocean', 'olive', 'terracotta', 'indigo'] as const
const theme = ref<string>(document.documentElement.dataset.theme || 'slate-blue')
const appearanceMode = ref<'light' | 'dark'>(document.documentElement.classList.contains('dark') ? 'dark' : 'light')
const snapshot = ref<Snapshot | null>(null)
const schedule = ref<Schedule>({ enabled: false, hours: 24, last: 0, attempt: 0, error: '' })
const status = ref<{ running: boolean; text: string; job: Job | null }>({ running: false, text: '', job: null })
const selected = ref<string | null>(null)
const serialShown = ref(false)
const revealedSerial = ref('')
const serialCopied = ref(false)
let copyFeedbackTimer: ReturnType<typeof setTimeout> | undefined
const smartSamples = ref<SmartSample[]>([])
const moduleChoice = ref('quick')
const busy = ref(false)
const editingSchedule = ref(false)
const loading = ref(true)
const error = ref('')
const message = ref('')
const messageSequence = ref(0)
let messageTimer: ReturnType<typeof setTimeout> | undefined
function showMessage(value: string) {
  if (messageTimer) clearTimeout(messageTimer)
  message.value = value
  messageSequence.value++
  messageTimer = value ? setTimeout(() => { message.value = ''; messageTimer = undefined }, 3000) : undefined
}
function closeMessage() { if (messageTimer) clearTimeout(messageTimer); messageTimer = undefined; message.value = '' }
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
  const heading = [...source.matchAll(/^## (.+)\s*$/gm)].find(item => item[1].trim() === changelogHeadings[lang.value])
  const tail = heading && heading.index !== undefined ? source.slice(heading.index + heading[0].length) : source
  const next = tail.search(/^## /m)
  const releaseStart = tail.search(/^### v\d+\.\d+\.\d+\b/m)
  const formal = releaseStart >= 0 ? tail.slice(releaseStart, next < 0 ? undefined : next) : next < 0 ? tail : tail.slice(0, next)
  const candidate = buildVersion.includes('test') ? `### ${buildVersion}\n\n${t('candidateIntro')}\n\n- ${t('candidateLogin')}\n- ${t('candidateNavigation')}\n- ${t('candidateMotion')}\n- ${t('candidateAccess')}\n- ${t('candidateDiskDetail')}\n- ${t('candidateSmart')}\n\n` : ''
  return markdown.render(candidate + formal)
})
const changelogCards = computed(() => {
  const sections = changelogHtml.value.split(/(?=<h3>)/).filter(Boolean)
  return sections.map((html, index) => ({ html, candidate: index === 0 && buildVersion.includes('test') }))
})
const auth = ref<Auth | null>(null)
const password = ref('')
const loginError = ref('')
const loginBusy = ref(false)
type Page = 'disks' | 'attention' | 'tasks' | 'schedule' | 'settings' | 'security' | 'changelog'
function pageFromPath(): Page { const segment = window.location.pathname.split('/')[1]; return (['attention','tasks','schedule','settings','security','changelog'].includes(segment) ? segment : 'disks') as Page }
const currentPage = ref<Page>(pageFromPath())
const settingsSection = ref<'general' | 'appearance' | 'power' | 'security'>('general')
const securitySection = ref<'password' | 'ip'>('password')
const faviconNames: Record<Page, string> = { disks: 'favicon.svg', attention: 'favicon-attention.svg', tasks: 'favicon-tasks.svg', schedule: 'favicon-schedule.svg', settings: 'favicon-settings.svg', security: 'favicon-security.svg', changelog: 'favicon-changelog.svg' }
watch(currentPage, page => { document.querySelector<HTMLLinkElement>('link[rel="icon"]')?.setAttribute('href', `/${faviconNames[page]}`) }, { immediate: true })
const smart = ref<Smart | null>(null)
const smartLoading = ref(false)
let detailRequest = 0
const detailTab = ref<'smart' | 'checks'>('smart')
const allowedIps = ref<string[]>([])
const accessEnabled = ref(false)
const securityPassword = ref('')
const securityError = ref('')
const securityBusy = ref(false)
const newIp = ref('')
const accessError = ref('')
const wakeSleepingOnVisit = ref(false)
const savedWakeSleepingOnVisit = ref(false)
const preferencesLoaded = ref(false)
const preferencesBusy = ref(false)
const preferencesError = ref('')
let visitWakeRequested = false
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
const wakeDiskBusy = ref(false)
const sleepDiskBusy = ref(false)
const justWokenDisk = ref<string | null>(null)
const expandedModule = ref<string | null>(null)
const powerTimeExpanded = ref(false)
const capacityBinary = ref(false)
const scopeOptions: Scope[] = ['sata', 'hdd', 'ssd', 'nvme', 'all']
const assessmentModules: readonly string[] = ['quick', 'short', 'long', 'speed', 'surface', 'badblocks', 'iface', 'full']
const ssdModules: readonly string[] = ['quick', 'short', 'long', 'surface', 'full']
const activeDisk = computed(() => snapshot.value?.disks.find(d => d.name === selected.value) || null)
const languageOptions = languages.map(item => ({ value: item.code, label: item.label }))
const scopeSelectOptions = computed(() => scopeOptions.map(value => ({ value, label: scopeLabel(value) })))
const assessmentDisks = computed(() => (snapshot.value?.disks || []).filter(d => {
  const transport = d.transport?.toLowerCase()
  if (assessmentScope.value === 'sata') return transport === 'sata'
  if (assessmentScope.value === 'hdd') return d.rotation === '1'
  if (assessmentScope.value === 'ssd') return d.rotation === '0'
  if (assessmentScope.value === 'nvme') return transport === 'nvme' || d.name.startsWith('nvme')
  return true
}))
const availableAssessmentModules = computed(() => assessmentDisks.value.some(d => d.rotation === '1') ? assessmentModules : ssdModules)
const assessmentEligible = computed(() => assessmentDisks.value.filter(d => d.rotation === '1' || ssdModules.includes(assessmentModule.value)))
const assessmentSkipped = computed(() => assessmentDisks.value.length - assessmentEligible.value.length)
const diskHistory = computed(() => smartSamples.value.filter(row => row.disk === selected.value))
const allHistory = computed(() => [
  ...pastJobs.value.map(job => ({ type: 'job' as const, stamp: job.finished || job.started, job })),
  ...smartSamples.value.map(sample => ({ type: 'sample' as const, stamp: sample.values[0], sample }))
].sort((a, b) => b.stamp - a.stamp))
const assessmentSelectOptions = computed(() => availableAssessmentModules.value.map(value => ({ value, label: moduleLabel(value) })))
const diskSelectOptions = computed(() => (activeDisk.value?.rotation === '1' ? assessmentModules : ssdModules).map(value => ({ value, label: moduleLabel(value) })))
function selectLanguage(value: string) { if (value in strings) lang.value = value as Lang }
function selectScope(value: string) { if (scopeOptions.includes(value as Scope)) assessmentScope.value = value as Scope }
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
async function toggleSerial() {
  if (serialShown.value) { serialShown.value = false; revealedSerial.value = ''; serialCopied.value = false; return }
  const name = selected.value
  if (!name) return
  try {
    const result = await api<{ serial: string }>(`/api/disks/${name}/serial`)
    if (selected.value === name && detailTab.value === 'smart') { revealedSerial.value = result.serial; serialShown.value = true }
  } catch (e) { showMessage(e instanceof Error ? e.message : t('error')) }
}
async function copySerial() {
  if (!serialShown.value || !revealedSerial.value) return
  try {
    if (navigator.clipboard?.writeText) await navigator.clipboard.writeText(revealedSerial.value)
    else {
      const field = document.createElement('textarea')
      field.value = revealedSerial.value
      field.style.cssText = 'position:fixed;left:-10000px;top:0'
      document.body.append(field); field.select()
      const copied = document.execCommand('copy')
      field.remove()
      if (!copied) throw new Error('copy failed')
    }
    showMessage(t('serialCopied'))
    serialCopied.value = true
    if (copyFeedbackTimer) clearTimeout(copyFeedbackTimer)
    copyFeedbackTimer = setTimeout(() => { serialCopied.value = false; copyFeedbackTimer = undefined }, 2200)
  }
  catch { showMessage(t('copyFailed')) }
}
type SmartAttribute = Smart['attributes'][number]
const ataExplanations: Record<number, string> = {
  5: 'smartReallocatedHelp', 9: 'smartPowerHelp', 12: 'smartPowerHelp',
  177: 'smartWearHelp', 187: 'smartErrorsHelp', 188: 'smartErrorsHelp',
  194: 'smartTemperatureHelp', 197: 'smartPendingHelp', 198: 'smartUncorrectableHelp',
  199: 'smartInterfaceHelp', 241: 'smartWrittenHelp', 242: 'smartReadHelp'
}
const nvmeExplanations: Record<string, string> = {
  critical_warning: 'smartWarningHelp', temperature: 'smartTemperatureHelp',
  available_spare: 'smartSpareHelp', available_spare_threshold: 'smartSpareHelp',
  percentage_used: 'smartWearHelp', data_units_read: 'smartReadHelp',
  data_units_written: 'smartWrittenHelp', host_read_commands: 'smartReadHelp',
  host_write_commands: 'smartWrittenHelp', host_reads: 'smartReadHelp',
  host_writes: 'smartWrittenHelp', controller_busy_time: 'smartBusyHelp',
  power_cycles: 'smartPowerHelp', power_on_hours: 'smartPowerHelp',
  unsafe_shutdowns: 'smartShutdownHelp', media_errors: 'smartErrorsHelp',
  num_err_log_entries: 'smartErrorsHelp', warning_temp_time: 'smartTemperatureDurationHelp',
  critical_comp_time: 'smartTemperatureDurationHelp'
}
function smartExplanation(item: SmartAttribute) {
  const key = String(item.key).toLowerCase()
  const topic = item.id != null ? ataExplanations[item.id] : nvmeExplanations[key]
  return t(topic || 'smartGenericHelp')
}
const smartTip = ref<{ text: string; left: number; top: number; above: boolean } | null>(null)
const detailTabTrack = ref<HTMLElement | null>(null)
let tabResizeObserver: ResizeObserver | undefined
function positionDetailTab() {
  const track = detailTabTrack.value
  const selectedTab = track?.querySelector<HTMLElement>('[role="tab"][aria-selected="true"]')
  if (!track || !selectedTab) return
  const trackBounds = track.getBoundingClientRect()
  if (!trackBounds.width) return
  const tabBounds = selectedTab.getBoundingClientRect()
  const layoutScale = parseFloat(getComputedStyle(track).width) / trackBounds.width
  track.style.setProperty('--detail-tab-x', `${(tabBounds.left - trackBounds.left) * layoutScale}px`)
  track.style.setProperty('--detail-tab-width', String(tabBounds.width * layoutScale))
  track.classList.add('is-ready')
}
watch([detailTab, lang, detailTabTrack], async () => {
  tabResizeObserver?.disconnect()
  await nextTick()
  const track = detailTabTrack.value
  if (!track) return
  positionDetailTab()
  tabResizeObserver = new ResizeObserver(positionDetailTab)
  tabResizeObserver.observe(track)
  track.querySelectorAll('[role="tab"]').forEach(tab => tabResizeObserver?.observe(tab))
}, { flush: 'post' })
function showSmartTip(event: Event, item: SmartAttribute) {
  const anchor = event.currentTarget as HTMLElement
  const bounds = anchor.getBoundingClientRect()
  const width = Math.min(320, window.innerWidth - 32)
  const left = Math.max(16, Math.min(bounds.left + bounds.width / 2 - width / 2, window.innerWidth - width - 16))
  const above = bounds.bottom + 100 > window.innerHeight && bounds.top > 110
  smartTip.value = { text: smartExplanation(item), left, top: above ? bounds.top - 10 : bounds.bottom + 10, above }
}
function hideSmartTip() { smartTip.value = null }
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
async function showDisks(event?: MouseEvent) {
  if (currentPage.value !== 'disks') await go('disks', event)
  await nextTick()
  document.getElementById('disk-list')?.scrollIntoView({ behavior: window.matchMedia('(prefers-reduced-motion: reduce)').matches ? 'instant' : 'smooth' })
}
function showAttention(event?: MouseEvent) { void go('attention', event) }
function showTasks(event?: MouseEvent) { void go('tasks', event) }
const themeLabel = (name: string) => t(({ 'slate-blue': 'themeSlateBlue', sage: 'themeSage', teal: 'themeTeal', plum: 'themePlum', ocean: 'themeOcean', olive: 'themeOlive', terracotta: 'themeTerracotta', indigo: 'themeIndigo' }[name] || 'themeSlateBlue') as Key)
const scopeLabel = (name: Scope) => t(({ sata: 'scopeSata', hdd: 'scopeHdd', ssd: 'scopeSsd', nvme: 'scopeNvme', all: 'scopeAll' }[name]))
watch(availableAssessmentModules, values => { if (!values.includes(assessmentModule.value)) assessmentModule.value = 'full' })
watch(diskSelectOptions, values => { if (!values.some(option => option.value === moduleChoice.value)) moduleChoice.value = 'quick' })
const assessmentNote = computed(() => {
  if (assessmentSkipped.value) return `${t('assessmentHddOnly')} ${assessmentSkipped.value}`
  if (assessmentModule.value === 'full' && assessmentDisks.value.some(d => d.rotation !== '1'))
    return t(assessmentDisks.value.every(d => d.rotation !== '1') ? 'assessmentNoteFullSsd' : 'assessmentNoteFullMixed')
  return t(`assessmentNote${assessmentModule.value[0].toUpperCase()}${assessmentModule.value.slice(1)}`)
})
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

async function api<T>(path: string, body?: object, method?: string): Promise<T> {
  const response = await fetch(path, method === 'DELETE' ? { method, headers: { 'X-HDD-CSRF': '1' } } : body ? { method: 'POST', headers: { 'Content-Type': 'application/json', 'X-HDD-CSRF': '1' }, body: JSON.stringify(body) } : undefined)
  if (!response.headers.get('Content-Type')?.toLowerCase().includes('application/json')) throw new Error(t('unexpectedResponse'))
  let data: { error?: string }
  try { data = await response.json() } catch { throw new Error(t('unexpectedResponse')) }
  if (response.status === 401 && !['/api/auth/login', '/api/auth', '/api/auth/security-verify'].includes(path)) auth.value = { authenticated: false, method: null, ipAllowed: auth.value?.ipAllowed || false, canManageAccess: false }
  if (!response.ok) throw new Error(data.error || `HTTP ${response.status}`)
  return data as T
}
async function loadAuth() {
  if (previewMode) { auth.value = { authenticated: true, method: 'local', ipAllowed: false, canManageAccess: true }; preferencesLoaded.value = true; return }
  try { auth.value = await api<Auth>('/api/auth'); if (auth.value.authenticated) { await refresh(); await loadPreferences(true); onPopState() } }
  catch (e) { loginError.value = e instanceof Error ? e.message : t('error') }
  finally { loading.value = false }
}
async function login(ip = false) {
  loginBusy.value = true; loginError.value = ''
  try { auth.value = await api<Auth>(ip ? '/api/auth/ip-login' : '/api/auth/login', ip ? {} : { password: password.value }); password.value = ''; await refresh(); await loadPreferences(true); onPopState() }
  catch (e) { loginError.value = ip ? t('ipLoginUnavailable') : e instanceof Error ? e.message : t('error') }
  finally { loginBusy.value = false }
}
async function logout() {
  try { await api('/api/auth/logout', {}) }
  catch (e) { showMessage(e instanceof Error ? e.message : t('error')); return }
  auth.value = { authenticated: false, method: null, ipAllowed: auth.value?.ipAllowed || false, canManageAccess: false }
  snapshot.value = null; selected.value = null; password.value = ''; preferencesLoaded.value = false
  visitWakeRequested = false; allowedIps.value = []; accessEnabled.value = false
  currentPage.value = 'disks'
  window.history.replaceState({}, '', routeUrl('/disks'))
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
    showMessage(t('save') + ' ✓')
    if (result.wakeSleepingOnVisit && !previous) { visitWakeRequested = true; void requestWakeOnVisit() }
  } catch (e) { preferencesError.value = e instanceof Error ? e.message : t('error') }
  finally { preferencesBusy.value = false }
}
async function loadAccess() {
  if (!auth.value?.canManageAccess || previewMode) return
  try { const result = await api<{ips:string[];enabled:boolean}>('/api/access'); allowedIps.value = result.ips; accessEnabled.value = result.enabled; accessError.value = '' }
  catch (e) { auth.value.canManageAccess = false; allowedIps.value = []; accessEnabled.value = false; accessError.value = e instanceof Error ? e.message : t('error') }
}
async function verifySecurity() {
  securityError.value = ''; securityBusy.value = true
  try {
    await api('/api/auth/security-verify', { password: securityPassword.value })
    securityPassword.value = ''
    if (auth.value) { auth.value.canManageAccess = true; auth.value.method = 'password' }
    await loadAccess()
  } catch (e) { securityError.value = e instanceof Error ? e.message : t('error') }
  finally { securityBusy.value = false }
}
async function saveAccess(ips: string[], enabled = accessEnabled.value) {
  accessError.value = ''
  try { const result = await api<{ips:string[];enabled:boolean}>('/api/access', { ips, enabled }); allowedIps.value = result.ips; accessEnabled.value = result.enabled; newIp.value = ''; showMessage(t('save') + ' ✓') }
  catch (e) { if (e instanceof Error && e.message.includes('Verify the administrator password') && auth.value) { auth.value.canManageAccess = false; allowedIps.value = []; accessEnabled.value = false }; accessError.value = e instanceof Error ? e.message : t('error') }
}
async function changePassword() {
  passwordChangeError.value = ''
  if (newPassword.value !== confirmPassword.value) { passwordChangeError.value = t('passwordMismatch'); return }
  passwordChangeBusy.value = true
  try {
    await api('/api/auth/change-password', { newPassword: newPassword.value, confirmPassword: confirmPassword.value })
    newPassword.value = ''; confirmPassword.value = ''
    auth.value = { authenticated: false, method: null, ipAllowed: auth.value?.ipAllowed || false, canManageAccess: false }
    snapshot.value = null; selected.value = null; currentPage.value = 'disks'
    window.history.replaceState({}, '', '/disks')
    loginError.value = t('passwordChangedLogin')
  } catch (e) { if (e instanceof Error && e.message.includes('Verify the administrator password') && auth.value) auth.value.canManageAccess = false; passwordChangeError.value = e instanceof Error ? e.message : t('error') }
  finally { passwordChangeBusy.value = false }
}
function applyPage(page: Page) {
  detailRequest++; serialShown.value = false; revealedSerial.value = ''; serialCopied.value = false; hideSmartTip()
  if (page !== 'security') { allowedIps.value = []; accessEnabled.value = false; securityPassword.value = '' }
  currentPage.value = page; selected.value = null
  if (page === 'settings') settingsSection.value = (['general', 'appearance', 'power', 'security'].includes(location.hash.slice(10)) ? location.hash.slice(10) : 'general') as typeof settingsSection.value
  if (page === 'security') securitySection.value = (['password', 'ip'].includes(location.hash.slice(10)) ? location.hash.slice(10) : 'password') as typeof securitySection.value
  if (page === 'security') void loadAccess()
}
async function updatePage(page: Page) {
  applyPage(page)
  await nextTick()
  const target = location.hash && ['settings', 'security'].includes(page) ? document.getElementById(location.hash.slice(1)) : null
  if (target) target.scrollIntoView({ behavior: 'instant', block: 'start' })
  else scrollTo({ top: 0, behavior: 'instant' })
  const heading = document.querySelector<HTMLElement>('main h1')
  if (heading) { heading.tabIndex = -1; heading.focus({ preventScroll: true }) }
}
async function go(page: Page, _event?: MouseEvent, _back = false) {
  if (page === currentPage.value && !selected.value) return
  window.history.pushState({}, '', routeUrl(`/${page}`))
  await updatePage(page)
  refreshResizeBaseline()
}
function navLink(event: MouseEvent, page: Page) {
  if (event.button !== 0 || event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return
  event.preventDefault(); void go(page, event)
}
function selectSection(section: 'general' | 'appearance' | 'power' | 'security') {
  settingsSection.value = section
  window.history.replaceState(window.history.state, '', `${location.pathname}${location.search}#settings-${section}`)
  document.getElementById(`settings-${section}`)?.scrollIntoView({ behavior: matchMedia('(prefers-reduced-motion: reduce)').matches ? 'instant' : 'smooth', block: 'start' })
}
function selectSecuritySection(section: 'password' | 'ip') {
  securitySection.value = section
  window.history.replaceState(window.history.state, '', `${location.pathname}${location.search}#security-${section}`)
  document.getElementById(`security-${section}`)?.scrollIntoView({ behavior: matchMedia('(prefers-reduced-motion: reduce)').matches ? 'instant' : 'smooth', block: 'start' })
}
async function closeDisk() {
  if (!selected.value) return
  if (window.history.state?.hddDetailFrom) { window.history.back(); return }
  window.history.pushState({}, '', routeUrl(`/${currentPage.value}`))
  detailRequest++; serialShown.value = false; revealedSerial.value = ''; serialCopied.value = false; hideSmartTip(); selected.value = null; justWokenDisk.value = null
  await nextTick(); scrollTo({ top: 0, behavior: 'instant' })
  refreshResizeBaseline()
}
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
      api<{ samples: SmartSample[] }>('/api/history/samples').then(result => { smartSamples.value = result.samples }),
      api<Schedule>('/api/schedule').then(settings => { if (!editingSchedule.value) schedule.value = settings })
    ])
  } finally { refreshPending = false }
}
async function openDisk(name: string, navigate = true, _event?: MouseEvent) {
  const request = ++detailRequest
  if (navigate) window.history.pushState({ hddDetailFrom: currentPage.value }, '', routeUrl(`/${currentPage.value}/${name}`))
  selected.value = name; serialShown.value = false; revealedSerial.value = ''; serialCopied.value = false; hideSmartTip(); smart.value = null; detailTab.value = 'smart'; smartLoading.value = true; powerTimeExpanded.value = false; moduleChoice.value = 'quick'; justWokenDisk.value = null; expandedModule.value = null
  await nextTick(); scrollTo({ top: 0, behavior: 'instant' })
  refreshResizeBaseline()
  void fetchSmart(name, request)
}
async function fetchSmart(name: string, request: number) {
  const results = await Promise.allSettled([api<Smart>(`/api/disks/${name}/smart`)])
  if (request !== detailRequest || selected.value !== name) return
  if (results[0].status === 'fulfilled') smart.value = results[0].value
  else smart.value = { available: false, error: String(results[0].reason), model: '', serial: '', protocol: '', capacity: null, passed: null, temperature: null, powerOnHours: null, attributes: [] }
  smartLoading.value = false
}
function diskLink(event: MouseEvent, name: string) {
  if (event.button !== 0 || event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return
  event.preventDefault(); void openDisk(name, true, event)
}
async function wakeDisk(name: string) {
  if (wakeDiskBusy.value || previewMode || !activeDisk.value || activeDisk.value.name !== name || activeDisk.value.rotation !== '1') return
  wakeDiskBusy.value = true
  try {
    await api(`/api/disks/${name}/wake`, {})
    await refresh()
    if (selected.value === name) smart.value = await api<Smart>(`/api/disks/${name}/smart`)
    justWokenDisk.value = name
    showMessage(t('wakeDiskDone'))
  } catch (e) { showMessage(e instanceof Error ? e.message : t('error')) }
  finally { wakeDiskBusy.value = false }
}
async function sleepDisk(name: string) {
  if (sleepDiskBusy.value || previewMode || status.value.running) return
  if (!await askConfirmation({ title: t('sleepDisk'), detail: t('sleepDiskConfirm'), targets: [`/dev/${name}`], action: t('sleepDisk') })) return
  sleepDiskBusy.value = true
  try {
    await api(`/api/disks/${name}/sleep`, {})
    justWokenDisk.value = null
    if (smart.value) smart.value = { ...smart.value, passed: null, temperatureState: 'sleeping', temperature: null, powerOnHours: null, attributes: [] }
    showMessage(t('sleepDiskDone'))
  } catch (e) { showMessage(e instanceof Error ? e.message : t('error')) }
  finally { sleepDiskBusy.value = false }
}
async function deleteJob(id: string) {
  if (!await askConfirmation({ title: t('deleteHistory'), detail: t('deleteJobConfirm'), action: t('deleteHistory') })) return
  try { await api(`/api/jobs/history/${id}`, undefined, 'DELETE'); pastJobOpen.value = null; await refresh() }
  catch (e) { showMessage(e instanceof Error ? e.message : t('error')) }
}
async function deleteSample(sample: SmartSample) {
  if (!await askConfirmation({ title: t('deleteHistory'), detail: t('deleteSampleConfirm'), action: t('deleteHistory') })) return
  try { await api(`/api/history/samples/${sample.disk}/${sample.index}`, undefined, 'DELETE'); await refresh() }
  catch (e) { showMessage(e instanceof Error ? e.message : t('error')) }
}
async function launch() {
  if (!activeDisk.value || busy.value) return
  if (moduleChoice.value !== 'quick' && !await askConfirmation({ title: t('confirmStart'), detail: moduleLabel(moduleChoice.value), targets: [`/dev/${activeDisk.value.name}`], action: t('launch') })) return
  busy.value = true; closeMessage()
  try { await api('/api/jobs', { disk: activeDisk.value.name, module: moduleChoice.value }); await refresh() }
  catch (e) { showMessage(e instanceof Error ? e.message : t('error')) }
  finally { busy.value = false }
}
async function assess() {
  if (assessmentBusy.value || status.value.running || !assessmentDisks.value.length || previewMode || !availableAssessmentModules.value.includes(assessmentModule.value)) return
  const names = assessmentEligible.value.map(d => `/dev/${d.name}`)
  if (!names.length) return
  if (!await askConfirmation({ title: t('assessmentConfirm'), detail: `${moduleLabel(assessmentModule.value)} · ${assessmentNote.value}`, targets: names, action: t('assessmentStart') })) return
  assessmentBusy.value = true; closeMessage()
  try { const result = await api<{message:string;disks:string[]}>('/api/jobs/assess', { scope: assessmentScope.value, module: assessmentModule.value }); showMessage(`${t('assessmentStarted')}: ${moduleLabel(assessmentModule.value)} · ${result.disks.length}`); await refresh() }
  catch (e) { showMessage(e instanceof Error ? e.message : t('error')) }
  finally { assessmentBusy.value = false }
}
async function stop() {
  if (!await askConfirmation({ title: t('confirmStop'), action: t('stop') })) return
  busy.value = true
  try { await api('/api/jobs/stop', {}); await refresh() }
  catch (e) { showMessage(e instanceof Error ? e.message : t('error')) }
  finally { busy.value = false }
}
async function saveSchedule() {
  busy.value = true; closeMessage()
  try { schedule.value = await api<Schedule>('/api/schedule', { enabled: schedule.value.enabled, hours: Number(schedule.value.hours) }); editingSchedule.value = false; showMessage(t('save') + ' ✓') }
  catch (e) { showMessage(e instanceof Error ? e.message : t('error')) }
  finally { busy.value = false }
}
let themeTimer: ReturnType<typeof setTimeout> | undefined
function animateThemeChange() {
  document.documentElement.classList.add('theme-changing')
  if (themeTimer) clearTimeout(themeTimer)
  themeTimer = setTimeout(() => document.documentElement.classList.remove('theme-changing'), 400)
}
function setTheme(value: string) { animateThemeChange(); theme.value = value; document.documentElement.dataset.theme = value; try { localStorage.setItem('hdd-theme', value) } catch { /* ignore */ } }
function setAppearanceMode(value: 'light' | 'dark') { animateThemeChange(); appearanceMode.value = value; document.documentElement.classList.toggle('dark', value === 'dark'); try { localStorage.setItem('hdd-mode', value) } catch { /* ignore */ } }
watch(lang, value => { document.documentElement.lang = value; document.documentElement.dir = value === 'ar' ? 'rtl' : 'ltr'; try { localStorage.setItem('hdd-lang', value) } catch { /* ignore */ } }, { immediate: true })
let timer: ReturnType<typeof setInterval> | undefined
let refreshPending = false
let removeResizeMotion: (() => void) | undefined
onMounted(() => { loadAuth(); removeResizeMotion = installResizeMotion(); timer = setInterval(() => { if (auth.value?.authenticated) { void refresh(); if (currentPage.value === 'security' && !previewMode) void api<Auth>('/api/auth').then(state => { if (auth.value && !state.canManageAccess) { auth.value.canManageAccess = false; allowedIps.value = []; accessEnabled.value = false } }).catch(() => {}) } }, 15000); window.addEventListener('popstate', onPopState) })
async function onPopState(event?: PopStateEvent) {
  const page = pageFromPath()
  if (event && page !== 'changelog' && !previewMode) {
    try { const state = await api<Auth>('/api/auth'); auth.value = state; if (!state.authenticated) throw new Error('expired') }
    catch { auth.value = { authenticated: false, method: null, ipAllowed: false, canManageAccess: false }; applyPage('disks'); window.history.replaceState({}, '', routeUrl('/disks')); return }
  }
  const diskMatch = window.location.pathname.match(/^\/(?:disks|attention)\/([A-Za-z0-9_-]+)$/)
  if (diskMatch && snapshot.value?.disks.some(d => d.name === diskMatch[1])) {
    if (page !== currentPage.value) applyPage(page)
    await openDisk(diskMatch[1], false)
    return
  }
  if (diskMatch && snapshot.value && !snapshot.value.disks.some(d => d.name === diskMatch[1]))
    window.history.replaceState(window.history.state, '', routeUrl(`/${page}`))
  await updatePage(page)
  refreshResizeBaseline()
}
onUnmounted(() => { if (timer) clearInterval(timer); if (themeTimer) clearTimeout(themeTimer); if (copyFeedbackTimer) clearTimeout(copyFeedbackTimer); if (messageTimer) clearTimeout(messageTimer); tabResizeObserver?.disconnect(); window.removeEventListener('popstate', onPopState); removeResizeMotion?.(); confirmResolve?.(false) })
</script>

<template>
  <div class="app-shell">
    <header class="topbar site-header" :class="{ 'app-login-header': auth && !auth.authenticated && currentPage!=='changelog' }">
      <div class="brand-group">
        <a class="brand" :class="{ 'app-login-brand': auth && !auth.authenticated }" href="/disks" @click="navLink($event, 'disks')"><span class="brand-icon" :class="{ 'app-login-brand-logo': auth && !auth.authenticated }"><HardDrive :size="22" /></span><span><strong>HDD Health</strong><small>{{ t('localMonitor') }}</small></span></a>
        <a v-if="auth?.authenticated || (auth && currentPage==='changelog')" class="version brand-version" href="/changelog" @click="navLink($event, 'changelog')">{{ buildVersion }}</a>
      </div>
      <nav v-if="auth?.authenticated" class="main-nav header-nav" :aria-label="t('navigation')">
        <a href="/disks" :class="{active:currentPage==='disks'}" :aria-current="currentPage==='disks' ? 'page' : undefined" @click="navLink($event, 'disks')">{{ t('home') }}</a>
        <a href="/changelog" :class="{active:currentPage==='changelog'}" :aria-current="currentPage==='changelog' ? 'page' : undefined" @click="navLink($event, 'changelog')">{{ t('changelog') }}</a>
        <a href="/settings" :class="{active:['settings','security'].includes(currentPage)}" :aria-current="['settings','security'].includes(currentPage) ? 'page' : undefined" @click="navLink($event, 'settings')">{{ t('settingsPage') }}</a>
        <button v-if="!previewMode" type="button" @click="logout"><LogOut :size="16" aria-hidden="true" />{{ t('logout') }}</button>
      </nav>
      <nav v-else-if="auth && currentPage==='changelog'" class="main-nav header-nav" :aria-label="t('navigation')"><a href="/changelog" class="active" aria-current="page">{{ t('changelog') }}</a><a href="/disks" @click="navLink($event, 'disks')">{{ t('login') }}</a></nav>
    </header>
    <main v-if="!auth" class="container"><div class="empty">{{ t('refresh') }}…</div></main>
    <main v-else-if="!auth.authenticated && currentPage==='changelog'" class="container content-main"><div class="breadcrumbs"><a href="/disks" @click="navLink($event, 'disks')">{{ t('home') }}</a><span>/</span><span>{{ t('changelog') }}</span></div><div class="page-actions"><a class="button back-button" href="/disks" @click="navLink($event, 'disks')"><ArrowLeft :size="16" aria-hidden="true" />{{ t('login') }}</a></div><div class="page-heading"><div><div class="eyebrow">{{ t('releaseNotes') }}</div><h1>{{ t('changelog') }}</h1><p>{{ t('changelogDescription') }}</p></div></div><div class="changelog-list"><article v-for="(entry, index) in changelogCards" :key="index" class="settings-card changelog-card"><span class="status-pill">{{ t(entry.candidate ? 'testBuild' : 'formalVersion') }}</span><div class="markdown-body" v-html="entry.html"></div></article></div></main>
    <main v-else-if="!auth.authenticated" class="app-login-main"><form class="panel login-card app-login-card" @submit.prevent="login()"><div class="login-symbol"><LockKeyhole :size="25" /></div><div class="eyebrow">HDD HEALTH</div><h1>{{ t('loginTitle') }}</h1><p class="lead">{{ t('loginDescription') }}</p><label for="login-password">{{ t('password') }}</label><PasswordField id="login-password" v-model="password" autocomplete="current-password" :show-label="t('showPassword')" :hide-label="t('hidePassword')" :show-text="t('show')" :hide-text="t('hide')" required /><p v-if="loginError" class="login-error" role="alert">{{ loginError }}</p><button class="button primary app-login-action" :disabled="loginBusy" type="submit">{{ t('login') }}</button><button class="button app-login-action" type="button" :disabled="loginBusy" @click="login(true)">{{ t('ipLogin') }}</button><div class="app-login-footer login-footer"><a class="app-login-version" href="/changelog" @click="navLink($event, 'changelog')">{{ buildVersion }}</a><div class="app-login-language"><label for="login-language">{{ t('language') }}</label><UiSelect id="login-language" :model-value="lang" :options="languageOptions" :aria-label="t('language')" @update:model-value="selectLanguage" /></div></div></form></main>
    <main v-else class="container content-main">
    <div v-if="activeDisk" class="disk-detail-page"><div class="breadcrumbs"><a href="/disks" @click="navLink($event, 'disks')">{{ t('home') }}</a><span>/</span><span>{{ t('driveDetail') }}</span></div><div class="page-actions"><button class="button back-button" type="button" @click="closeDisk"><ArrowLeft :size="16" aria-hidden="true" />{{ t('backToList') }}</button></div><section class="disk-detail-content panel"><div class="disk-page-header"><div><div class="eyebrow">{{ t('driveDetail') }}</div><h1>{{ activeDisk.model || `/dev/${activeDisk.name}` }}</h1><p>/dev/{{ activeDisk.name }} · <button class="capacity-toggle" type="button" :title="t('toggleCapacity')" :aria-label="t('toggleCapacity')" @click="toggleCapacity">{{ capacityText(activeDisk.bytes, activeDisk.size) }}</button> · {{ activeDisk.transport }}</p></div></div><div class="detail-tabs" role="tablist"><div ref="detailTabTrack" class="detail-tab-track"><button role="tab" :aria-selected="detailTab==='smart'" :class="{active:detailTab==='smart'}" @click="detailTab='smart'">{{ t('smartInfo') }}</button><button role="tab" :aria-selected="detailTab==='checks'" :class="{active:detailTab==='checks'}" @click="serialShown=false; revealedSerial=''; serialCopied=false; hideSmartTip(); detailTab='checks'">{{ t('checks') }}</button></div></div><div v-if="detailTab==='smart'" class="drawer-body"><div v-if="smartLoading" class="empty">{{ t('refresh') }}…</div><template v-else-if="smart"><div class="smart-status"><span>{{ t('healthStatus') }}</span><strong :class="smart.passed===true?'good':smart.passed===false?'bad':'na'">{{ smart.passed===true ? t('smartPassed') : smart.passed===false ? t('smartFailed') : smart.temperatureState==='sleeping' ? t('sleeping') : t('smartUnknown') }}</strong><div v-if="activeDisk.rotation==='1' && activeDisk.transport?.toLowerCase()==='sata'" class="power-actions"><button v-if="smart.temperatureState==='sleeping' || activeDisk.temperatureState==='sleeping' || justWokenDisk===activeDisk.name" class="disk-wake-button" type="button" :disabled="wakeDiskBusy || justWokenDisk===activeDisk.name || previewMode" @click="wakeDisk(activeDisk.name)">{{ justWokenDisk===activeDisk.name ? t('wakeDiskDone') : wakeDiskBusy ? t('wakingDisk') : t('wakeDisk') }}</button><button v-else class="disk-wake-button" type="button" :disabled="sleepDiskBusy || status.running || previewMode" @click="sleepDisk(activeDisk.name)">{{ sleepDiskBusy ? t('sleepingDisk') : t('sleepDisk') }}</button></div></div><p v-if="smart.temperatureState==='sleeping'" class="subtle-note">{{ t('sleepingSmartNote') }}</p><p v-else-if="smart.error && !smart.available" class="subtle-note">{{ smart.error }}</p><div class="smart-facts"><div><small>{{ t('model') }}</small><strong>{{ smart.model || activeDisk.model || '—' }}</strong></div><div><small>{{ t('serial') }}</small><template v-if="smart.serial || activeDisk.serial"><button class="sensitive-value" type="button" :aria-label="t(serialShown ? 'hideSerial' : 'showSerial')" :aria-pressed="serialShown" @click="toggleSerial">{{ serialShown ? revealedSerial : (smart.serial || activeDisk.serial) }}</button><button v-if="serialShown && revealedSerial" class="serial-copy-button" :class="{copied:serialCopied}" type="button" :aria-label="t(serialCopied ? 'serialCopied' : 'copySerial')" :title="t(serialCopied ? 'serialCopied' : 'copySerial')" @click="copySerial"><Check v-if="serialCopied" :size="18" :stroke-width="3" aria-hidden="true" /><Copy v-else :size="17" aria-hidden="true" /></button></template><strong v-else>—</strong></div><div><small>{{ t('diskType') }}</small><strong>{{ diskTypeText(activeDisk) }}</strong></div><div v-if="smart.formFactor"><small>{{ t('formFactor') }}</small><strong>{{ smart.formFactor }}</strong></div><div><small>{{ t('currentLink') }}</small><strong>{{ linkText(smart.link || activeDisk.link, smart.protocol || activeDisk.transport) }}</strong></div><div v-if="maxLinkText(smart.link || activeDisk.link)"><small>{{ t('maxLink') }}</small><strong>{{ maxLinkText(smart.link || activeDisk.link) }}</strong></div><div><small>{{ t('temp') }}</small><strong :class="temperatureClass(activeDisk, smart.temperature)">{{ temperatureText(smart.temperature, smart.temperatureState) }}</strong></div><div v-if="activeDisk.rotation==='0'"><small>{{ t('hostReads') }}</small><button v-if="smart.readBytes!=null" class="capacity-toggle" type="button" :title="t('toggleCapacity')" :aria-label="t('toggleCapacity')" @click="toggleCapacity">{{ capacityText(smart.readBytes) }}</button><strong v-else>—</strong><small v-if="smart.readBytes==null">{{ t('readsUnavailable') }}</small></div><div v-if="activeDisk.rotation==='0'"><small>{{ t('hostWrites') }}</small><button v-if="smart.writtenBytes!=null" class="capacity-toggle" type="button" :title="t('toggleCapacity')" :aria-label="t('toggleCapacity')" @click="toggleCapacity">{{ capacityText(smart.writtenBytes) }}</button><strong v-else>—</strong><small v-if="smart.writtenBytes==null">{{ t('writesUnavailable') }}</small></div><div><small>{{ t('powerOnHours') }}</small><button v-if="smart.powerOnHours!=null" class="time-toggle" type="button" :title="t('togglePowerTime')" :aria-label="t('togglePowerTime')" :aria-pressed="powerTimeExpanded" @click="powerTimeExpanded=!powerTimeExpanded">{{ powerTime(smart.powerOnHours) }}</button><strong v-else>{{ smart.temperatureState==='sleeping' ? t('sleeping') : '—' }}</strong></div></div><div class="section-head"><h3>{{ t('smartAttributes') }}</h3></div><p class="smart-legend">{{ t('smartTableHelp') }}</p><div v-if="!smart.attributes.length" class="empty compact">{{ smart.temperatureState==='sleeping' ? t('sleepingSmartNote') : t('smartUnavailable') }}</div><div v-else class="table-scroll"><table><thead><tr><th>{{ t('attribute') }}</th><th>{{ t('value') }}</th><th>{{ t('normalized') }}</th><th>{{ t('threshold') }}</th></tr></thead><tbody><tr v-for="(item,index) in smart.attributes" :key="item.key+index"><td class="attr-name"><span class="smart-attribute-name">{{ item.key }}</span><button type="button" class="smart-attribute-help" :aria-label="`${item.key}: ${smartExplanation(item)}`" @pointerenter="showSmartTip($event,item)" @pointerleave="hideSmartTip" @focus="showSmartTip($event,item)" @blur="hideSmartTip" @click="showSmartTip($event,item)" @keydown.esc="hideSmartTip"><CircleHelp :size="17" aria-hidden="true" /></button></td><td class="smart-raw-value">{{ item.value }}</td><td>{{ item.normalized ?? '—' }}</td><td>{{ item.threshold ?? '—' }}</td></tr></tbody></table></div></template></div><div v-else class="drawer-body"><div class="score-panel"><div><small>{{ t('current') }}</small><strong>{{ activeDisk.score === null ? '—' : activeDisk.score }}</strong><span>{{ gradeText(activeDisk) }}</span></div><div><small>{{ t('status') }}</small><span class="badge large" :class="condition(activeDisk)">{{ conditionLabel(activeDisk) }}</span><span>{{ coverageText(activeDisk.coverage) }}</span></div></div><p class="subtle-note">{{ t('scoreNote') }}</p><div v-if="attentionModules(activeDisk).length > 0" class="attention-detail"><strong>{{ t('attentionReasons') }}</strong><ul><li v-for="item in attentionModules(activeDisk)" :key="item.name">{{ moduleLabel(item.name) }}: {{ moduleSummary(item) }} <small>({{ item.current ? t('fresh') : t('stale') }})</small></li></ul></div><div class="section-head"><h3>{{ t('checks') }}</h3><History :size="17" /></div><div v-if="!activeDisk.modules.length" class="empty compact">{{ t('noCheck') }}</div><div v-for="item in activeDisk.modules" :key="item.name" class="module-row module-detail"><button type="button" class="module-expand" :aria-expanded="expandedModule===item.name" @click="expandedModule=expandedModule===item.name ? null : item.name"><strong>{{ moduleLabel(item.name) }}</strong><small>{{ date(item.timestamp) }} · {{ item.current ? t('fresh') : t('stale') }}</small><p>{{ moduleSummary(item) }}</p><small>{{ t('viewDetails') }} {{ expandedModule===item.name ? '⌃' : '⌄' }}</small></button><span class="badge" :class="item.status">{{ label(item.status) }}</span><div v-if="expandedModule===item.name" class="module-expanded"><p><strong>{{ t('status') }}:</strong> {{ label(item.status) }}</p><p><strong>{{ t('date') }}:</strong> {{ date(item.timestamp) }}</p><p><strong>{{ t('deduction') }}:</strong> {{ item.deduction }}</p><p><strong>{{ t('summary') }}:</strong> {{ item.summary || t('noDetail') }}</p><p><strong>{{ t('attentionReasons') }}:</strong> {{ item.issues || t('noDetail') }}</p></div></div><div class="section-head"><h3>{{ t('launch') }}</h3><Play :size="17" /></div><p class="subtle-note">{{ t('scanNote') }}</p><div class="launch-row"><UiSelect v-model="moduleChoice" :options="diskSelectOptions" :aria-label="t('checkType')" :disabled="busy || status.running" /><button class="button primary" :disabled="busy || status.running" @click="launch"><Play :size="15" />{{ t('launch') }}</button></div><div class="section-head"><h3>{{ t('history') }}</h3><History :size="17" /></div><div v-if="!diskHistory.length" class="empty compact">{{ t('noHistory') }}</div><div v-else class="table-scroll"><table><thead><tr><th>{{ t('date') }}</th><th>{{ t('realloc') }}</th><th>{{ t('pending') }}</th><th>{{ t('uncorrect') }}</th><th>{{ t('crc') }}</th><th>{{ t('temp') }}</th><th></th></tr></thead><tbody><tr v-for="row in diskHistory" :key="row.index"><td>{{ date(row.values[0]) }}</td><td>{{ row.values[2] }}</td><td>{{ row.values[3] }}</td><td>{{ row.values[4] }}</td><td>{{ row.values[6] }}</td><td>{{ row.values[7] }}°</td><td><button class="history-delete" type="button" @click="deleteSample(row)">{{ t('deleteHistory') }}</button></td></tr></tbody></table></div></div></section></div>
      <template v-else>
      <div v-if="previewMode" class="preview-note" role="status"><ShieldAlert :size="18" /><span>{{ t('previewOnly') }}</span></div>
      <div v-if="error" class="alert"><ShieldAlert :size="18" /><span>{{ error }}</span><button class="text-button" @click="refresh">{{ t('retry') }}</button></div>
      <div v-if="currentPage!=='disks'" class="breadcrumbs"><a href="/disks" @click="navLink($event, 'disks')">{{ t('home') }}</a><span>/</span><span>{{ currentPage==='security' ? t('securitySettings') : currentPage==='attention' ? t('attention') : currentPage==='tasks' ? t('running') : currentPage==='schedule' ? t('schedule') : currentPage==='changelog' ? t('changelog') : t('settingsPage') }}</span></div>
      <div v-if="currentPage!=='disks'" class="page-actions">
        <button class="button back-button" type="button" @click="go(currentPage==='security' ? 'settings' : 'disks', $event, true)"><ArrowLeft :size="16" aria-hidden="true" />{{ t(currentPage==='security' ? 'backSettings' : 'backDashboard') }}</button>
        <button v-if="currentPage==='attention' || currentPage==='tasks' || currentPage==='schedule'" class="button page-refresh" type="button" :disabled="previewMode" @click="refresh"><RefreshCw :size="16" aria-hidden="true" />{{ t('refresh') }}</button>
      </div>
      <template v-if="currentPage!=='settings' && currentPage!=='security' && currentPage!=='changelog'">
        <div class="page-heading"><div><div class="eyebrow"><Activity :size="14" /> {{ currentPage==='disks' ? t('systemOverview') : t('operations') }}</div><h1>{{ currentPage==='disks' ? t('overview') : currentPage==='attention' ? t('attention') : currentPage==='tasks' ? t('running') : t('schedule') }}</h1><p>{{ currentPage==='disks' ? t('subtitle') : currentPage==='attention' ? t('viewAttention') : currentPage==='tasks' ? t('task') : t('automation') }}</p></div><div class="heading-actions"><span v-if="!previewMode" class="live-pill"><span class="live-dot"></span>{{ t('local') }}</span><button v-if="currentPage==='disks'" class="button page-refresh" type="button" :disabled="previewMode" @click="refresh"><RefreshCw :size="16" aria-hidden="true" />{{ t('refresh') }}</button></div></div>
        <div v-if="currentPage==='disks'" class="stats-grid dashboard-grid"><button class="stat-card stat-action dashboard-card" type="button" @click="showDisks"><div class="stat-label dashboard-card-copy"><HardDrive :size="18" />{{ t('disks') }}</div><strong>{{ snapshot?.disks.length ?? '—' }}</strong><span>{{ t('all') }}</span></button><button class="stat-card stat-action dashboard-card" type="button" @click="showAttention"><div class="stat-label dashboard-card-copy"><ShieldAlert :size="18" />{{ t('attention') }}</div><strong>{{ attentionCount }}</strong><span>{{ t('viewAttention') }}</span></button><button class="stat-card stat-action dashboard-card" type="button" @click="showTasks"><div class="stat-label dashboard-card-copy"><Activity :size="18" />{{ t('running') }}</div><strong class="stat-word">{{ status.running ? t('runningState') : status.job ? jobStateText(status.job) : '—' }}</strong><span>{{ status.job ? `${status.job.targets.split(' ').filter(Boolean).length} ${t('disks')}` : t('noRunning') }}</span></button><button class="stat-card stat-action dashboard-card" type="button" @click="go('schedule', $event)"><div class="stat-label dashboard-card-copy"><Clock3 :size="18" />{{ t('schedule') }}</div><strong class="stat-word">{{ schedule.enabled ? `${schedule.hours}h` : '—' }}</strong><span>{{ schedule.enabled ? t('enabled') : t('noCheck') }}</span></button></div>
        <section v-if="currentPage==='disks'" class="panel storage-summary"><div><small>{{ t('physicalCapacity') }}</small><button class="capacity-toggle" type="button" :title="t('toggleCapacity')" :aria-label="t('toggleCapacity')" @click="toggleCapacity">{{ capacityText(snapshot?.storage?.totalBytes) }}</button></div><div><small>{{ t('mountedUsed') }}</small><button class="capacity-toggle" type="button" :title="t('toggleCapacity')" :aria-label="t('toggleCapacity')" @click="toggleCapacity">{{ capacityText(snapshot?.storage?.usedBytes) }}</button></div><p>{{ t('storageNote') }}</p></section>
        <section v-if="currentPage==='disks'" class="panel assessment-panel"><div><div class="eyebrow">{{ t('assessmentEyebrow') }}</div><h2>{{ t('assessmentTitle') }}</h2><p class="muted">{{ t('assessmentDescription') }}</p></div><div class="assessment-controls"><div class="assessment-field"><label for="assessment-scope">{{ t('assessmentScope') }}</label><UiSelect id="assessment-scope" :model-value="assessmentScope" :options="scopeSelectOptions" :aria-label="t('assessmentScope')" :disabled="assessmentBusy || status.running || previewMode" @update:model-value="selectScope" /></div><div class="assessment-field"><label for="assessment-module">{{ t('assessmentModule') }}</label><UiSelect id="assessment-module" v-model="assessmentModule" :options="assessmentSelectOptions" :aria-label="t('assessmentModule')" :disabled="assessmentBusy || status.running || previewMode" /></div><span class="assessment-count">{{ t('assessmentCount') }}: {{ assessmentDisks.length }}</span><button class="button primary" :disabled="assessmentBusy || status.running || !assessmentEligible.length || previewMode" @click="assess"><Play :size="15" />{{ assessmentBusy ? t('assessmentStarting') : t('assessmentStart') }}</button></div><p class="assessment-note">{{ assessmentNote }}</p></section>
        <section v-if="currentPage==='disks' || currentPage==='attention'" id="disk-list" class="panel disk-list"><div class="panel-heading"><div><div class="eyebrow">{{ t('drives') }}</div><h2>{{ currentPage==='attention' ? t('attention') : t('all') }}</h2></div><div class="list-actions"><button v-if="currentPage==='attention'" class="text-button" type="button" @click="go('disks')">{{ t('showAllDisks') }}</button><span class="count">{{ visibleDisks.length }}</span></div></div><div v-if="loading" class="empty">{{ t('refresh') }}…</div><div v-else-if="!visibleDisks.length" class="empty">{{ currentPage==='attention' ? t('noAttention') : previewMode ? t('previewOnly') : t('empty') }}</div><div class="disk-cards"><div v-for="disk in visibleDisks" :key="disk.name" class="disk-card"><div class="disk-icon"><HardDrive :size="24" /></div><div class="disk-card-main"><div class="disk-card-title"><strong>{{ disk.model || `/dev/${disk.name}` }}</strong><span class="badge" :class="condition(disk)">{{ conditionLabel(disk) }}</span></div><div class="disk-card-fields"><span><small>{{ t('capacity') }}</small><button class="capacity-toggle" type="button" :title="t('toggleCapacity')" :aria-label="t('toggleCapacity')" @click="toggleCapacity">{{ capacityText(disk.bytes, disk.size) }}</button></span><span><small>{{ t('diskType') }}</small>{{ diskTypeText(disk) }}</span><span><small>{{ t('devicePath') }}</small>/dev/{{ disk.name }}</span><span><small>{{ t('temp') }}</small><strong :class="temperatureClass(disk, disk.temperature)">{{ temperatureText(disk.temperature, disk.temperatureState) }}</strong></span><span><small>{{ t('interface') }}</small>{{ linkText(disk.link, disk.transport) }}</span><span><small>{{ t('serial') }}</small>{{ disk.serial || '—' }}</span><span><small>{{ t('last') }}</small>{{ date(latest(disk)) }}</span></div><div v-if="currentPage==='attention' && attentionModules(disk).length" class="disk-card-reasons"><strong>{{ t('attentionReasons') }}</strong><ul><li v-for="item in attentionModules(disk)" :key="item.name">{{ moduleLabel(item.name) }}: {{ moduleSummary(item) }} <small>({{ item.current ? t('fresh') : t('stale') }})</small></li></ul></div></div><div class="disk-card-end"><span>{{ t('healthStatus') }}</span><strong :class="condition(disk)">{{ disk.score===null ? `${coverageText(disk.coverage)} / ${t('unknownScore')}` : gradeText(disk) }}</strong><a class="disk-detail-button" :href="routeUrl(`/${currentPage}/${disk.name}`)" @click="diskLink($event, disk.name)">{{ t('details') }} →</a></div></div></div></section>
        <section v-if="currentPage==='tasks'" id="task-panel" class="panel task-panel task-overview"><div class="panel-heading"><div><div class="eyebrow">{{ t('operations') }}</div><h2>{{ t('task') }}</h2></div><Activity :size="19" /></div><div v-if="status.job" class="job-summary"><span class="badge" :class="status.job.state === 'failed' || status.job.state === 'unconfirmed' ? 'bad' : status.job.exitCode > 0 ? 'warn' : 'good'">{{ status.running ? t('runningState') : jobStateText(status.job) }}</span><strong>{{ moduleLabel(status.job.module) }} · {{ status.job.targets.split(' ').filter(Boolean).map(name => `/dev/${name}`).join(', ') }}</strong><small>{{ date(status.job.finished || status.job.started) }}</small></div><p class="task-natural" role="status">{{ taskSummary }}</p><div v-if="taskRawLog" class="task-log-controls"><button class="button" type="button" :aria-expanded="taskDetailsOpen" @click="taskDetailsOpen=!taskDetailsOpen">{{ taskDetailsOpen ? t('hideDetailedLog') : t('showDetailedLog') }}</button></div><pre v-if="taskDetailsOpen && taskRawLog" class="task-output">{{ taskRawLog }}</pre><button v-if="status.running" class="button danger" :disabled="busy" @click="stop"><Square :size="15" />{{ t('stop') }}</button></section>
        <section v-if="currentPage==='tasks'" class="panel task-history"><div class="panel-heading"><div><div class="eyebrow">{{ t('operations') }}</div><h2>{{ t('taskHistory') }}</h2></div><History :size="19" /></div><div v-if="!allHistory.length" class="empty">{{ t('noTaskHistory') }}</div><div v-for="event in allHistory" :key="event.type==='job' ? event.job.id : `${event.sample.disk}-${event.sample.index}`" class="past-job"><template v-if="event.type==='job'"><div class="past-job-head"><span class="badge" :class="event.job.state==='failed' ? 'bad' : event.job.state==='stopped' || event.job.exitCode > 0 ? 'warn' : 'good'">{{ jobStateText({ ...event.job, output: '' }) }}</span><strong>{{ moduleLabel(event.job.module) }} · {{ event.job.targets.split(' ').filter(Boolean).length }} {{ t('disks') }}</strong><small>{{ date(event.job.finished) }}</small></div><p>{{ event.job.targets.split(' ').filter(Boolean).map(name => `/dev/${name}`).join(', ') }}</p><button class="button" type="button" :aria-expanded="pastJobOpen===event.job.id" @click="togglePastJob(event.job.id)">{{ pastJobOpen===event.job.id ? t('hideDetailedLog') : t('showDetailedLog') }}</button><pre v-if="pastJobOpen===event.job.id" class="task-output">{{ pastJobLog || t('refresh') + '…' }}</pre><button class="button history-delete" type="button" @click="deleteJob(event.job.id)">{{ t('deleteHistory') }}</button></template><template v-else><div class="past-job-head"><span class="badge good">SMART</span><strong>/dev/{{ event.sample.disk }} · {{ t('smartSample') }}</strong><small>{{ date(event.sample.values[0]) }}</small></div><p>{{ t('realloc') }}: {{ event.sample.values[2] }} · {{ t('pending') }}: {{ event.sample.values[3] }} · {{ t('uncorrect') }}: {{ event.sample.values[4] }} · {{ t('crc') }}: {{ event.sample.values[6] }} · {{ t('temp') }}: {{ event.sample.values[7] }}°</p><button class="button history-delete" type="button" @click="deleteSample(event.sample)">{{ t('deleteHistory') }}</button></template></div></section>
        <section v-if="currentPage==='schedule'" class="panel schedule-panel"><div class="panel-heading"><div><div class="eyebrow">{{ t('automation') }}</div><h2>{{ t('schedule') }}</h2></div><Settings2 :size="19" /></div><label class="switch-line"><input v-model="schedule.enabled" type="checkbox" :disabled="previewMode" @change="editingSchedule = true" /><span>{{ t('enabled') }}</span></label><label class="field-label" for="hours">{{ t('interval') }}</label><div class="input-wrap"><input id="hours" v-model.number="schedule.hours" type="number" min="6" max="168" :disabled="previewMode" @input="editingSchedule = true" /><span>{{ t('hours') }}</span></div><p v-if="schedule.error" class="schedule-error" role="alert">{{ schedule.error }}</p><button class="button primary" :disabled="busy || previewMode" @click="saveSchedule">{{ t('save') }}</button></section>
        <p v-if="currentPage==='disks' || currentPage==='attention'" class="footnote">{{ t('scoreNote') }}</p>
      </template>
      <template v-else-if="currentPage==='changelog'"><div class="page-heading"><div><div class="eyebrow">{{ t('releaseNotes') }}</div><h1>{{ t('changelog') }}</h1><p>{{ t('changelogDescription') }}</p></div></div><div class="changelog-list"><article v-for="(entry, index) in changelogCards" :key="index" class="settings-card changelog-card"><span class="status-pill">{{ t(entry.candidate ? 'testBuild' : 'formalVersion') }}</span><div class="markdown-body" v-html="entry.html"></div></article></div></template>
      <template v-else-if="currentPage==='security'">
        <div class="page-heading"><div><div class="eyebrow"><LockKeyhole :size="14" /> {{ t('security') }}</div><h1>{{ t('securitySettings') }}</h1><p>{{ t('securitySettingsDescription') }}</p></div></div>
        <form v-if="!auth.canManageAccess" class="panel settings-card security-challenge" @submit.prevent="verifySecurity">
          <div class="settings-body"><label for="security-password">{{ t('verifyAdminPassword') }}</label><PasswordField id="security-password" v-model="securityPassword" autocomplete="current-password" :show-label="t('showPassword')" :hide-label="t('hidePassword')" :show-text="t('show')" :hide-text="t('hide')" required /><p v-if="securityError" class="login-error" role="alert">{{ securityError }}</p><button class="button primary" type="submit" :disabled="securityBusy || previewMode">{{ t('verifyAndOpen') }}</button></div>
        </form>
        <div v-else class="settings-layout">
          <nav class="section-nav" :aria-label="t('securitySettings')"><button type="button" :class="{active:securitySection==='password'}" :aria-current="securitySection==='password' ? 'location' : undefined" @click="selectSecuritySection('password')">{{ t('passwordGroup') }}</button><button type="button" :class="{active:securitySection==='ip'}" :aria-current="securitySection==='ip' ? 'location' : undefined" @click="selectSecuritySection('ip')">{{ t('ipGroup') }}</button></nav>
          <div class="settings-content">
            <section id="security-password" class="panel settings-card password-card"><div class="panel-heading"><div><div class="eyebrow">{{ t('security') }}</div><h2>{{ t('changePassword') }}</h2></div><LockKeyhole :size="19" /></div><form class="settings-body" @submit.prevent="changePassword"><p class="muted">{{ t('changePasswordDescription') }}</p><label for="new-password">{{ t('newPassword') }}</label><PasswordField id="new-password" v-model="newPassword" autocomplete="new-password" :show-label="t('showPassword')" :hide-label="t('hidePassword')" :show-text="t('show')" :hide-text="t('hide')" :minlength="12" :maxlength="128" required /><label for="confirm-password">{{ t('confirmPassword') }}</label><PasswordField id="confirm-password" v-model="confirmPassword" autocomplete="new-password" :show-label="t('showPassword')" :hide-label="t('hidePassword')" :show-text="t('show')" :hide-text="t('hide')" :minlength="12" :maxlength="128" required /><p v-if="passwordChangeError" class="login-error" role="alert">{{ passwordChangeError }}</p><button class="button primary" type="submit" :disabled="passwordChangeBusy || previewMode">{{ t('savePassword') }}</button></form></section>
            <section id="security-ip" class="panel settings-card access-card"><div class="panel-heading"><div><div class="eyebrow">{{ t('security') }}</div><h2>{{ t('ipAccess') }}</h2></div><LockKeyhole :size="19" /></div><div class="settings-body"><p class="muted">{{ t('ipAccessDescription') }}</p><p class="subtle-note">{{ t('ipAccessWarning') }}</p><label class="switch-line"><input type="checkbox" :checked="accessEnabled" @change="saveAccess(allowedIps, !accessEnabled)" /><span>{{ t('enableIpAccess') }}</span></label><div v-for="ip in allowedIps" :key="ip" class="ip-row"><code>{{ ip }}</code><button class="text-button" :aria-label="t('remove')+' '+ip" @click="saveAccess(allowedIps.filter(x=>x!==ip))">{{ t('remove') }}</button></div><div class="ip-add"><input v-model.trim="newIp" :placeholder="t('ipPlaceholder')" inputmode="decimal" :aria-label="t('ipAccess')" /><button class="button primary" :disabled="!newIp || previewMode" @click="saveAccess([...allowedIps,newIp])">{{ t('addIp') }}</button></div><p v-if="accessError" class="login-error" role="alert">{{ accessError }}</p></div></section>
          </div>
        </div>
      </template>
      <template v-else>
        <div class="page-heading"><div><div class="eyebrow"><Settings2 :size="14" /> {{ t('preferences') }}</div><h1>{{ t('settingsPage') }}</h1><p>{{ t('settingsDescription') }}</p></div></div>
        <div class="settings-layout">
          <nav class="section-nav" :aria-label="t('settingsPage')"><button type="button" :class="{active:settingsSection==='general'}" :aria-current="settingsSection==='general' ? 'location' : undefined" @click="selectSection('general')">{{ t('general') }}</button><button type="button" :class="{active:settingsSection==='appearance'}" :aria-current="settingsSection==='appearance' ? 'location' : undefined" @click="selectSection('appearance')">{{ t('appearance') }}</button><button type="button" :class="{active:settingsSection==='power'}" :aria-current="settingsSection==='power' ? 'location' : undefined" @click="selectSection('power')">{{ t('diskPolicy') }}</button><button type="button" :class="{active:settingsSection==='security'}" :aria-current="settingsSection==='security' ? 'location' : undefined" @click="selectSection('security')">{{ t('security') }}</button></nav>
          <div class="settings-content">
            <section id="settings-general" class="panel settings-card"><div class="panel-heading"><div><div class="eyebrow">{{ t('general') }}</div><h2>{{ t('language') }}</h2><p>{{ t('languageDescription') }}</p></div></div><div class="settings-body"><label for="lang">{{ t('language') }}</label><UiSelect id="lang" :model-value="lang" :options="languageOptions" :aria-label="t('language')" @update:model-value="selectLanguage" /></div></section>
            <section id="settings-appearance" class="panel settings-card"><div class="panel-heading"><div><div class="eyebrow">{{ t('appearance') }}</div><h2>{{ t('appearance') }}</h2><p>{{ t('appearanceDescription') }}</p></div></div><div class="settings-body"><span class="settings-label">{{ t('appearanceMode') }}</span><div class="appearance-options" role="group" :aria-label="t('appearanceMode')"><button v-for="item in (['light', 'dark'] as const)" :key="item" class="appearance-button" type="button" :aria-pressed="appearanceMode===item" @click="setAppearanceMode(item)">{{ t(item==='light' ? 'modeLight' : 'modeDark') }}</button></div><span class="settings-label">{{ t('theme') }}</span><div class="theme-options"><button v-for="item in themes" :key="item" class="theme-button" type="button" :class="{ selected: theme === item }" :aria-pressed="theme === item" @click="setTheme(item)"><span class="theme-swatch" :class="item"></span>{{ themeLabel(item) }}</button></div></div></section>
            <section id="settings-power" class="panel settings-card power-card"><div class="panel-heading"><div><div class="eyebrow">{{ t('preferences') }}</div><h2>{{ t('diskPowerPolicy') }}</h2></div><HardDrive :size="19" /></div><div class="settings-body"><p class="muted">{{ t('diskPowerPolicyDescription') }}</p><fieldset class="power-options" :disabled="!preferencesLoaded || preferencesBusy || previewMode"><label><input v-model="wakeSleepingOnVisit" type="radio" :value="false" /><span><strong>{{ t('keepSleeping') }}</strong><small>{{ t('keepSleepingDescription') }}</small></span></label><label><input v-model="wakeSleepingOnVisit" type="radio" :value="true" /><span><strong>{{ t('wakeOnVisit') }}</strong><small>{{ t('wakeOnVisitDescription') }}</small></span></label></fieldset><p v-if="preferencesError" class="login-error" role="alert">{{ preferencesError }}</p><button class="button primary" type="button" :disabled="!preferencesLoaded || preferencesBusy || previewMode || wakeSleepingOnVisit===savedWakeSleepingOnVisit" @click="savePreferences">{{ t('savePowerPolicy') }}</button></div></section>
            <section id="settings-security" class="panel settings-card"><div class="panel-heading"><div><div class="eyebrow">{{ t('security') }}</div><h2>{{ t('securitySettings') }}</h2></div><LockKeyhole :size="19" /></div><div class="settings-body"><p class="muted">{{ t('securitySettingsDescription') }}</p><button class="button security-enter" type="button" @click="go('security', $event)">{{ t('enterSecurity') }} <ArrowRight :size="16" aria-hidden="true" /></button></div></section>
          </div>
        </div>
      </template>
      </template>
    </main>
    <div v-if="confirmation" class="confirm-backdrop" @click.self="answerConfirmation(false)"><section ref="confirmDialog" class="confirm-dialog" role="dialog" aria-modal="true" aria-labelledby="confirm-title" @keydown="onConfirmKeydown"><div class="confirm-heading"><div class="eyebrow">{{ t('checkType') }}</div><h2 id="confirm-title">{{ confirmation.title }}</h2></div><p v-if="confirmation.detail" class="confirm-detail">{{ confirmation.detail }}</p><div v-if="confirmation.targets?.length" class="confirm-targets"><strong>{{ t('assessmentCount') }}: {{ confirmation.targets.length }}</strong><div>{{ confirmation.targets.join(' · ') }}</div></div><div class="confirm-actions"><button ref="confirmCancelButton" class="button" type="button" @click="answerConfirmation(false)">{{ t('cancel') }}</button><button class="button primary" type="button" @click="answerConfirmation(true)">{{ confirmation.action }}</button></div></section></div>
    <Transition name="toast-pop"><div v-if="message" :key="messageSequence" class="toast" role="status"><span>{{ message }}</span><button :aria-label="t('close')" @click="closeMessage"><X :size="19" /></button></div></Transition><Teleport to="body"><div v-if="smartTip" class="smart-tip" role="tooltip" :class="{above:smartTip.above}" :style="{left:`${smartTip.left}px`,top:`${smartTip.top}px`}">{{ smartTip.text }}</div></Teleport>
  </div>
</template>
