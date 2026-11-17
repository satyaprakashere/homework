import { createSignal, createMemo, createEffect } from 'solid-js';
import { ThemeToggle } from './components/ThemeToggle.jsx';
import { MetricCard } from './components/MetricCard.jsx';
import { InteractiveControls } from './components/InteractiveControls.jsx';
import { DataList } from './components/DataList.jsx';
import { ModalDialog } from './components/ModalDialog.jsx';

const INITIAL_SERVICES = [
  { id: 1, name: 'api-gateway-edge', category: 'Network', latency: 12, status: 'active' },
  { id: 2, name: 'vector-search-engine', category: 'Compute', latency: 28, status: 'active' },
  { id: 3, name: 'redis-cache-cluster', category: 'Storage', latency: 4, status: 'active' },
  { id: 4, name: 'neural-inference-worker', category: 'Compute', latency: 64, status: 'standby' },
  { id: 5, name: 's3-blob-replicator', category: 'Storage', latency: 45, status: 'active' },
];

export function App() {
  const [theme, setTheme] = createSignal('dark');
  const [velocity, setVelocity] = createSignal(6);
  const [activeCategory, setActiveCategory] = createSignal('All');
  const [gpuAcceleration, setGpuAcceleration] = createSignal(true);
  const [searchTerm, setSearchTerm] = createSignal('');
  const [services, setServices] = createSignal(INITIAL_SERVICES);
  const [isModalOpen, setIsModalOpen] = createSignal(false);

  // Sync theme with DOM data attribute using createEffect
  createEffect(() => {
    document.documentElement.setAttribute('data-theme', theme());
  });

  const toggleTheme = () => {
    setTheme((prev) => (prev === 'dark' ? 'light' : 'dark'));
  };

  const handleAddService = (newService) => {
    setServices((prev) => [newService, ...prev]);
  };

  // Fine-grained memoized calculations
  const throughput = createMemo(() => (velocity() * 482).toLocaleString());
  const memoryUtilization = createMemo(() =>
    Math.min(96, Math.round(32 + velocity() * 3.2))
  );

  return (
    <div className="container">
      {/* Header */}
      <header className="app-header">
        <div className="logo-group">
          <div style={{ 'font-size': '2rem' }}>🔵</div>
          <div>
            <div style={{ display: 'flex', 'align-items': 'center', gap: '0.5rem' }}>
              <h1 className="app-title">SolidJS UI Studio</h1>
              <span className="framework-badge">SolidJS / Signals (JS)</span>
            </div>
            <p className="app-subtitle">
              Reactive signals, zero-VDOM fine-grained DOM bindings, and single-execution JSX.
            </p>
          </div>
        </div>

        <ThemeToggle theme={theme} onToggle={toggleTheme} />
      </header>

      {/* Metrics Grid */}
      <section className="metrics-grid">
        <MetricCard
          label="Cluster Throughput"
          value={`${throughput()} req/s`}
          growth="+18.4%"
          growthType="pos"
          icon="⚡"
          iconBg="rgba(56, 189, 248, 0.2)"
          progressPercent={velocity() * 5}
        />
        <MetricCard
          label="Memory Allocation"
          value={`${memoryUtilization()}%`}
          growth={gpuAcceleration() ? 'GPU Offload' : 'CPU Only'}
          growthType="neutral"
          icon="🧠"
          iconBg="rgba(168, 85, 247, 0.2)"
          progressPercent={memoryUtilization()}
        />
        <MetricCard
          label="Active Nodes"
          value={services().length}
          growth="+2 Nodes"
          growthType="pos"
          icon="🌐"
          iconBg="rgba(16, 185, 129, 0.2)"
          progressPercent={Math.min(100, services().length * 15)}
        />
        <MetricCard
          label="Average Latency"
          value={gpuAcceleration() ? '14.2 ms' : '28.6 ms'}
          growth={gpuAcceleration() ? '-50% Latency' : 'Standard'}
          growthType="pos"
          icon="⏱️"
          iconBg="rgba(245, 158, 11, 0.2)"
        />
      </section>

      {/* Main Dashboard Columns */}
      <div className="dashboard-columns">
        <InteractiveControls
          velocity={velocity}
          onVelocityChange={setVelocity}
          activeCategory={activeCategory}
          categories={['All', 'Compute', 'Storage', 'Network']}
          onCategoryChange={setActiveCategory}
          gpuAcceleration={gpuAcceleration}
          onGpuToggle={() => setGpuAcceleration((prev) => !prev)}
        />

        <DataList
          items={services}
          searchTerm={searchTerm}
          onSearchChange={setSearchTerm}
          activeCategory={activeCategory}
          onOpenModal={() => setIsModalOpen(true)}
        />
      </div>

      {/* Educational Framework Note */}
      <div className="info-box">
        💡 <strong>SolidJS Mental Model (JavaScript)</strong>: Components run exactly ONCE on mount!
        Unlike React, updating a signal (<code>setVelocity(10)</code>) never re-executes the component body.
        Instead, the getter function (<code>velocity()</code>) wires directly to the specific DOM text node.
      </div>

      {/* Service Modal */}
      <ModalDialog
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        onAddService={handleAddService}
      />
    </div>
  );
}
