import { Component } from 'solid-js';

interface ThemeToggleProps {
  theme: 'dark' | 'light';
  onToggle: () => void;
}

/**
 * SolidJS UI Component: ThemeToggle
 * Demonstrates: Solid Component typing, props access via props.theme (never destructure!), and event dispatching.
 */
export const ThemeToggle: Component<ThemeToggleProps> = (props) => {
  return (
    <button
      onClick={props.onToggle}
      class="btn btn-secondary"
      aria-label="Toggle visual theme"
      title={`Switch to ${props.theme === 'dark' ? 'Light' : 'Dark'} mode`}
      style={{
        display: 'inline-flex',
        'align-items': 'center',
        gap: '0.5rem',
        padding: '0.5rem 0.9rem',
        cursor: 'pointer',
      }}
    >
      <span>{props.theme === 'dark' ? '🌙 Dark Mode' : '☀️ Light Mode'}</span>
    </button>
  );
};
