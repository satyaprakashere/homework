<script setup lang="ts">
/**
 * Vue 3 Component: ThemeToggle
 * Demonstrates: defineProps, defineEmits, and modern <script setup> syntax.
 */
defineProps<{
  theme: 'dark' | 'light';
}>();

const emit = defineEmits<{
  (e: 'toggle'): void;
}>();
</script>

<template>
  <button
    @click="emit('toggle')"
    class="btn btn-secondary"
    aria-label="Toggle visual theme"
    :title="`Switch to ${theme === 'dark' ? 'Light' : 'Dark'} mode`"
    style="display: inline-flex; align-items: center; gap: 0.5rem; padding: 0.5rem 0.9rem; cursor: pointer;"
  >
    <span>{{ theme === 'dark' ? '🌙 Dark Mode' : '☀️ Light Mode' }}</span>
  </button>
</template>
