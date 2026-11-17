<script setup>
// Pure JavaScript Vue 3 Component
defineProps({
  theme: {
    type: String,
    required: true,
  },
});

defineEmits(['toggle']);
</script>

<template>
  <button
    @click="$emit('toggle')"
    class="btn btn-secondary"
    aria-label="Toggle visual theme"
    :title="`Switch to ${theme === 'dark' ? 'Light' : 'Dark'} mode`"
    style="display: inline-flex; align-items: center; gap: 0.5rem; padding: 0.5rem 0.9rem;"
  >
    <span>{{ theme === 'dark' ? '🌙 Dark Mode' : '☀️ Light Mode' }}</span>
  </button>
</template>
