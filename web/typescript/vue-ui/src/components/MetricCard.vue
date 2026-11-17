<script setup lang="ts">
/**
 * Vue 3 Component: MetricCard
 * Demonstrates: Typed props with defaults, computed styles, and conditional rendering (v-if).
 */
defineProps<{
  label: string;
  value: string | number;
  growth: string;
  growthType: 'pos' | 'neutral';
  icon: string;
  iconBg: string;
  progressPercent?: number;
}>();
</script>

<template>
  <div class="glass-panel metric-card">
    <div class="metric-card-top">
      <span class="metric-label">{{ label }}</span>
      <div
        class="metric-icon-box"
        :style="{
          background: iconBg,
          boxShadow: `0 0 16px ${iconBg}66`,
        }"
      >
        {{ icon }}
      </div>
    </div>

    <div class="metric-value">{{ value }}</div>

    <div class="metric-footer">
      <span :class="growthType === 'pos' ? 'badge-growth-pos' : 'badge-growth-neutral'">
        {{ growth }}
      </span>
      <span style="color: var(--text-muted);">vs previous period</span>
    </div>

    <div
      v-if="progressPercent !== undefined"
      class="progress-bar-track"
      :title="`Capacity: ${progressPercent}%`"
    >
      <div
        class="progress-bar-fill"
        :style="{ width: `${Math.min(100, Math.max(0, progressPercent))}%` }"
      />
    </div>
  </div>
</template>
