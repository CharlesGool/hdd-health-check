import { cssDuration, reducedMotion } from './motion'

// 调整窗口时: 带 data-reflow 的元素先停在原位置, 停止调整 --resize-settle 后以 --duration-resize 移到新位置.
// data-reflow 元素之间禁止嵌套.
// resize 事件触发时布局已是新尺寸, 所以平时持续记录最近一次绘制的位置(页面坐标).
type Point = { x: number; y: number }

function pagePosition(el: HTMLElement): Point {
  const rect = el.getBoundingClientRect()
  return { x: rect.left + window.scrollX, y: rect.top + window.scrollY }
}

export function initResizeReflow() {
  const coarse = matchMedia('(pointer: coarse)')
  let painted = new Map<HTMLElement, Point>()
  let anchored: Map<HTMLElement, Point> | null = null
  let settleTimer: ReturnType<typeof setTimeout> | undefined
  let animatingUntil = 0
  let frame = 0
  let lastWidth = window.innerWidth
  let recordTimer: ReturnType<typeof setTimeout> | undefined
  const preference = matchMedia('(prefers-reduced-motion: reduce)')

  function reset() {
    clearTimeout(settleTimer)
    clearTimeout(recordTimer)
    cancelAnimationFrame(frame)
    frame = 0
    for (const el of new Set([...painted.keys(), ...(anchored?.keys() || [])])) {
      el.style.transition = ''
      el.style.transform = ''
    }
    anchored = null
    animatingUntil = 0
    lastWidth = innerWidth
    scheduleRecord()
  }

  const resizeObserver = new ResizeObserver(() => scheduleRecord())

  function record() {
    frame = 0
    if (anchored) return
    const previous = painted
    painted = new Map()
    for (const el of document.querySelectorAll<HTMLElement>('[data-reflow]')) {
      painted.set(el, pagePosition(el))
      // observe 会立即回调一次, 只观察新元素以免逐帧循环
      if (!previous.has(el)) resizeObserver.observe(el)
    }
    for (const el of previous.keys()) {
      if (!painted.has(el)) resizeObserver.unobserve(el)
    }
    // 过渡进行中逐帧记录视觉位置, 新的调整从当前视觉位置开始, 替换而不是累积
    if (performance.now() < animatingUntil) scheduleRecord()
  }

  function scheduleRecord() {
    if (!frame) frame = requestAnimationFrame(record)
  }

  function onResize() {
    const widthChanged = window.innerWidth !== lastWidth
    lastWidth = window.innerWidth
    // 触摸设备上只有高度变化时是浏览器工具栏伸缩
    if ((!widthChanged && coarse.matches) || reducedMotion()) return

    if (!anchored) anchored = painted
    for (const [el, before] of anchored) {
      if (!el.isConnected) continue
      el.style.transition = 'none'
      el.style.transform = 'none'
      const after = pagePosition(el)
      el.style.transform = `translate(${before.x - after.x}px, ${before.y - after.y}px)`
    }
    clearTimeout(settleTimer)
    settleTimer = setTimeout(settle, cssDuration('--resize-settle'))
  }

  function settle() {
    if (!anchored) return
    for (const el of anchored.keys()) {
      el.style.transition = 'transform var(--duration-resize) var(--ease-standard)'
      el.style.transform = ''
    }
    anchored = null
    animatingUntil = performance.now() + cssDuration('--duration-resize')
    scheduleRecord()
    recordTimer = setTimeout(scheduleRecord, cssDuration('--duration-resize'))
  }

  const mutationObserver = new MutationObserver(scheduleRecord)
  mutationObserver.observe(document.body, {
    childList: true,
    subtree: true,
    characterData: true,
    attributes: true,
    attributeFilter: ['class', 'data-reflow'],
  })
  window.addEventListener('resize', onResize)
  preference.addEventListener('change', reset)
  scheduleRecord()
  return {
    refresh: reset,
    stop() {
      reset()
      cancelAnimationFrame(frame)
      resizeObserver.disconnect()
      mutationObserver.disconnect()
      window.removeEventListener('resize', onResize)
      preference.removeEventListener('change', reset)
    },
  }
}
