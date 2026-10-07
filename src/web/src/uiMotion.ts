import { initResizeReflow } from './lib/resize-reflow'

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

let controller: ReturnType<typeof initResizeReflow> | undefined
export function refreshResizeBaseline() {
  controller?.refresh()
}
export function installResizeMotion() {
  controller?.stop()
  controller = initResizeReflow()
  return () => {
    controller?.stop()
    controller = undefined
  }
}
