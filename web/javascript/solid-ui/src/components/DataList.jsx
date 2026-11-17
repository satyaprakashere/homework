import { For, Show, createMemo } from 'solid-js';

/**
 * Pure JavaScript SolidJS Component: DataList
 */
export function DataList(props) {
  const filteredItems = createMemo(() => {
    return props.items().filter((item) => {
      const matchesSearch = item.name
        .toLowerCase()
        .includes(props.searchTerm().toLowerCase());
      const matchesCategory =
        props.activeCategory() === 'All' || item.category === props.activeCategory();
      return matchesSearch && matchesCategory;
    });
  });

  return (
    <div className="glass-panel">
      <div
        style={{
          display: 'flex',
          'justify-content': 'space-between',
          'align-items': 'center',
          'margin-bottom': '1rem',
        }}
      >
        <h3 className="panel-heading" style={{ margin: 0 }}>
          📊 Data Services ({filteredItems().length})
        </h3>
        <button
          onClick={() => props.onOpenModal()}
          className="btn btn-primary"
          style={{ padding: '0.4rem 0.8rem', 'font-size': '0.8rem' }}
        >
          + Add Service
        </button>
      </div>

      <input
        type="text"
        className="search-input"
        placeholder="Filter services by name..."
        value={props.searchTerm()}
        onInput={(e) => props.onSearchChange(e.target.value)}
      />

      <div className="data-list">
        <Show
          when={filteredItems().length > 0}
          fallback={
            <div style={{ 'text-align': 'center', padding: '2rem', color: 'var(--text-muted)' }}>
              No services match "{props.searchTerm()}" in category "{props.activeCategory()}"
            </div>
          }
        >
          <For each={filteredItems()}>
            {(item) => (
              <div className="data-item">
                <div>
                  <div style={{ 'font-weight': '600', 'font-size': '0.9rem' }}>
                    {item.name}
                  </div>
                  <div
                    style={{
                      'font-size': '0.75rem',
                      color: 'var(--text-muted)',
                      'font-family': 'var(--font-mono)',
                    }}
                  >
                    {item.category} • Latency: {item.latency}ms
                  </div>
                </div>
                <span
                  classList={{
                    'status-badge': true,
                    'status-active': item.status === 'active',
                    'status-standby': item.status !== 'active',
                  }}
                >
                  {item.status}
                </span>
              </div>
            )}
          </For>
        </Show>
      </div>
    </div>
  );
}
