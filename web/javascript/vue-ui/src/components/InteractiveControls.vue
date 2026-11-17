<script setup>
// Pure JavaScript Vue 3 Component
defineProps({
  velocity: { type: Number, required: true },
  activeCategory: { type: String, required: true },
  categories: { type: Array, required: true },
  gpuAcceleration: { type: Boolean, required: true },
});

defineEmits(['update:velocity', 'update:activeCategory', 'toggleGpu']);
</script>

<template>
  <div class="glass-panel">
    <h3 class="panel-heading">🎛️ Interactive Controls (Vue 3 JS)</h3>

    <!-- Segmented Pill Tabs -->
    <div class="control-group">
      <div class="control-label">
        <span>Active Viewport</span>
        <span class="control-hint">v-model / Emits</span>
      </div>
      <div class="segmented-nav" role="tablist">
        <button
          v-for="cat in categories"
          :key="cat"
          role="tab"
          :aria-selected="activeCategory === cat"
          :class="['segmented-button', { active: activeCategory === cat }]"
          @click="$emit('update:activeCategory', cat)"
        >
          {{ cat }}
        </button>
      </div>
    </div>

    <!-- Range Slider -->
    <div class="control-group">
      <div class="control-label">
        <span>Processing Velocity</span>
        <span style="color: var(--accent-cyan); font-family: var(--font-mono);">
          {{ velocity }}x
        </span>
      </div>
      <input
        type="range"
        min="1"
        max="20"
        :value="velocity"
        @input="$emit('update:velocity', Number($event.target.value))"
      />
    </div>

    <!-- Hardware Switch -->
    <div class="switch-container">
      <div>
        <div class="switch-label-title">Hardware Acceleration</div>
        <div class="switch-label-desc">Render shaders on dedicated GPU</div>
      </div>
      <label class="switch">
        <input
          type="checkbox"
          :checked="gpuAcceleration"
          @change="$emit('toggleGpu')"
        />
        <span class="slider"></span>
      </label>
    </div>
  </div>
</template>
