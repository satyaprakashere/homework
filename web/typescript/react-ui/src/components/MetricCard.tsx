import React from 'react';

interface MetricCardProps {
  label: string;
  value: string | number;
  growth: string;
  growthType: 'pos' | 'neutral';
  icon: string;
  iconBg: string;
  progressPercent?: number;
}

/**
 * React UI Component: MetricCard
 * Demonstrates: Component composition, optional props, dynamic style calculation, glassmorphism design.
 */
export const MetricCard: React.FC<MetricCardProps> = ({
  label,
  value,
  growth,
  growthType,
  icon,
  iconBg,
  progressPercent,
}) => {
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
};
