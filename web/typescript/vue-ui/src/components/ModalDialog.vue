<script setup lang="ts">
import { onMounted, onUnmounted } from 'vue';

/**
 * Vue 3 Component: ModalDialog
 * Demonstrates: Lifecycle hooks (onMounted, onUnmounted), slots (<slot />), and v-if.
 */
const props = defineProps<{
  isOpen: boolean;
  title: string;
}>();

const emit = defineEmits<{
  (e: 'close'): void;
}>();

const handleKeyDown = (e: KeyboardEvent) => {
  if (e.key === 'Escape' && props.isOpen) {
    emit('close');
  }
};

onMounted(() => {
  window.addEventListener('keydown', handleKeyDown);
});

onUnmounted(() => {
  window.removeEventListener('keydown', handleKeyDown);
});
</script>

<template>
  <div
    v-if="isOpen"
    class="modal-overlay"
    @click.self="emit('close')"
    role="dialog"
    aria-modal="true"
  >
    <div class="modal-content">
      <div class="modal-header">
        <h3 style="font-size: 1.25rem; font-weight: 700;">{{ title }}</h3>
        <button
          class="modal-close"
          @click="emit('close')"
          aria-label="Close modal"
        >
          ✕
        </button>
      </div>

      <div style="margin-bottom: 1.5rem; color: var(--text-secondary);">
        <!-- Vue Slot: Transcluded template content from parent -->
        <slot />
      </div>

      <div style="display: flex; justify-content: flex-end; gap: 0.75rem;">
        <button class="btn btn-secondary" @click="emit('close')">
          Dismiss
        </button>
        <button class="btn btn-primary" @click="emit('close')">
          Confirm Action
        </button>
      </div>
    </div>
  </div>
</template>
