<script setup lang="ts">
import { Info } from '@lucide/vue'
import { onBeforeUnmount, onMounted, ref, useId, watch, nextTick } from 'vue'

// 悬浮, 键盘焦点和触摸都能打开.
defineProps<{ text: string; label: string }>()

const id = useId()
const open = ref(false)
const pinned = ref(false)
function pin() {
  pinned.value = true
  open.value = true
}
function hide() {
  pinned.value = false
  open.value = false
}
function leave() {
  if (!pinned.value && !root.value?.contains(document.activeElement)) open.value = false
}
const root = ref<HTMLElement>()
const tooltip = ref<HTMLElement>()
const position = ref({ left: 0, top: 0 })
watch(open, async (value) => {
  if (!value) return
  await nextTick()
  if (!root.value || !tooltip.value) return
  const anchor = root.value.getBoundingClientRect()
  const rect = tooltip.value.getBoundingClientRect()
  const gap =
    parseFloat(getComputedStyle(document.documentElement).getPropertyValue('--spacing')) * 2
  position.value = {
    left: Math.max(
      gap,
      Math.min(anchor.left + anchor.width / 2 - rect.width / 2, innerWidth - rect.width - gap),
    ),
    top: Math.max(
      gap,
      anchor.bottom + gap + rect.height <= innerHeight
        ? anchor.bottom + gap
        : anchor.top - rect.height - gap,
    ),
  }
})

function onOutside(event: PointerEvent) {
  if (!root.value?.contains(event.target as Node) && !tooltip.value?.contains(event.target as Node))
    hide()
}

onMounted(() => document.addEventListener('pointerdown', onOutside))
onBeforeUnmount(() => document.removeEventListener('pointerdown', onOutside))
</script>

<template>
  <span
    ref="root"
    class="relative inline-flex"
    @mouseenter="open = true"
    @mouseleave="leave"
    @keydown.escape="hide"
    @keydown.tab="hide"
  >
    <button
      type="button"
      class="flex size-6 items-center justify-center rounded-full text-muted-foreground hover:text-foreground"
      :aria-label="label"
      :aria-describedby="open ? id : undefined"
      :aria-expanded="open"
      @focus="open = true"
      @blur="!pinned && (open = false)"
      @click="pin"
    >
      <Info class="size-4" aria-hidden="true" />
    </button>
    <Teleport to="body"
      ><span
        ref="tooltip"
        v-if="open"
        :id="id"
        role="tooltip"
        :style="{ left: `${position.left}px`, top: `${position.top}px` }"
        class="fixed z-40 w-max max-w-tip rounded-md border border-border bg-popover p-3 text-sm text-popover-foreground shadow-md"
      >
        {{ text }}
      </span></Teleport
    >
  </span>
</template>
