<script lang="ts">
/**
 * Svelte 5 Component: ThemeToggle
 * Demonstrates: Modern $props() rune and event callback.
 */
interface Props {
  theme: 'dark' | 'light';
  ontoggle: () => void;
}

let { theme, ontoggle }: Props = $props();
</script>

<button
  onclick={ontoggle}
  class="btn btn-secondary"
  aria-label="Toggle visual theme"
  title={`Switch to ${theme === 'dark' ? 'Light' : 'Dark'} mode`}
  style="display: inline-flex; align-items: center; gap: 0.5rem; padding: 0.5rem 0.9rem; cursor: pointer;"
>
  <span>{theme === 'dark' ? '🌙 Dark Mode' : '☀️ Light Mode'}</span>
</button>
