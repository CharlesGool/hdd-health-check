<script setup lang="ts">
import { HardDrive, LogOut } from '@lucide/vue'
import { Button } from '../ui/button'
defineProps<{
  authenticated: boolean
  login: boolean
  version: string
  subtitle: string
  navigationLabel: string
  logoutLabel: string
  showLogout: boolean
  items: { href: string; label: string; current?: 'page' | 'location' }[]
}>()
const emit = defineEmits<{
  navigate: [event: MouseEvent, href: string]
  logout: []
}>()
</script>
<template>
  <header data-reflow class="topbar site-header" :class="{ 'app-login-header': login }">
    <div class="flex min-w-0 flex-wrap items-center gap-x-3 gap-y-1">
      <a
        href="/disks"
        class="brand flex min-w-0 items-center gap-3"
        @click="emit('navigate', $event, '/disks')"
      >
        <span
          class="brand-icon flex shrink-0 items-center justify-center rounded-md bg-primary text-primary-foreground"
          :class="{ 'app-login-brand-logo': login }"
          ><HardDrive class="size-5" aria-hidden="true"
        /></span>
        <span class="min-w-0"
          ><strong>HDD Health</strong><small>{{ subtitle }}</small></span
        >
      </a>
      <a
        v-if="!login"
        class="version brand-version text-sm text-muted-foreground hover:text-foreground"
        href="/changelog"
        @click="emit('navigate', $event, '/changelog')"
        >{{ version }}</a
      >
    </div>
    <nav v-if="items.length" :aria-label="navigationLabel">
      <ul class="flex flex-wrap items-center gap-1">
        <li v-for="item in items" :key="item.href">
          <a
            :href="item.href"
            class="flex h-9 items-center rounded-md px-3 text-sm font-medium transition-colors"
            :class="
              item.current
                ? 'bg-primary text-primary-foreground'
                : 'text-muted-foreground hover:bg-accent hover:text-accent-foreground'
            "
            :aria-current="item.current"
            @click="emit('navigate', $event, item.href)"
            >{{ item.label }}</a
          >
        </li>
        <li v-if="authenticated && showLogout">
          <Button variant="ghost" type="button" @click="emit('logout')"
            ><LogOut aria-hidden="true" />{{ logoutLabel }}</Button
          >
        </li>
      </ul>
    </nav>
  </header>
</template>
