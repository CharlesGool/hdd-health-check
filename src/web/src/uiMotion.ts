type ViewTransitionHandle = { ready: Promise<void>; finished: Promise<void>; skipTransition: () => void }
type ViewTransitionDocument = Document & { startViewTransition?: (update: () => Promise<void>) => ViewTransitionHandle }
type RouteMotion = { source?: HTMLElement | null; returnTo?: string; reverseSlide?: boolean; detailReturn?: boolean }

const root = document.documentElement
const reducedMotion = matchMedia('(prefers-reduced-motion: reduce)')
const mobileDevice = /Android|iPhone|iPod/i.test(navigator.userAgent) ||
  (/Macintosh/i.test(navigator.userAgent) && navigator.maxTouchPoints > 1)
const storageKey = 'hdd-page-motion'

function savedChoice(): boolean {
  const urlChoice = new URL(location.href).searchParams.get('page-motion')
  if (urlChoice === 'on' || urlChoice === 'off') return urlChoice === 'on'
  try {
    const choice = localStorage.getItem(storageKey)
    if (choice === 'on' || choice === 'off') return choice === 'on'
  } catch { /* The URL and cookie still preserve an explicit choice. */ }
  const cookieChoice = document.cookie.match(/(?:^|; )hdd_page_motion=(on|off)(?:;|$)/)?.[1]
  if (cookieChoice) return cookieChoice === 'on'
  return !mobileDevice
}

let enabled = savedChoice()
root.dataset.pageMotion = enabled ? 'on' : 'off'
let activeTransition: ViewTransitionHandle | null = null
let cover: HTMLElement | null = null
let marker: HTMLElement | null = null
let pressed: HTMLElement | null = null
let pressTimer: ReturnType<typeof setTimeout> | undefined
let pressResolve: (() => void) | null = null
let routeGeneration = 0
let originBounds: DOMRect | null = null
const classes = ['viewport-enter', 'viewport-exit', 'page-slide', 'page-slide-reverse', 'detail-return']
const vars = ['--route-x', '--route-y', '--route-scale-x', '--route-scale-y', '--route-cover-scale-x', '--route-cover-scale-y']

function clearPressed() { if (pressTimer) clearTimeout(pressTimer); pressTimer = undefined; pressResolve?.(); pressResolve = null; pressed?.classList.remove('route-press'); pressed = null }
function clearRoute() {
  cover?.remove(); cover = null
  marker?.remove(); marker = null
  root.classList.remove(...classes)
  vars.forEach(name => root.style.removeProperty(name))
  originBounds = null
  clearPressed()
}
function setOrigin(bounds: DOMRect, width = innerWidth, height = innerHeight, offsetX = 0, offsetY = 0) {
  originBounds = bounds
  root.style.setProperty('--route-x', `${bounds.left + offsetX}px`)
  root.style.setProperty('--route-y', `${bounds.top + offsetY}px`)
  root.style.setProperty('--route-scale-x', String(Math.max(.01, bounds.width / width)))
  root.style.setProperty('--route-scale-y', String(Math.max(.01, bounds.height / height)))
  root.style.setProperty('--route-cover-scale-x', String(width / bounds.width))
  root.style.setProperty('--route-cover-scale-y', String(height / bounds.height))
}
function visible(element: HTMLElement | null): element is HTMLElement { return !!element && element.getClientRects().length > 0 }
function makeCover(element: HTMLElement) {
  const bounds = element.getBoundingClientRect()
  cover = element.cloneNode(true) as HTMLElement
  cover.querySelectorAll('[id]').forEach(node => node.removeAttribute('id'))
  cover.removeAttribute('id')
  cover.classList.remove('route-press')
  cover.classList.add('route-cover')
  cover.inert = true
  cover.setAttribute('aria-hidden', 'true')
  Object.assign(cover.style, { left: `${bounds.left}px`, top: `${bounds.top}px`, width: `${bounds.width}px`, height: `${bounds.height}px` })
  document.body.append(cover)
  setOrigin(bounds)
}
function makeMarker() {
  marker = document.createElement('span')
  marker.setAttribute('aria-hidden', 'true')
  Object.assign(marker.style, { position: 'fixed', left: '0', top: '0', width: '1px', height: '1px', opacity: '0', pointerEvents: 'none', viewTransitionName: 'route-calibration' })
  document.body.append(marker)
}
function calibrate(transition: ViewTransitionHandle, returning: boolean) {
  transition.ready.then(() => {
    if (transition !== activeTransition || !originBounds) return
    const animation = document.getAnimations().find(item => (item.effect as KeyframeEffect | null)?.pseudoElement === '::view-transition-group(route-calibration)')
    const oldTime = animation?.currentTime
    if (animation) animation.currentTime = returning ? (animation.effect as KeyframeEffect).getComputedTiming().endTime || 0 : 0
    const style = getComputedStyle(root, '::view-transition-group(route-calibration)')
    const width = parseFloat(style.width)
    const transform = style.transform
    if (animation && oldTime !== null && oldTime !== undefined) animation.currentTime = oldTime ?? null
    if (width !== 1) return
    const offset = new DOMMatrixReadOnly(transform)
    const snapshot = getComputedStyle(root, '::view-transition')
    setOrigin(originBounds, parseFloat(snapshot.width) || innerWidth, parseFloat(snapshot.height) || innerHeight, offset.m41, offset.m42)
  }).catch(() => { /* A resize can cancel the snapshot. */ })
}

export function pageMotionEnabled() { return enabled }
export function setPageMotion(value: boolean) {
  enabled = value
  root.dataset.pageMotion = value ? 'on' : 'off'
  try { localStorage.setItem(storageKey, value ? 'on' : 'off') } catch { /* URL fallback below. */ }
  try { document.cookie = `hdd_page_motion=${value ? 'on' : 'off'}; Max-Age=31536000; Path=/; SameSite=Lax` } catch { /* URL fallback below. */ }
  const url = new URL(location.href)
  url.searchParams.set('page-motion', value ? 'on' : 'off')
  history.replaceState(history.state, '', url)
  if (!value) { activeTransition?.skipTransition(); activeTransition = null; clearRoute() }
}
export function routeUrl(path: string) { return `${path}${location.search}` }
export function stopRouteMotion() { routeGeneration++; activeTransition?.skipTransition(); activeTransition = null; clearRoute() }

export async function transitionRoute(update: () => Promise<void>, motion: RouteMotion = {}) {
  stopRouteMotion()
  const generation = routeGeneration
  const viewDocument = document as ViewTransitionDocument
  if (!enabled || reducedMotion.matches || !viewDocument.startViewTransition) { await update(); refreshResizeBaseline(); return }
  const source = !motion.detailReturn && visible(motion.source || null) ? motion.source! : null
  if (source) {
    pressed = source
    source.classList.add('route-press')
    await new Promise<void>(resolve => { pressResolve = resolve; pressTimer = setTimeout(() => { pressResolve = null; pressTimer = undefined; resolve() }, 70) })
    if (generation !== routeGeneration) return
    if (!enabled) { clearPressed(); await update(); refreshResizeBaseline(); return }
  }
  const returning = !motion.detailReturn && !source && !!motion.returnTo
  root.classList.add(motion.detailReturn ? 'detail-return' : source ? 'viewport-enter' : returning ? 'viewport-exit' : motion.reverseSlide ? 'page-slide-reverse' : 'page-slide')
  if (source) makeCover(source)
  if (source || returning) makeMarker()
  const transition = viewDocument.startViewTransition(async () => {
    clearPressed()
    await update()
    if (returning) {
      const target = document.querySelector<HTMLElement>(`[data-motion-id="${CSS.escape(motion.returnTo!)}"]`)
      if (visible(target)) {
        if (target.getBoundingClientRect().top < 0 || target.getBoundingClientRect().bottom > innerHeight) target.scrollIntoView({ behavior: 'instant', block: 'center' })
        makeCover(target)
      } else { root.classList.remove('viewport-exit'); root.classList.add('page-slide-reverse') }
    }
  })
  activeTransition = transition
  if (marker) calibrate(transition, returning)
  await transition.finished.catch(() => { /* Interrupted transitions fall back to the updated page. */ })
  if (activeTransition === transition) { activeTransition = null; clearRoute(); refreshResizeBaseline() }
}

// Keep the old screen positions during a resize burst, then move the visible UI together.
const motionElements = () => Array.from(document.querySelectorAll<HTMLElement>('body *')).filter(element =>
  element.getClientRects().length && getComputedStyle(element).visibility !== 'hidden' && !element.classList.contains('route-cover'))
const screenOrigin = () => {
  const difference = outerWidth - innerWidth
  const frame = difference >= 0 && difference <= 80 ? difference / 2 : 0
  return { x: screenX + frame, y: screenY + Math.max(0, outerHeight - innerHeight - frame) }
}
type Position = { left: number; top: number }
type Layout = Map<HTMLElement, Position>
function visualOffset(element: HTMLElement) {
  let x = 0, y = 0
  for (let current: HTMLElement | null = element; current && current !== document.body; current = current.parentElement) {
    const transform = new DOMMatrixReadOnly(getComputedStyle(current).transform)
    x += transform.m41; y += transform.m42
  }
  return { x, y }
}
function captureLayout(): Layout {
  const origin = screenOrigin()
  return new Map(motionElements().map(element => {
    const rect = element.getBoundingClientRect()
    return [element, { left: rect.left + origin.x, top: rect.top + origin.y }]
  }))
}
let lastLayout: Layout = new Map()
let lastWidth = innerWidth, lastHeight = innerHeight, lastOrigin = screenOrigin()
let frozen: { origin: { x: number; y: number }; scrollY: number } | null = null
let settleTimer: ReturnType<typeof setTimeout> | undefined
let clipTimer: ReturnType<typeof setTimeout> | undefined
let resizeFrame = 0
let layoutAnimations: Animation[] = []
function clearLayoutAnimations() { layoutAnimations.forEach(animation => animation.cancel()); layoutAnimations = []; motionElements().forEach(element => { if (element.dataset.resizeFrozen) { element.style.transform = ''; delete element.dataset.resizeFrozen } }) }
function applyRelativeMotion(before: Layout, after: Layout, animate: boolean) {
  const deltas = new Map<HTMLElement, { x: number; y: number }>()
  after.forEach((next, element) => {
    const previous = before.get(element)
    if (previous) deltas.set(element, { x: previous.left - next.left, y: previous.top - next.top })
  })
  deltas.forEach((delta, element) => {
    let parent = element.parentElement
    while (parent && !deltas.has(parent)) parent = parent.parentElement
    const parentDelta = parent ? deltas.get(parent) || { x: 0, y: 0 } : { x: 0, y: 0 }
    const x = delta.x - parentDelta.x, y = delta.y - parentDelta.y
    if (Math.abs(x) < 2 && Math.abs(y) < 2) return
    const base = getComputedStyle(element).transform
    const from = `translate(${x}px, ${y}px)${base === 'none' ? '' : ` ${base}`}`
    if (animate) layoutAnimations.push(element.animate([{ transform: from }, { transform: base }], { duration: 620, easing: 'cubic-bezier(.22,1,.36,1)', fill: 'backwards' }))
    else { element.style.transform = from; element.dataset.resizeFrozen = '1' }
  })
}
function unfreeze(keepClip = false) {
  document.body.style.width = ''; document.body.style.transform = ''
  root.style.removeProperty('--frozen-viewport-height')
  if (!keepClip) root.classList.remove('layout-resizing')
  clearLayoutAnimations(); frozen = null
}
function finishResize() {
  if (!frozen) return
  const before = captureLayout()
  unfreeze(true)
  const after = captureLayout()
  if (!reducedMotion.matches) applyRelativeMotion(before, after, true)
  lastLayout = after; lastWidth = innerWidth; lastHeight = innerHeight; lastOrigin = screenOrigin()
  if (clipTimer) clearTimeout(clipTimer)
  clipTimer = setTimeout(() => root.classList.remove('layout-resizing'), 660)
}
function onResize() {
  cancelAnimationFrame(resizeFrame)
  resizeFrame = requestAnimationFrame(() => {
    if (matchMedia('(pointer: coarse)').matches && innerWidth === lastWidth && !frozen) { lastLayout = captureLayout(); lastHeight = innerHeight; lastOrigin = screenOrigin(); return }
    if (activeTransition) stopRouteMotion()
    if (reducedMotion.matches) { unfreeze(); refreshResizeBaseline(); return }
    if (!frozen) {
      if (clipTimer) clearTimeout(clipTimer)
      const previous = new Map([...lastLayout].map(([element, position]) => {
        const offset = visualOffset(element)
        return [element, { left: position.left + offset.x, top: position.top + offset.y }] as [HTMLElement, Position]
      }))
      clearLayoutAnimations()
      frozen = { origin: lastOrigin, scrollY: scrollY }
      document.body.style.width = `${lastWidth}px`
      root.style.setProperty('--frozen-viewport-height', `${lastHeight}px`)
      root.classList.add('layout-resizing')
      const origin = screenOrigin()
      document.body.style.transform = `translate(${lastOrigin.x - origin.x}px, ${lastOrigin.y - origin.y}px)`
      applyRelativeMotion(previous, captureLayout(), false)
    }
    const currentFreeze = frozen
    if (!currentFreeze) return
    const origin = screenOrigin()
    document.body.style.transform = `translate(${currentFreeze.origin.x - origin.x}px, ${currentFreeze.origin.y - origin.y + scrollY - currentFreeze.scrollY}px)`
    if (settleTimer) clearTimeout(settleTimer)
    settleTimer = setTimeout(finishResize, 180)
  })
}
export function refreshResizeBaseline() {
  if (frozen) { if (settleTimer) clearTimeout(settleTimer); unfreeze() }
  lastLayout = captureLayout(); lastWidth = innerWidth; lastHeight = innerHeight; lastOrigin = screenOrigin()
}
export function installResizeMotion() {
  requestAnimationFrame(refreshResizeBaseline)
  addEventListener('resize', onResize)
  return () => { removeEventListener('resize', onResize); cancelAnimationFrame(resizeFrame); if (settleTimer) clearTimeout(settleTimer); if (clipTimer) clearTimeout(clipTimer); unfreeze() }
}
