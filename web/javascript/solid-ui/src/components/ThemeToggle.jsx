/**
 * Pure JavaScript SolidJS Component: ThemeToggle
 */
export function ThemeToggle(props) {
  return (
    <button
      onClick={() => props.onToggle()}
      className="btn btn-secondary"
      aria-label="Toggle visual theme"
      title={`Switch to ${props.theme() === 'dark' ? 'Light' : 'Dark'} mode`}
      style={{
        display: 'inline-flex',
        'align-items': 'center',
        gap: '0.5rem',
        padding: '0.5rem 0.9rem',
      }}
    >
      <span>{props.theme() === 'dark' ? '🌙 Dark Mode' : '☀️ Light Mode'}</span>
    </button>
  );
}
