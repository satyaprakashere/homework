import { Show } from 'solid-js';

/**
 * Pure JavaScript SolidJS Component: MetricCard
 */
export function MetricCard(props) {
  return (
    <div className="glass-panel metric-card">
      <div className="metric-card-top">
        <span className="metric-label">{props.label}</span>
        <div
          className="metric-icon-box"
          style={{
            background: props.iconBg,
            'box-shadow': `0 0 16px ${props.iconBg}66`,
          }}
        >
          {props.icon}
        </div>
      </div>

      <div className="metric-value">{props.value}</div>

      <div className="metric-footer">
        <span
          className={
            props.growthType === 'pos'
              ? 'badge-growth-pos'
              : 'badge-growth-neutral'
          }
        >
          {props.growth}
        </span>
        <span style={{ color: 'var(--text-muted)' }}>vs previous period</span>
      </div>

      <Show when={props.progressPercent !== undefined}>
        <div
          className="progress-bar-track"
          title={`Capacity: ${props.progressPercent}%`}
        >
          <div
            className="progress-bar-fill"
            style={{
              width: `${Math.min(100, Math.max(0, props.progressPercent))}%`,
            }}
          />
        </div>
      </Show>
    </div>
  );
}
