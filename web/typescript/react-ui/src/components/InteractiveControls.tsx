import React from 'react';

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
 * React UI Component: InteractiveControls
 * Demonstrates: Controlled inputs, state lift-up, event dispatching, and segmented tab selection.
 */
export const InteractiveControls: React.FC<InteractiveControlsProps> = ({
  velocity,
  onVelocityChange,
  activeCategory,
  categories,
  onCategoryChange,
  gpuAcceleration,
  onGpuToggle,
}) => {
  return (
    <div className="glass-panel">
      <h3 className="panel-heading">🎛️ Interactive Controls</h3>

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
            {velocity} ops/sec
          </span>
        </div>
        <input
          type="range"
          min="10"
          max="200"
          step="5"
          value={velocity}
          onChange={(e) => onVelocityChange(Number(e.target.value))}
        />
        <div
          style={{
            display: 'flex',
            justifyContent: 'space-between',
            fontSize: '0.75rem',
            color: 'var(--text-muted)',
            marginTop: '0.35rem',
          }}
        >
          <span>Low Power (10)</span>
          <span>Max Speed (200)</span>
        </div>
      </div>

      {/* Switch Toggle */}
      <div className="control-group" style={{ marginBottom: 0 }}>
        <div className="switch-wrapper" onClick={onGpuToggle}>
          <div>
            <div style={{ fontWeight: 600, fontSize: '0.9rem' }}>
              Hardware GPU Acceleration
            </div>
            <div className="control-hint">
              {gpuAcceleration ? 'Active (WebGL / WebGPU)' : 'Software Rasterizer'}
            </div>
          </div>
          <div className={`switch ${gpuAcceleration ? 'on' : ''}`}>
            <div className="switch-dot" />
          </div>
        </div>
      </div>
    </div>
  );
};
