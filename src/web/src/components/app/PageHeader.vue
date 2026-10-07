<script setup lang="ts">
import { ArrowLeft } from '@lucide/vue'
import { Button } from '../ui/button'
defineProps<{ title?: string; description?: string; backLabel?: string }>()
const emit = defineEmits<{ back: [event: MouseEvent] }>()
</script>
<template>
  <div data-reflow class="mb-6 flex flex-col gap-3">
    <div v-if="backLabel || $slots.actions" class="flex items-center justify-between gap-3">
      <Button
        v-if="backLabel"
        variant="ghost"
        size="sm"
        type="button"
        class="-ml-3"
        @click="emit('back', $event)"
        ><ArrowLeft aria-hidden="true" />{{ backLabel }}</Button
      >
      <span v-else /><slot name="actions" />
    </div>
    <h1 v-if="title" class="text-2xl font-semibold">{{ title }}</h1>
    <p v-if="description" class="text-muted-foreground">{{ description }}</p>
    <slot />
  </div>
</template>
