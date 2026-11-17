import React from 'react';

/**
 * Pure JavaScript DataList Component
 * Demonstrates: Search input binding, array filtering, conditional rendering, micro-animations.
 */
export function DataList({
  items,
  searchTerm,
  onSearchChange,
  activeCategory,
  onOpenModal,
}) {
  const filteredItems = items.filter((item) => {
    const matchesSearch = item.name
      .toLowerCase()
      .includes(searchTerm.toLowerCase());
    const matchesCategory =
      activeCategory === 'All' || item.category === activeCategory;
    return matchesSearch && matchesCategory;
  });

  return (
    <div className="glass-panel">
      <div
        style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          marginBottom: '1rem',
        }}
      >
        <h3 className="panel-heading" style={{ margin: 0 }}>
          📊 Data Services ({filteredItems.length})
        </h3>
        <button onClick={onOpenModal} className="btn btn-primary" style={{ padding: '0.4rem 0.8rem', fontSize: '0.8rem' }}>
          + Add Service
        </button>
      </div>

      <input
        type="text"
        className="search-input"
        placeholder="Filter services by name..."
        value={searchTerm}
        onChange={(e) => onSearchChange(e.target.value)}
      />

      <div className="data-list">
        {filteredItems.length === 0 ? (
          <div style={{ textAlign: 'center', padding: '2rem', color: 'var(--text-muted)' }}>
            No services match "{searchTerm}" in category "{activeCategory}"
          </div>
        ) : (
          filteredItems.map((item) => (
            <div key={item.id} className="data-item">
              <div>
                <div style={{ fontWeight: 600, fontSize: '0.9rem' }}>
                  {item.name}
                </div>
                <div
                  style={{
                    fontSize: '0.75rem',
                    color: 'var(--text-muted)',
                    fontFamily: 'var(--font-mono)',
                  }}
                >
                  {item.category} • Latency: {item.latency}ms
                </div>
              </div>
              <span
                className={`status-badge ${
                  item.status === 'active' ? 'status-active' : 'status-standby'
                }`}
              >
                {item.status}
              </span>
            </div>
          ))
        )}
      </div>
    </div>
  );
}
