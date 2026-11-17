<script lang="ts">
/**
 * Svelte 5 Component: MetricCard
 * Demonstrates: $props() typing, dynamic classes, and {#if} blocks.
 */
interface Props {
  label: string;
  value: string | number;
  growth: string;
  growthType: 'pos' | 'neutral';
  icon: string;
  iconBg: string;
  progressPercent?: number;
}

let {
  label,
  value,
  growth,
  growthType,
  icon,
  iconBg,
  progressPercent,
}: Props = $props();
</script>

<div class="glass-panel metric-card">
  <div class="metric-card-top">
    <span class="metric-label">{label}</span>
    <div
      class="metric-icon-box"
      style:background={iconBg}
      style:box-shadow={`0 0 16px ${iconBg}66`}
    >
      {icon}
    </div>
  </div>

  <div class="metric-value">{value}</div>

  <div class="metric-footer">
    <span class={growthType === 'pos' ? 'badge-growth-pos' : 'badge-growth-neutral'}>
      {growth}
    </span>
    <span style="color: var(--text-muted);">vs previous period</span>
  </div>

  {#if progressPercent !== undefined}
    <div class="progress-bar-track" title={`Capacity: ${progressPercent}%`}>
      <div
        class="progress-bar-fill"
        style:width={`${Math.min(100, Math.max(0, progressPercent))}%`}
      ></div>
    </div>
  {/if}
</div>
