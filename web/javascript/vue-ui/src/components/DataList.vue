<script setup>
import { computed } from 'vue';

// Pure JavaScript Vue 3 Component
const props = defineProps({
  items: { type: Array, required: true },
  searchTerm: { type: String, required: true },
  activeCategory: { type: String, required: true },
});

defineEmits(['update:searchTerm', 'openModal']);

// Reactive computed filtering in Vue 3 Composition API
const filteredItems = computed(() => {
  return props.items.filter((item) => {
    const matchesSearch = item.name
      .toLowerCase()
      .includes(props.searchTerm.toLowerCase());
    const matchesCategory =
      props.activeCategory === 'All' || item.category === props.activeCategory;
    return matchesSearch && matchesCategory;
  });
});
</script>

<template>
  <div class="glass-panel">
    <div
      style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 1rem;"
    >
      <h3 class="panel-heading" style="margin: 0;">
        📊 Data Services ({{ filteredItems.length }})
      </h3>
      <button
        @click="$emit('openModal')"
        class="btn btn-primary"
        style="padding: 0.4rem 0.8rem; font-size: 0.8rem;"
      >
        + Add Service
      </button>
    </div>

    <input
      type="text"
      class="search-input"
      placeholder="Filter services by name..."
      :value="searchTerm"
      @input="$emit('update:searchTerm', $event.target.value)"
    />

    <div class="data-list">
      <div
        v-if="filteredItems.length === 0"
        style="text-align: center; padding: 2rem; color: var(--text-muted);"
      >
        No services match "{{ searchTerm }}" in category "{{ activeCategory }}"
      </div>

      <div
        v-for="item in filteredItems"
        :key="item.id"
        class="data-item"
      >
        <div>
          <div style="font-weight: 600; font-size: 0.9rem;">
            {{ item.name }}
          </div>
          <div
            style="font-size: 0.75rem; color: var(--text-muted); font-family: var(--font-mono);"
          >
            {{ item.category }} • Latency: {{ item.latency }}ms
          </div>
        </div>
        <span
          :class="[
            'status-badge',
            item.status === 'active' ? 'status-active' : 'status-standby',
          ]"
        >
          {{ item.status }}
        </span>
      </div>
    </div>
  </div>
</template>
