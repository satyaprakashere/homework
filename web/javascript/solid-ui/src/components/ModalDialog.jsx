import { Show, createSignal } from 'solid-js';

/**
 * Pure JavaScript SolidJS Component: ModalDialog
 */
export function ModalDialog(props) {
  const [name, setName] = createSignal('');
  const [category, setCategory] = createSignal('Compute');

  const handleSubmit = (e) => {
    e.preventDefault();
    if (!name().trim()) return;
    props.onAddService({
      id: Date.now(),
      name: name().trim(),
      category: category(),
      latency: Math.floor(Math.random() * 40) + 5,
      status: 'active',
    });
    setName('');
    props.onClose();
  };

  return (
    <Show when={props.isOpen()}>
      <div className="modal-overlay" onClick={() => props.onClose()}>
        <div className="modal-content" onClick={(e) => e.stopPropagation()}>
          <h3 className="panel-heading" style={{ 'margin-bottom': '1rem' }}>
            ✨ Register New Service
          </h3>
          <p style={{ 'font-size': '0.85rem', color: 'var(--text-secondary)', 'margin-bottom': '1.5rem' }}>
            Provide cluster service parameters to instantiate a reactive data pipeline.
          </p>

          <form onSubmit={handleSubmit}>
            <div className="control-group">
              <label className="control-label">Service Name</label>
              <input
                type="text"
                className="search-input"
                placeholder="e.g. auth-gateway-v2"
                value={name()}
                onInput={(e) => setName(e.target.value)}
                required
              />
            </div>

            <div className="control-group">
              <label className="control-label">Service Layer</label>
              <select
                className="search-input"
                value={category()}
                onChange={(e) => setCategory(e.target.value)}
              >
                <option value="Compute">Compute</option>
                <option value="Storage">Storage</option>
                <option value="Network">Network</option>
              </select>
            </div>

            <div
              style={{
                display: 'flex',
                'justify-content': 'flex-end',
                gap: '0.75rem',
                'margin-top': '1.5rem',
              }}
            >
              <button
                type="button"
                onClick={() => props.onClose()}
                className="btn btn-secondary"
              >
                Cancel
              </button>
              <button type="submit" className="btn btn-primary">
                Deploy Service
              </button>
            </div>
          </form>
        </div>
      </div>
    </Show>
  );
}
