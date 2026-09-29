const root = document.documentElement
const reducedMotion = matchMedia('(prefers-reduced-motion: reduce)')

// Discard a saved page-transition URL choice without changing other query parameters.
const initialUrl = new URL(location.href)
if (initialUrl.searchParams.has('page-motion')) {
  initialUrl.searchParams.delete('page-motion')
  history.replaceState(history.state, '', initialUrl)
}
export function routeUrl(path: string) {
  const url = new URL(location.href)
  url.searchParams.delete('page-motion')
  return `${path}${url.search}`
}

// Keep the old screen positions during a resize burst, then move the visible UI together.
const motionElements = () => Array.from(document.querySelectorAll<HTMLElement>('body *')).filter(element =>
  element.getClientRects().length && getComputedStyle(element).visibility !== 'hidden')
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
