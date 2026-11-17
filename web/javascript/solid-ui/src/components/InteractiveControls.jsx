import { For } from 'solid-js';

/**
 * Pure JavaScript SolidJS Component: InteractiveControls
 */
export function InteractiveControls(props) {
  return (
    <div className="glass-panel">
      <h3 className="panel-heading">🎛️ Interactive Controls (SolidJS Signals)</h3>

      {/* Segmented Pill Tabs */}
      <div className="control-group">
        <div className="control-label">
          <span>Active Viewport</span>
          <span className="control-hint">createSignal / Reactive JSX</span>
        </div>
        <div className="segmented-nav" role="tablist">
          <For each={props.categories}>
            {(cat) => (
              <button
                role="tab"
                aria-selected={props.activeCategory() === cat}
                classList={{
                  'segmented-button': true,
                  active: props.activeCategory() === cat,
                }}
                onClick={() => props.onCategoryChange(cat)}
              >
                {cat}
              </button>
            )}
          </For>
        </div>
      </div>

      {/* Range Slider */}
      <div className="control-group">
        <div className="control-label">
          <span>Processing Velocity</span>
          <span style={{ color: 'var(--accent-cyan)', 'font-family': 'var(--font-mono)' }}>
            {props.velocity()}x
          </span>
        </div>
        <input
          type="range"
          min="1"
          max="20"
          value={props.velocity()}
          onInput={(e) => props.onVelocityChange(Number(e.target.value))}
        />
      </div>

      {/* Hardware Switch */}
      <div className="switch-container">
        <div>
          <div className="switch-label-title">Hardware Acceleration</div>
          <div className="switch-label-desc">Render shaders on dedicated GPU</div>
        </div>
        <label className="switch">
          <input
            type="checkbox"
            checked={props.gpuAcceleration()}
            onChange={() => props.onGpuToggle()}
          />
          <span className="slider"></span>
        </label>
      </div>
    </div>
  );
}
