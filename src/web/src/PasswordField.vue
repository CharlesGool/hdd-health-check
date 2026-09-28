<script setup lang="ts">
import { ref } from 'vue'
import { Eye, EyeOff } from '@lucide/vue'

defineProps<{
  id: string
  modelValue: string
  autocomplete: string
  showLabel: string
  hideLabel: string
  required?: boolean
  minlength?: number
  maxlength?: number
}>()

const emit = defineEmits<{ 'update:modelValue': [value: string] }>()
const shown = ref(false)

function toggle() {
  shown.value = !shown.value
}
</script>

<template>
  <div class="password-field">
    <input
      :id="id"
      class="app-login-field"
      :type="shown ? 'text' : 'password'"
      :value="modelValue"
      :autocomplete="autocomplete"
      :required="required"
      :minlength="minlength"
      :maxlength="maxlength"
      @input="emit('update:modelValue', ($event.target as HTMLInputElement).value)"
    />
    <button
      class="app-login-password-toggle"
      type="button"
      :aria-label="shown ? hideLabel : showLabel"
      :aria-pressed="shown"
      @pointerdown.prevent
      @click="toggle"
    >
      <EyeOff v-if="shown" :size="18" aria-hidden="true" />
      <Eye v-else :size="18" aria-hidden="true" />
    </button>
  </div>
</template>
