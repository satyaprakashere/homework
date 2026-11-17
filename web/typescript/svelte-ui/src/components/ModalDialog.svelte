<script lang="ts">
import type { Snippet } from 'svelte';

/**
 * Svelte 5 Component: ModalDialog
 * Demonstrates: Svelte 5 Snippets {@render children?.()}, window event bindings, and $effect.
 */
interface Props {
  isOpen: boolean;
  title: string;
  onclose: () => void;
  children?: Snippet;
}

let { isOpen, title, onclose, children }: Props = $props();

const handleKeyDown = (e: KeyboardEvent) => {
  if (e.key === 'Escape' && isOpen) {
    onclose();
  }
};
</script>

<svelte:window onkeydown={handleKeyDown} />

{#if isOpen}
  <div
    class="modal-overlay"
    onclick={(e) => {
      if (e.target === e.currentTarget) onclose();
    }}
    onkeydown={(e) => {
      if (e.key === 'Escape') onclose();
    }}
    role="presentation"
    tabindex="-1"
  >
    <div class="modal-content">
      <div class="modal-header">
        <h3 style="font-size: 1.25rem; font-weight: 700;">{title}</h3>
        <button
          class="modal-close"
          onclick={onclose}
          aria-label="Close modal"
        >
          ✕
        </button>
      </div>

      <div style="margin-bottom: 1.5rem; color: var(--text-secondary);">
        {#if children}
          {@render children()}
        {/if}
      </div>

      <div style="display: flex; justify-content: flex-end; gap: 0.75rem;">
        <button class="btn btn-secondary" onclick={onclose}>
          Dismiss
        </button>
        <button class="btn btn-primary" onclick={onclose}>
          Confirm Action
        </button>
      </div>
    </div>
  </div>
{/if}
