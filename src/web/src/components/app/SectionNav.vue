<script setup lang="ts">
import { onBeforeUnmount, onMounted, ref, watch, nextTick } from 'vue'
import { reducedMotion } from '@/lib/motion'

// 两个及以上设置组: 左侧分区导航, 窄屏时位于内容上方.
const props = defineProps<{
  sections: { id: string; label: string }[]
  label: string
}>()
const current = ref<string | undefined>(props.sections[0]?.id)
let frame = 0
function update() {
  const sections = props.sections
    .map((section) => ({
      section,
      element: document.getElementById(section.id),
    }))
    .filter((item) => item.element)
  const passed = sections.filter(
    (item) => item.element!.getBoundingClientRect().top <= innerHeight * 0.35,
  )
  const atBottom = scrollY + innerHeight >= document.documentElement.scrollHeight - 2
  current.value = (atBottom ? sections.at(-1) : passed.at(-1) || sections[0])?.section.id
}
function scheduleUpdate() {
  cancelAnimationFrame(frame)
  frame = requestAnimationFrame(update)
}
function jump(id: string) {
  current.value = id
  history.replaceState(history.state, '', `${location.pathname}${location.search}#${id}`)
  document.getElementById(id)?.scrollIntoView({
    behavior: reducedMotion() ? 'auto' : 'smooth',
    block: 'start',
  })
}
onMounted(() => {
  update()
  addEventListener('scroll', scheduleUpdate, { passive: true })
  addEventListener('resize', scheduleUpdate)
})
watch(
  () => props.sections,
  () => nextTick(update),
  { deep: true },
)
onBeforeUnmount(() => {
  cancelAnimationFrame(frame)
  removeEventListener('scroll', scheduleUpdate)
  removeEventListener('resize', scheduleUpdate)
})
</script>

<template>
  <nav data-reflow :aria-label="label" class="md:sticky md:top-6">
    <ul class="flex flex-wrap gap-1 md:flex-col">
      <li v-for="section in sections" :key="section.id">
        <a
          :href="`#${section.id}`"
          class="flex h-9 items-center rounded-md px-3 text-sm font-medium transition-colors"
          :class="
            current === section.id
              ? 'bg-accent text-accent-foreground'
              : 'text-muted-foreground hover:text-foreground'
          "
          :aria-current="current === section.id ? 'location' : undefined"
          @click.prevent="jump(section.id)"
        >
          {{ section.label }}
        </a>
      </li>
    </ul>
  </nav>
</template>
