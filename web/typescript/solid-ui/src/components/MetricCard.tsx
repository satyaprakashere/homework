import { Component, Show } from 'solid-js';

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
 * SolidJS UI Component: MetricCard
 * Demonstrates: Solid's built-in <Show> control component and fine-grained style bindings.
 */
export const MetricCard: Component<MetricCardProps> = (props) => {
  return (
    <div class="glass-panel metric-card">
      <div class="metric-card-top">
        <span class="metric-label">{props.label}</span>
        <div
          class="metric-icon-box"
          style={{
            background: props.iconBg,
            'box-shadow': `0 0 16px ${props.iconBg}66`,
          }}
        >
          {props.icon}
        </div>
      </div>

      <div class="metric-value">{props.value}</div>

      <div class="metric-footer">
        <span
          class={
            props.growthType === 'pos' ? 'badge-growth-pos' : 'badge-growth-neutral'
          }
        >
          {props.growth}
        </span>
        <span style={{ color: 'var(--text-muted)' }}>vs previous period</span>
      </div>

      <Show when={props.progressPercent !== undefined}>
        <div
          class="progress-bar-track"
          title={`Capacity: ${props.progressPercent}%`}
        >
          <div
            class="progress-bar-fill"
            style={{
              width: `${Math.min(100, Math.max(0, props.progressPercent ?? 0))}%`,
            }}
          />
        </div>
      </Show>
    </div>
  );
};
