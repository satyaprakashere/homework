<script setup lang="ts">
/**
 * Vue 3 Component: InteractiveControls
 * Demonstrates: v-for list rendering, dynamic classes :class, event emitting.
 */
defineProps<{
  velocity: number;
  activeCategory: string;
  categories: string[];
  gpuAcceleration: boolean;
}>();

const emit = defineEmits<{
  (e: 'update:velocity', val: number): void;
  (e: 'update:activeCategory', cat: string): void;
  (e: 'toggleGpu'): void;
}>();
</script>

<template>
  <div class="glass-panel">
    <h3 class="panel-heading">🎛️ Interactive Controls</h3>

    <!-- Segmented Pill Tabs -->
    <div class="control-group">
      <div class="control-label">
        <span>Active Viewport</span>
        <span class="control-hint">Tab Selection (v-for)</span>
      </div>
      <div class="segmented-nav" role="tablist">
        <button
          v-for="cat in categories"
          :key="cat"
          role="tab"
          :aria-selected="activeCategory === cat"
          class="segmented-button"
          :class="{ active: activeCategory === cat }"
          @click="emit('update:activeCategory', cat)"
        >
          {{ cat }}
        </button>
      </div>
    </div>

    <!-- Range Slider -->
    <div class="control-group">
      <div class="control-label">
        <span>Processing Velocity</span>
        <span style="color: var(--accent-brand); font-family: var(--font-mono);">
          {{ velocity }} ops/sec
        </span>
      </div>
      <input
        type="range"
        min="10"
        max="200"
        step="5"
        :value="velocity"
        @input="emit('update:velocity', Number(($event.target as HTMLInputElement).value))"
      />
      <div
        style="display: flex; justify-content: space-between; font-size: 0.75rem; color: var(--text-muted); margin-top: 0.35rem;"
      >
        <span>Low Power (10)</span>
        <span>Max Speed (200)</span>
      </div>
    </div>

    <!-- Switch Toggle -->
    <div class="control-group" style="margin-bottom: 0;">
      <div class="switch-wrapper" @click="emit('toggleGpu')">
        <div>
          <div style="font-weight: 600; font-size: 0.9rem;">
            Hardware GPU Acceleration
          </div>
          <div class="control-hint">
            {{ gpuAcceleration ? 'Active (WebGL / WebGPU)' : 'Software Rasterizer' }}
          </div>
        </div>
        <div class="switch" :class="{ on: gpuAcceleration }">
          <div class="switch-dot" />
        </div>
      </div>
    </div>
  </div>
</template>
