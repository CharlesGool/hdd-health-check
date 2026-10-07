<script setup lang="ts">
import { Check, ChevronDown } from '@lucide/vue'
import {
  SelectContent,
  SelectItem,
  SelectItemIndicator,
  SelectItemText,
  SelectPortal,
  SelectRoot,
  SelectTrigger,
  SelectValue,
  SelectViewport,
} from 'reka-ui'

// 八种主题色超过 5 个选项, 使用无障碍列表框.
defineProps<{ label: string; options: { value: string; label: string }[] }>()
const theme = defineModel<string>({ required: true })
</script>

<template>
  <SelectRoot v-model="theme">
    <SelectTrigger
      :aria-label="label"
      class="flex h-9 w-full items-center justify-between gap-2 rounded-md border border-input bg-card px-3 text-sm sm:w-64"
    >
      <span class="flex items-center gap-2">
        <span class="theme-swatch size-4 rounded-full" :data-theme="theme" aria-hidden="true" />
        <SelectValue>{{ options.find((item) => item.value === theme)?.label }}</SelectValue>
      </span>
      <ChevronDown class="size-4 text-muted-foreground" aria-hidden="true" />
    </SelectTrigger>
    <SelectPortal>
      <SelectContent
        position="popper"
        :side-offset="4"
        class="z-50 min-w-(--reka-select-trigger-width) overflow-hidden rounded-md border border-border bg-popover text-popover-foreground shadow-md"
      >
        <SelectViewport class="p-1">
          <SelectItem
            v-for="item in options"
            :key="item.value"
            :value="item.value"
            class="relative flex h-9 cursor-pointer select-none items-center gap-2 rounded-sm pr-8 pl-2 text-sm outline-none data-highlighted:bg-accent data-highlighted:text-accent-foreground"
          >
            <span
              class="theme-swatch size-4 rounded-full"
              :data-theme="item.value"
              aria-hidden="true"
            />
            <SelectItemText>{{ item.label }}</SelectItemText>
            <SelectItemIndicator class="absolute right-2">
              <Check class="size-4" aria-hidden="true" />
            </SelectItemIndicator>
          </SelectItem>
        </SelectViewport>
      </SelectContent>
    </SelectPortal>
  </SelectRoot>
</template>

<style scoped>
.theme-swatch {
  background-color: var(--theme-swatch);
}
</style>
