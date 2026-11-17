import React from 'react';

/**
 * Pure JavaScript MetricCard Component
 * Demonstrates component composition, props destructuring, dynamic inline styles, and conditional rendering.
 */
export function MetricCard({
  label,
  value,
  growth,
  growthType = 'pos',
  icon,
  iconBg,
  progressPercent,
}) {
  return (
    <div className="glass-panel metric-card">
      <div className="metric-card-top">
        <span className="metric-label">{label}</span>
        <div
          className="metric-icon-box"
          style={{
            background: iconBg,
            boxShadow: `0 0 16px ${iconBg}66`,
          }}
        >
          {icon}
        </div>
      </div>

      <div className="metric-value">{value}</div>

      <div className="metric-footer">
        <span
          className={
            growthType === 'pos' ? 'badge-growth-pos' : 'badge-growth-neutral'
          }
        >
          {growth}
        </span>
        <span style={{ color: 'var(--text-muted)' }}>vs previous period</span>
      </div>

      {progressPercent !== undefined && (
        <div className="progress-bar-track" title={`Capacity: ${progressPercent}%`}>
          <div
            className="progress-bar-fill"
            style={{ width: `${Math.min(100, Math.max(0, progressPercent))}%` }}
          />
        </div>
      )}
    </div>
  );
}
