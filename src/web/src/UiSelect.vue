<script setup lang="ts">
import { computed, nextTick, onMounted, onUnmounted, ref, useId, watch } from 'vue'
import { Check, ChevronDown } from '@lucide/vue'

type Option = { value: string; label: string }
const props = defineProps<{ modelValue: string; options: Option[]; id?: string; disabled?: boolean; ariaLabel?: string }>()
const emit = defineEmits<{ 'update:modelValue': [value: string] }>()

const root = ref<HTMLElement | null>(null)
const trigger = ref<HTMLButtonElement | null>(null)
const list = ref<HTMLElement | null>(null)
const expanded = ref(false)
const above = ref(false)
const activeIndex = ref(0)
const generatedId = useId()
const listId = `select-list-${generatedId}`
const selectedIndex = computed(() => props.options.findIndex(option => option.value === props.modelValue))
const selectedLabel = computed(() => props.options[selectedIndex.value]?.label || props.options[0]?.label || '—')
let search = ''
let searchTimer: ReturnType<typeof setTimeout> | undefined

function close(restoreFocus = false) {
  expanded.value = false
  search = ''
  if (searchTimer) clearTimeout(searchTimer)
  if (restoreFocus) trigger.value?.focus()
}

function scrollActive() {
  void nextTick(() => list.value?.querySelectorAll('[role="option"]')[activeIndex.value]?.scrollIntoView({ block: 'nearest' }))
}

function open() {
  if (props.disabled || !props.options.length) return
  activeIndex.value = Math.max(0, selectedIndex.value)
  const rect = root.value?.getBoundingClientRect()
  const height = Math.min(props.options.length * 42 + 12, 280)
  above.value = !!rect && window.innerHeight - rect.bottom < height + 12 && rect.top > height + 12
  expanded.value = true
  scrollActive()
}

function choose(index: number) {
  const option = props.options[index]
  if (!option || props.disabled) return
  emit('update:modelValue', option.value)
  close(true)
}

function move(delta: number) {
  if (!expanded.value) open()
  else activeIndex.value = (activeIndex.value + delta + props.options.length) % props.options.length
  scrollActive()
}

function onKeydown(event: KeyboardEvent) {
  if (props.disabled) return
  if (event.key === 'ArrowDown' || event.key === 'ArrowUp') {
    event.preventDefault()
    move(event.key === 'ArrowDown' ? 1 : -1)
  } else if (event.key === 'Home' || event.key === 'End') {
    event.preventDefault()
    if (!expanded.value) open()
    activeIndex.value = event.key === 'Home' ? 0 : props.options.length - 1
    scrollActive()
  } else if (event.key === 'Enter' || event.key === ' ') {
    event.preventDefault()
    if (expanded.value) choose(activeIndex.value)
    else open()
  } else if (event.key === 'Escape' && expanded.value) {
    event.preventDefault()
    close(true)
  } else if (event.key === 'Tab') {
    close()
  } else if (event.key.length === 1 && !event.altKey && !event.ctrlKey && !event.metaKey) {
    search += event.key.toLocaleLowerCase()
    if (searchTimer) clearTimeout(searchTimer)
    searchTimer = setTimeout(() => { search = '' }, 650)
    const match = props.options.findIndex(option => option.label.toLocaleLowerCase().startsWith(search))
    if (match >= 0) {
      if (!expanded.value) open()
      activeIndex.value = match
      scrollActive()
    }
  }
}

function onOutside(event: PointerEvent) {
  if (expanded.value && !root.value?.contains(event.target as Node)) close()
}

watch(() => props.disabled, disabled => { if (disabled) close() })
watch(() => props.options, options => { if (expanded.value && !options.some(option => option.value === props.modelValue)) close() })
onMounted(() => document.addEventListener('pointerdown', onOutside))
onUnmounted(() => {
  document.removeEventListener('pointerdown', onOutside)
  if (searchTimer) clearTimeout(searchTimer)
})
</script>

<template>
  <div ref="root" class="ui-select" :class="{ 'is-open': expanded, 'is-above': above }">
    <button
      :id="id"
      ref="trigger"
      class="ui-select-trigger"
      type="button"
      role="combobox"
      aria-haspopup="listbox"
      :aria-label="ariaLabel"
      :aria-expanded="expanded"
      :aria-controls="listId"
      :aria-activedescendant="expanded ? `${listId}-option-${activeIndex}` : undefined"
      :disabled="disabled"
      @click="expanded ? close() : open()"
      @keydown="onKeydown"
    >
      <span class="ui-select-value">{{ selectedLabel }}</span>
      <ChevronDown :size="16" aria-hidden="true" />
    </button>
    <ul v-if="expanded" :id="listId" ref="list" class="ui-select-list" role="listbox" :aria-label="ariaLabel">
      <li
        v-for="(option, index) in options"
        :id="`${listId}-option-${index}`"
        :key="option.value"
        class="ui-select-option"
        :class="{ 'is-active': activeIndex === index, 'is-selected': modelValue === option.value }"
        role="option"
        :aria-selected="modelValue === option.value"
        @pointermove="activeIndex = index"
        @click="choose(index)"
      ><span>{{ option.label }}</span><Check v-if="modelValue === option.value" :size="15" aria-hidden="true" /></li>
    </ul>
  </div>
</template>
