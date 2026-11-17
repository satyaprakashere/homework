<script lang="ts">
/**
 * Svelte 5 Component: InteractiveControls
 * Demonstrates: {#each} iteration, $props() callbacks, and two-way bind:value slider.
 */
interface Props {
  velocity: number;
  activeCategory: string;
  categories: string[];
  gpuAcceleration: boolean;
  onvelocitychange: (val: number) => void;
  oncategorychange: (cat: string) => void;
  ontogglegpu: () => void;
}

let {
  velocity,
  activeCategory,
  categories,
  gpuAcceleration,
  onvelocitychange,
  oncategorychange,
  ontogglegpu,
}: Props = $props();
</script>

<div class="glass-panel">
  <h3 class="panel-heading">🎛️ Interactive Controls</h3>

  <!-- Segmented Pill Tabs -->
  <div class="control-group">
    <div class="control-label">
      <span>Active Viewport</span>
      <span class="control-hint">Tab Selection ({'#each'})</span>
    </div>
    <div class="segmented-nav" role="tablist">
      {#each categories as cat (cat)}
        <button
          role="tab"
          aria-selected={activeCategory === cat}
          class="segmented-button"
          class:active={activeCategory === cat}
          onclick={() => oncategorychange(cat)}
        >
          {cat}
        </button>
      {/each}
    </div>
  </div>

  <!-- Range Slider -->
  <div class="control-group">
    <div class="control-label">
      <span>Processing Velocity</span>
      <span style="color: var(--accent-brand); font-family: var(--font-mono);">
        {velocity} ops/sec
      </span>
    </div>
    <input
      type="range"
      min="10"
      max="200"
      step="5"
      value={velocity}
      oninput={(e) => onvelocitychange(Number((e.target as HTMLInputElement).value))}
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
    <div
      class="switch-wrapper"
      onclick={ontogglegpu}
      onkeydown={(e) => { if (e.key === 'Enter' || e.key === ' ') ontogglegpu(); }}
      role="button"
      tabindex="0"
    >
      <div>
        <div style="font-weight: 600; font-size: 0.9rem;">
          Hardware GPU Acceleration
        </div>
        <div class="control-hint">
          {gpuAcceleration ? 'Active (WebGL / WebGPU)' : 'Software Rasterizer'}
        </div>
      </div>
      <div class="switch" class:on={gpuAcceleration}>
        <div class="switch-dot"></div>
      </div>
    </div>
  </div>
</div>
