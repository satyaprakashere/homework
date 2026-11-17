<script>
  // Svelte 5 Runes in Pure JavaScript
  let { isOpen, onClose, onAddService } = $props();

  let name = $state('');
  let category = $state('Compute');

  function handleSubmit(e) {
    e.preventDefault();
    if (!name.trim()) return;
    onAddService({
      id: Date.now(),
      name: name.trim(),
      category,
      latency: Math.floor(Math.random() * 40) + 5,
      status: 'active',
    });
    name = '';
    onClose();
  }
</script>

{#if isOpen}
  <div class="modal-overlay" onclick={onClose} role="presentation">
    <!-- svelte-ignore a11y_click_events_have_key_events -->
    <div class="modal-content" onclick={(e) => e.stopPropagation()} role="dialog" aria-modal="true" tabindex="-1">
      <h3 class="panel-heading" style="margin-bottom: 1rem;">
        ✨ Register New Service
      </h3>
      <p style="font-size: 0.85rem; color: var(--text-secondary); margin-bottom: 1.5rem;">
        Provide cluster service parameters to instantiate a reactive data pipeline.
      </p>

      <form onsubmit={handleSubmit}>
        <div class="control-group">
          <label class="control-label" for="service-name">Service Name</label>
          <input
            id="service-name"
            type="text"
            class="search-input"
            placeholder="e.g. auth-gateway-v2"
            bind:value={name}
            required
          />
        </div>

        <div class="control-group">
          <label class="control-label" for="service-category">Service Layer</label>
          <select id="service-category" class="search-input" bind:value={category}>
            <option value="Compute">Compute</option>
            <option value="Storage">Storage</option>
            <option value="Network">Network</option>
          </select>
        </div>

        <div
          style="display: flex; justify-content: flex-end; gap: 0.75rem; margin-top: 1.5rem;"
        >
          <button type="button" onclick={onClose} class="btn btn-secondary">
            Cancel
          </button>
          <button type="submit" class="btn btn-primary">
            Deploy Service
          </button>
        </div>
      </form>
    </div>
  </div>
{/if}
