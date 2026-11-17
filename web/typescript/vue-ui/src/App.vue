<script setup lang="ts">
import { ref, computed, watchEffect } from 'vue';
import ThemeToggle from './components/ThemeToggle.vue';
import MetricCard from './components/MetricCard.vue';
import InteractiveControls from './components/InteractiveControls.vue';
import ModalDialog from './components/ModalDialog.vue';

// Reactive State using ref()
const theme = ref<'dark' | 'light'>('dark');
const velocity = ref<number>(65);
const activeCategory = ref<string>('Overview');
const gpuAcceleration = ref<boolean>(true);
const isModalOpen = ref<boolean>(false);
const interactionCount = ref<number>(0);

const categories = ['Overview', 'Telemetry', 'Memory Pool', 'Render Pipeline'];

// Side Effect: Synchronize theme on documentElement
watchEffect(() => {
  document.documentElement.setAttribute('data-theme', theme.value);
});

// Computed State using computed()
const throughput = computed(() => {
  const base = velocity.value * 142;
  return gpuAcceleration.value ? Math.round(base * 1.85) : base;
});

const efficiencyScore = computed(() => {
  return Math.min(100, Math.round((velocity.value / 200) * 80 + (gpuAcceleration.value ? 20 : 5)));
});

const toggleTheme = () => {
  theme.value = theme.value === 'dark' ? 'light' : 'dark';
  interactionCount.value++;
};

const handleVelocity = (val: number) => {
  velocity.value = val;
  interactionCount.value++;
};

const handleCategory = (cat: string) => {
  activeCategory.value = cat;
  interactionCount.value++;
};

const toggleGpu = () => {
  gpuAcceleration.value = !gpuAcceleration.value;
  interactionCount.value++;
};

const resetDefaults = () => {
  velocity.value = 100;
  gpuAcceleration.value = true;
  interactionCount.value++;
};

const boostMax = () => {
  velocity.value = 200;
  interactionCount.value++;
};
</script>

<template>
  <div class="app-container">
    <!-- Header -->
    <header class="app-header">
      <div class="brand-wrapper">
        <div class="framework-badge">
          🟢 Vue 3 Composition API
        </div>
        <div>
          <h1 class="header-title">UI Design & Reactivity Studio</h1>
          <p class="header-subtitle">
            Learn Vue 3 Single-File Components, reactive proxies, and template directives
          </p>
        </div>
      </div>
      <ThemeToggle :theme="theme" @toggle="toggleTheme" />
    </header>

    <!-- Metrics Row -->
    <section class="grid-metrics">
      <MetricCard
        label="Throughput"
        :value="`${throughput.toLocaleString()} ops`"
        growth="+18.4%"
        growthType="pos"
        icon="⚡"
        iconBg="rgba(66, 184, 131, 0.2)"
        :progressPercent="efficiencyScore"
      />
      <MetricCard
        label="Engine Velocity"
        :value="`${velocity} fps`"
        :growth="velocity > 100 ? '+32.1%' : '-4.2%'"
        :growthType="velocity > 100 ? 'pos' : 'neutral'"
        icon="🚀"
        iconBg="rgba(168, 85, 247, 0.2)"
        :progressPercent="Math.round((velocity / 200) * 100)"
      />
      <MetricCard
        label="Active Mode"
        :value="gpuAcceleration ? 'Hardware GPU' : 'Software'"
        :growth="gpuAcceleration ? 'Ultra Latency' : 'Fallback'"
        :growthType="gpuAcceleration ? 'pos' : 'neutral'"
        icon="💎"
        iconBg="rgba(16, 185, 129, 0.2)"
      />
      <MetricCard
        label="Total Interactions"
        :value="interactionCount"
        growth="Live Clicks"
        growthType="neutral"
        icon="🎯"
        iconBg="rgba(245, 158, 11, 0.2)"
      />
    </section>

    <!-- Studio Two-Column Layout -->
    <div class="studio-layout">
      <!-- Left Column: Interactive Controls -->
      <InteractiveControls
        :velocity="velocity"
        :activeCategory="activeCategory"
        :categories="categories"
        :gpuAcceleration="gpuAcceleration"
        @update:velocity="handleVelocity"
        @update:activeCategory="handleCategory"
        @toggleGpu="toggleGpu"
      />

      <!-- Right Column: Live State Inspector -->
      <div class="glass-panel">
        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 1.25rem;">
          <h3 class="panel-heading" style="margin-bottom: 0;">🔬 Vue Proxy Inspector</h3>
          <button class="btn btn-primary" @click="isModalOpen = true">
            Open Modal Dialog
          </button>
        </div>

        <p style="color: var(--text-secondary); font-size: 0.875rem; margin-bottom: 1rem;">
          Vue tracks reactive dependencies automatically using JavaScript Proxies. When <code>velocity.value</code> changes, only the exact DOM interpolations bound to it are patched:
        </p>

        <pre class="state-inspector">
{{
  JSON.stringify(
    {
      framework: 'Vue 3 (Composition API)',
      theme,
      activeCategory,
      velocity,
      gpuAcceleration,
      derivedStats: {
        throughput,
        efficiencyScore: `${efficiencyScore}%`,
      },
      totalInteractions: interactionCount,
    },
    null,
    2
  )
}}
        </pre>

        <div style="margin-top: 1.25rem; display: flex; gap: 0.75rem;">
          <button class="btn btn-secondary" @click="resetDefaults">
            Reset to Defaults
          </button>
          <button class="btn btn-secondary" @click="boostMax">
            Boost to Max
          </button>
        </div>
      </div>
    </div>

    <!-- Educational Callout -->
    <div class="learning-callout">
      <h4>💡 Vue 3 Architectural Concept: Reactive Proxies & Compiler Flags</h4>
      <p>
        Unlike React, Vue does not re-run the entire component function on state changes. Instead, <code>ref()</code> wraps values in a JavaScript Proxy. Vue's template compiler analyzes template bindings at build-time, tagging dynamic elements with bitwise Patch Flags. At runtime, Vue only updates the exact DOM nodes that depend on the mutated ref.
      </p>
    </div>

    <!-- Modal Dialog -->
    <ModalDialog
      :isOpen="isModalOpen"
      title="Vue 3 Modal Architecture"
      @close="isModalOpen = false"
    >
      <p style="line-height: 1.6; margin-bottom: 0.75rem;">
        This modal demonstrates how Vue manages overlays cleanly with <code>v-if</code> and slot transclusion (<code>&lt;slot /&gt;</code>).
      </p>
      <p style="line-height: 1.6;">
        It also binds lifecycle listeners using <code>onMounted</code> and <code>onUnmounted</code> to catch the <kbd style="padding: 2px 6px; background: var(--surface-inset); border-radius: 4px;">Escape</kbd> key!
      </p>
    </ModalDialog>
  </div>
</template>
