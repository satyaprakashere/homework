<script>
  // Svelte 5 Runes in Pure JavaScript
  let {
    velocity = $bindable(),
    activeCategory = $bindable(),
    categories,
    gpuAcceleration = $bindable(),
    onToggleGpu,
  } = $props();
</script>

<div class="glass-panel">
  <h3 class="panel-heading">🎛️ Interactive Controls (Svelte 5 Runes)</h3>

  <!-- Segmented Pill Tabs -->
  <div class="control-group">
    <div class="control-label">
      <span>Active Viewport</span>
      <span class="control-hint">$bindable / Runes</span>
    </div>
    <div class="segmented-nav" role="tablist">
      {#each categories as cat}
        <button
          role="tab"
          aria-selected={activeCategory === cat}
          class="segmented-button {activeCategory === cat ? 'active' : ''}"
          onclick={() => activeCategory = cat}
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
      <span style="color: var(--accent-cyan); font-family: var(--font-mono);">
        {velocity}x
      </span>
    </div>
    <input
      type="range"
      min="1"
      max="20"
      bind:value={velocity}
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
        bind:checked={gpuAcceleration}
        onchange={onToggleGpu}
      />
      <span class="slider"></span>
    </label>
  </div>
</div>
