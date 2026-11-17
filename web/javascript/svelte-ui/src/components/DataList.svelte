<script>
  // Svelte 5 Runes in Pure JavaScript
  let {
    items,
    searchTerm = $bindable(),
    activeCategory,
    onOpenModal,
  } = $props();

  // Svelte 5 $derived Rune: automatic reactive calculation
  let filteredItems = $derived(
    items.filter((item) => {
      const matchesSearch = item.name
        .toLowerCase()
        .includes(searchTerm.toLowerCase());
      const matchesCategory =
        activeCategory === 'All' || item.category === activeCategory;
      return matchesSearch && matchesCategory;
    })
  );
</script>

<div class="glass-panel">
  <div
    style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 1rem;"
  >
    <h3 class="panel-heading" style="margin: 0;">
      📊 Data Services ({filteredItems.length})
    </h3>
    <button
      onclick={onOpenModal}
      class="btn btn-primary"
      style="padding: 0.4rem 0.8rem; font-size: 0.8rem;"
    >
      + Add Service
    </button>
  </div>

  <input
    type="text"
    class="search-input"
    placeholder="Filter services by name..."
    bind:value={searchTerm}
  />

  <div class="data-list">
    {#if filteredItems.length === 0}
      <div
        style="text-align: center; padding: 2rem; color: var(--text-muted);"
      >
        No services match "{searchTerm}" in category "{activeCategory}"
      </div>
    {:else}
      {#each filteredItems as item (item.id)}
        <div class="data-item">
          <div>
            <div style="font-weight: 600; font-size: 0.9rem;">
              {item.name}
            </div>
            <div
              style="font-size: 0.75rem; color: var(--text-muted); font-family: var(--font-mono);"
            >
              {item.category} • Latency: {item.latency}ms
            </div>
          </div>
          <span
            class="status-badge {item.status === 'active' ? 'status-active' : 'status-standby'}"
          >
            {item.status}
          </span>
        </div>
      {/each}
    {/if}
  </div>
</div>
