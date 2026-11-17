<script setup>
import { ref } from 'vue';

// Pure JavaScript Vue 3 Component
defineProps({
  isOpen: { type: Boolean, required: true },
});

const emit = defineEmits(['close', 'addService']);

const name = ref('');
const category = ref('Compute');

const handleSubmit = () => {
  if (!name.value.trim()) return;
  emit('addService', {
    id: Date.now(),
    name: name.value.trim(),
    category: category.value,
    latency: Math.floor(Math.random() * 40) + 5,
    status: 'active',
  });
  name.value = '';
  emit('close');
};
</script>

<template>
  <div v-if="isOpen" class="modal-overlay" @click="$emit('close')">
    <div class="modal-content" @click.stop>
      <h3 class="panel-heading" style="margin-bottom: 1rem;">
        ✨ Register New Service
      </h3>
      <p style="font-size: 0.85rem; color: var(--text-secondary); margin-bottom: 1.5rem;">
        Provide cluster service parameters to instantiate a reactive data pipeline.
      </p>

      <form @submit.prevent="handleSubmit">
        <div class="control-group">
          <label class="control-label">Service Name</label>
          <input
            v-model="name"
            type="text"
            class="search-input"
            placeholder="e.g. auth-gateway-v2"
            autofocus
            required
          />
        </div>

        <div class="control-group">
          <label class="control-label">Service Layer</label>
          <select v-model="category" class="search-input">
            <option value="Compute">Compute</option>
            <option value="Storage">Storage</option>
            <option value="Network">Network</option>
          </select>
        </div>

        <div
          style="display: flex; justify-content: flex-end; gap: 0.75rem; margin-top: 1.5rem;"
        >
          <button type="button" @click="$emit('close')" class="btn btn-secondary">
            Cancel
          </button>
          <button type="submit" class="btn btn-primary">
            Deploy Service
          </button>
        </div>
      </form>
    </div>
  </div>
</template>
