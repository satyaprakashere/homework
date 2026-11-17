import React, { useState, useEffect } from 'react';
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
  const [theme, setTheme] = useState('dark');
  const [velocity, setVelocity] = useState(6);
  const [activeCategory, setActiveCategory] = useState('All');
  const [gpuAcceleration, setGpuAcceleration] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [services, setServices] = useState(INITIAL_SERVICES);
  const [isModalOpen, setIsModalOpen] = useState(false);

  // Sync theme with DOM data attribute
  useEffect(() => {
    document.documentElement.setAttribute('data-theme', theme);
  }, [theme]);

  const toggleTheme = () => {
    setTheme((prev) => (prev === 'dark' ? 'light' : 'dark'));
  };

  const handleAddService = (newService) => {
    setServices((prev) => [newService, ...prev]);
  };

  const throughput = (velocity * 482).toLocaleString();
  const memoryUtilization = Math.min(96, Math.round(32 + velocity * 3.2));

  return (
    <div className="container">
      {/* Header */}
      <header className="app-header">
        <div className="logo-group">
          <div style={{ fontSize: '2rem' }}>⚛️</div>
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
              <h1 className="app-title">React UI Studio</h1>
              <span className="framework-badge">React 18 / Pure JS</span>
            </div>
            <p className="app-subtitle">
              Declarative component composition, hooks, and Virtual DOM in pure JavaScript.
            </p>
          </div>
        </div>

        <ThemeToggle theme={theme} onToggle={toggleTheme} />
      </header>

      {/* Metrics Grid */}
      <section className="metrics-grid">
        <MetricCard
          label="Cluster Throughput"
          value={`${throughput} req/s`}
          growth="+18.4%"
          growthType="pos"
          icon="⚡"
          iconBg="rgba(56, 189, 248, 0.2)"
          progressPercent={velocity * 5}
        />
        <MetricCard
          label="Memory Allocation"
          value={`${memoryUtilization}%`}
          growth={gpuAcceleration ? 'GPU Offload' : 'CPU Only'}
          growthType="neutral"
          icon="🧠"
          iconBg="rgba(168, 85, 247, 0.2)"
          progressPercent={memoryUtilization}
        />
        <MetricCard
          label="Active Nodes"
          value={services.length}
          growth="+2 Nodes"
          growthType="pos"
          icon="🌐"
          iconBg="rgba(16, 185, 129, 0.2)"
          progressPercent={Math.min(100, services.length * 15)}
        />
        <MetricCard
          label="Average Latency"
          value={gpuAcceleration ? '14.2 ms' : '28.6 ms'}
          growth={gpuAcceleration ? '-50% Latency' : 'Standard'}
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
        💡 <strong>React Mental Model (JavaScript)</strong>: UI is a pure function of state: <code>UI = f(state)</code>.
        Components re-render upon <code>useState</code> updates, triggering a lightweight Virtual DOM reconciliation pass.
        Written in standard <code>.jsx</code> with zero TypeScript transpilation overhead.
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
