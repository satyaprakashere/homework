<script setup>
import { ref, computed, watch, onMounted } from 'vue';
import ThemeToggle from './components/ThemeToggle.vue';
import MetricCard from './components/MetricCard.vue';
import InteractiveControls from './components/InteractiveControls.vue';
import DataList from './components/DataList.vue';
import ModalDialog from './components/ModalDialog.vue';

const theme = ref('dark');
const velocity = ref(6);
const activeCategory = ref('All');
const gpuAcceleration = ref(true);
const searchTerm = ref('');
const isModalOpen = ref(false);

const services = ref([
  { id: 1, name: 'api-gateway-edge', category: 'Network', latency: 12, status: 'active' },
  { id: 2, name: 'vector-search-engine', category: 'Compute', latency: 28, status: 'active' },
  { id: 3, name: 'redis-cache-cluster', category: 'Storage', latency: 4, status: 'active' },
  { id: 4, name: 'neural-inference-worker', category: 'Compute', latency: 64, status: 'standby' },
  { id: 5, name: 's3-blob-replicator', category: 'Storage', latency: 45, status: 'active' },
]);

const syncTheme = () => {
  document.documentElement.setAttribute('data-theme', theme.value);
};

onMounted(() => {
  syncTheme();
});

watch(theme, () => {
  syncTheme();
});

const toggleTheme = () => {
  theme.value = theme.value === 'dark' ? 'light' : 'dark';
};

const handleAddService = (newService) => {
  services.value.unshift(newService);
};

// Computed state
const throughput = computed(() => (velocity.value * 482).toLocaleString());
const memoryUtilization = computed(() => Math.min(96, Math.round(32 + velocity.value * 3.2)));
</script>

<template>
  <div class="container">
    <!-- Header -->
    <header class="app-header">
      <div class="logo-group">
        <div style="font-size: 2rem;">💚</div>
        <div>
          <div style="display: flex; align-items: center; gap: 0.5rem;">
            <h1 class="app-title">Vue 3 UI Studio</h1>
            <span class="framework-badge">Vue 3 / Composition API</span>
          </div>
          <p class="app-subtitle">
            Single-File Components, reactive proxies (ref & computed), and direct template bindings.
          </p>
        </div>
      </div>

      <ThemeToggle :theme="theme" @toggle="toggleTheme" />
    </header>

    <!-- Metrics Grid -->
    <section class="metrics-grid">
      <MetricCard
        label="Cluster Throughput"
        :value="`${throughput} req/s`"
        growth="+18.4%"
        growthType="pos"
        icon="⚡"
        iconBg="rgba(56, 189, 248, 0.2)"
        :progressPercent="velocity * 5"
      />
      <MetricCard
        label="Memory Allocation"
        :value="`${memoryUtilization}%`"
        :growth="gpuAcceleration ? 'GPU Offload' : 'CPU Only'"
        growthType="neutral"
        icon="🧠"
        iconBg="rgba(168, 85, 247, 0.2)"
        :progressPercent="memoryUtilization"
      />
      <MetricCard
        label="Active Nodes"
        :value="services.length"
        growth="+2 Nodes"
        growthType="pos"
        icon="🌐"
        iconBg="rgba(16, 185, 129, 0.2)"
        :progressPercent="Math.min(100, services.length * 15)"
      />
      <MetricCard
        label="Average Latency"
        :value="gpuAcceleration ? '14.2 ms' : '28.6 ms'"
        :growth="gpuAcceleration ? '-50% Latency' : 'Standard'"
        growthType="pos"
        icon="⏱️"
        iconBg="rgba(245, 158, 11, 0.2)"
      />
    </section>

    <!-- Main Dashboard Columns -->
    <div class="dashboard-columns">
      <InteractiveControls
        v-model:velocity="velocity"
        v-model:activeCategory="activeCategory"
        :categories="['All', 'Compute', 'Storage', 'Network']"
        :gpuAcceleration="gpuAcceleration"
        @toggleGpu="gpuAcceleration = !gpuAcceleration"
      />

      <DataList
        :items="services"
        v-model:searchTerm="searchTerm"
        :activeCategory="activeCategory"
        @openModal="isModalOpen = true"
      />
    </div>

    <!-- Educational Framework Note -->
    <div class="info-box">
      💡 <strong>Vue 3 Mental Model (JavaScript)</strong>: Uses JavaScript ES6 Proxies for transparent reactivity.
      When <code>ref.value</code> changes, only the specific DOM nodes tied to that property re-evaluate via compiler-optimized dynamic flags.
      Single File Components (<code>.vue</code>) cleanly bundle template, script, and style without TypeScript compiler setup.
    </div>

    <!-- Service Modal -->
    <ModalDialog
      :isOpen="isModalOpen"
      @close="isModalOpen = false"
      @addService="handleAddService"
    />
  </div>
</template>
