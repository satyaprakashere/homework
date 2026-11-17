import React from 'react';

/**
 * Pure JavaScript InteractiveControls Component
 * Demonstrates: Controlled inputs, state lift-up, array mapping, and event handling.
 */
export function InteractiveControls({
  velocity,
  onVelocityChange,
  activeCategory,
  categories,
  onCategoryChange,
  gpuAcceleration,
  onGpuToggle,
}) {
  return (
    <div className="glass-panel">
      <h3 className="panel-heading">🎛️ Interactive Controls (React JS)</h3>

      {/* Segmented Pill Tabs */}
      <div className="control-group">
        <div className="control-label">
          <span>Active Viewport</span>
          <span className="control-hint">Tab Selection</span>
        </div>
        <div className="segmented-nav" role="tablist">
          {categories.map((cat) => (
            <button
              key={cat}
              role="tab"
              aria-selected={activeCategory === cat}
              className={`segmented-button ${
                activeCategory === cat ? 'active' : ''
              }`}
              onClick={() => onCategoryChange(cat)}
            >
              {cat}
            </button>
          ))}
        </div>
      </div>

      {/* Range Slider */}
      <div className="control-group">
        <div className="control-label">
          <span>Processing Velocity</span>
          <span style={{ color: 'var(--accent-cyan)', fontFamily: 'var(--font-mono)' }}>
            {velocity}x
          </span>
        </div>
        <input
          type="range"
          min="1"
          max="20"
          value={velocity}
          onChange={(e) => onVelocityChange(Number(e.target.value))}
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
            checked={gpuAcceleration}
            onChange={onGpuToggle}
          />
          <span className="slider"></span>
        </label>
      </div>
    </div>
  );
}
