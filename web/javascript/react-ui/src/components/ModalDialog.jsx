import React, { useState } from 'react';

/**
 * Pure JavaScript ModalDialog Component
 * Demonstrates: Portals / overlay state, form handling, validation, keyboard/click outside dismissal.
 */
export function ModalDialog({ isOpen, onClose, onAddService }) {
  const [name, setName] = useState('');
  const [category, setCategory] = useState('Compute');

  if (!isOpen) return null;

  const handleSubmit = (e) => {
    e.preventDefault();
    if (!name.trim()) return;
    onAddService({
      id: Date.now(),
      name: name.trim(),
      category,
      latency: Math.floor(Math.random() * 40) + 5,
      status: 'active',
    });
    setName('');
    onClose();
  };

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal-content" onClick={(e) => e.stopPropagation()}>
        <h3 className="panel-heading" style={{ marginBottom: '1rem' }}>
          ✨ Register New Service
        </h3>
        <p style={{ fontSize: '0.85rem', color: 'var(--text-secondary)', marginBottom: '1.5rem' }}>
          Provide cluster service parameters to instantiate a reactive data pipeline.
        </p>

        <form onSubmit={handleSubmit}>
          <div className="control-group">
            <label className="control-label">Service Name</label>
            <input
              type="text"
              className="search-input"
              placeholder="e.g. auth-gateway-v2"
              value={name}
              onChange={(e) => setName(e.target.value)}
              autoFocus
              required
            />
          </div>

          <div className="control-group">
            <label className="control-label">Service Layer</label>
            <select
              className="search-input"
              value={category}
              onChange={(e) => setCategory(e.target.value)}
            >
              <option value="Compute">Compute</option>
              <option value="Storage">Storage</option>
              <option value="Network">Network</option>
            </select>
          </div>

          <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '0.75rem', marginTop: '1.5rem' }}>
            <button type="button" onClick={onClose} className="btn btn-secondary">
              Cancel
            </button>
            <button type="submit" className="btn btn-primary">
              Deploy Service
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
