import { Component, For } from 'solid-js';

interface InteractiveControlsProps {
  velocity: number;
  onVelocityChange: (val: number) => void;
  activeCategory: string;
  categories: string[];
  onCategoryChange: (cat: string) => void;
  gpuAcceleration: boolean;
  onGpuToggle: () => void;
}

/**
 * SolidJS UI Component: InteractiveControls
 * Demonstrates: <For> keyed loops (zero DOM recreation) and signal updates.
 */
export const InteractiveControls: Component<InteractiveControlsProps> = (props) => {
  return (
    <div class="glass-panel">
      <h3 class="panel-heading">🎛️ Interactive Controls</h3>

      {/* Segmented Pill Tabs */}
      <div class="control-group">
        <div class="control-label">
          <span>Active Viewport</span>
          <span class="control-hint">Tab Selection (&lt;For&gt;)</span>
        </div>
        <div class="segmented-nav" role="tablist">
          <For each={props.categories}>
            {(cat) => (
              <button
                role="tab"
                aria-selected={props.activeCategory === cat}
                class={`segmented-button ${
                  props.activeCategory === cat ? 'active' : ''
                }`}
                onClick={() => props.onCategoryChange(cat)}
              >
                {cat}
              </button>
            )}
          </For>
        </div>
      </div>

      {/* Range Slider */}
      <div class="control-group">
        <div class="control-label">
          <span>Processing Velocity</span>
          <span style={{ color: 'var(--accent-brand)', 'font-family': 'var(--font-mono)' }}>
            {props.velocity} ops/sec
          </span>
        </div>
        <input
          type="range"
          min="10"
          max="200"
          step="5"
          value={props.velocity}
          onInput={(e) => props.onVelocityChange(Number(e.currentTarget.value))}
        />
        <div
          style={{
            display: 'flex',
            'justify-content': 'space-between',
            'font-size': '0.75rem',
            color: 'var(--text-muted)',
            'margin-top': '0.35rem',
          }}
        >
          <span>Low Power (10)</span>
          <span>Max Speed (200)</span>
        </div>
      </div>

      {/* Switch Toggle */}
      <div class="control-group" style={{ 'margin-bottom': 0 }}>
        <div class="switch-wrapper" onClick={props.onGpuToggle}>
          <div>
            <div style={{ 'font-weight': 600, 'font-size': '0.9rem' }}>
              Hardware GPU Acceleration
            </div>
            <div class="control-hint">
              {props.gpuAcceleration ? 'Active (WebGL / WebGPU)' : 'Software Rasterizer'}
            </div>
          </div>
          <div class={`switch ${props.gpuAcceleration ? 'on' : ''}`}>
            <div class="switch-dot" />
          </div>
        </div>
      </div>
    </div>
  );
};
