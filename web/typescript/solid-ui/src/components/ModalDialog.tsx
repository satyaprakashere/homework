import { Component, JSX, Show, onMount, onCleanup } from 'solid-js';

interface ModalDialogProps {
  isOpen: boolean;
  onClose: () => void;
  title: string;
  children: JSX.Element;
}

/**
 * SolidJS UI Component: ModalDialog
 * Demonstrates: Solid lifecycle hooks (onMount, onCleanup) and <Show> element gating.
 */
export const ModalDialog: Component<ModalDialogProps> = (props) => {
  const handleKeyDown = (e: KeyboardEvent) => {
    if (e.key === 'Escape' && props.isOpen) {
      props.onClose();
    }
  };

  onMount(() => {
    window.addEventListener('keydown', handleKeyDown);
  });

  onCleanup(() => {
    window.removeEventListener('keydown', handleKeyDown);
  });

  return (
    <Show when={props.isOpen}>
      <div
        class="modal-overlay"
        onClick={(e) => {
          if (e.target === e.currentTarget) props.onClose();
        }}
        role="dialog"
        aria-modal="true"
      >
        <div class="modal-content">
          <div class="modal-header">
            <h3 style={{ 'font-size': '1.25rem', 'font-weight': 700 }}>{props.title}</h3>
            <button
              class="modal-close"
              onClick={props.onClose}
              aria-label="Close modal"
            >
              ✕
            </button>
          </div>

          <div style={{ 'margin-bottom': '1.5rem', color: 'var(--text-secondary)' }}>
            {props.children}
          </div>

          <div style={{ display: 'flex', 'justify-content': 'flex-end', gap: '0.75rem' }}>
            <button class="btn btn-secondary" onClick={props.onClose}>
              Dismiss
            </button>
            <button class="btn btn-primary" onClick={props.onClose}>
              Confirm Action
            </button>
          </div>
        </div>
      </div>
    </Show>
  );
};
