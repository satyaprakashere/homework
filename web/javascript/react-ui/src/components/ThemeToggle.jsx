import React from 'react';

/**
 * Pure JavaScript ThemeToggle Component
 * @param {{ theme: 'dark' | 'light', onToggle: () => void }} props
 */
export function ThemeToggle({ theme, onToggle }) {
  return (
    <button
      onClick={onToggle}
      className="btn btn-secondary"
      aria-label="Toggle visual theme"
      title={`Switch to ${theme === 'dark' ? 'Light' : 'Dark'} mode`}
      style={{
        display: 'inline-flex',
        alignItems: 'center',
        gap: '0.5rem',
        padding: '0.5rem 0.9rem',
      }}
    >
      <span>{theme === 'dark' ? '🌙 Dark Mode' : '☀️ Light Mode'}</span>
    </button>
  );
}
