import { Component, createSignal, createMemo, createEffect } from 'solid-js';
import { ThemeToggle } from './components/ThemeToggle';
import { MetricCard } from './components/MetricCard';
import { InteractiveControls } from './components/InteractiveControls';
import { ModalDialog } from './components/ModalDialog';

export const App: Component = () => {
  // Fine-grained Reactive Signals
  const [theme, setTheme] = createSignal<'dark' | 'light'>('dark');
  const [velocity, setVelocity] = createSignal<number>(65);
  const [activeCategory, setActiveCategory] = createSignal<string>('Overview');
  const [gpuAcceleration, setGpuAcceleration] = createSignal<boolean>(true);
  const [isModalOpen, setIsModalOpen] = createSignal<boolean>(false);
  const [interactionCount, setInteractionCount] = createSignal<number>(0);

  const categories = ['Overview', 'Telemetry', 'Memory Pool', 'Render Pipeline'];

  // Side Effect: Synchronize theme on documentElement
  createEffect(() => {
    document.documentElement.setAttribute('data-theme', theme());
  });

  // Derived / Computed state using createMemo
  const throughput = createMemo(() => {
    const base = velocity() * 142;
    return gpuAcceleration() ? Math.round(base * 1.85) : base;
  });

  const efficiencyScore = createMemo(() => {
    return Math.min(100, Math.round((velocity() / 200) * 80 + (gpuAcceleration() ? 20 : 5)));
  });

  const toggleTheme = () => {
    setTheme((prev) => (prev === 'dark' ? 'light' : 'dark'));
    setInteractionCount((c) => c + 1);
  };

  const handleVelocity = (val: number) => {
    setVelocity(val);
    setInteractionCount((c) => c + 1);
  };

  const handleCategory = (cat: string) => {
    setActiveCategory(cat);
    setInteractionCount((c) => c + 1);
  };

  const toggleGpu = () => {
    setGpuAcceleration((prev) => !prev);
    setInteractionCount((c) => c + 1);
  };

  const resetDefaults = () => {
    setVelocity(100);
    setGpuAcceleration(true);
    setInteractionCount((c) => c + 1);
  };

  const boostMax = () => {
    setVelocity(200);
    setInteractionCount((c) => c + 1);
  };

  return (
    <div class="app-container">
      {/* Header */}
      <header class="app-header">
        <div class="brand-wrapper">
          <div class="framework-badge">
            💙 SolidJS (Signals)
          </div>
          <div>
            <h1 class="header-title">UI Design & Reactivity Studio</h1>
            <p class="header-subtitle">
              Learn fine-grained signals, zero virtual DOM, and component run-once execution
            </p>
          </div>
        </div>
        <ThemeToggle theme={theme()} onToggle={toggleTheme} />
      </header>

      {/* Metrics Row */}
      <section class="grid-metrics">
        <MetricCard
          label="Throughput"
          value={`${throughput().toLocaleString()} ops`}
          growth="+18.4%"
          growthType="pos"
          icon="⚡"
          iconBg="rgba(68, 136, 238, 0.2)"
          progressPercent={efficiencyScore()}
        />
        <MetricCard
          label="Engine Velocity"
          value={`${velocity()} fps`}
          growth={velocity() > 100 ? '+32.1%' : '-4.2%'}
          growthType={velocity() > 100 ? 'pos' : 'neutral'}
          icon="🚀"
          iconBg="rgba(168, 85, 247, 0.2)"
          progressPercent={Math.round((velocity() / 200) * 100)}
        />
        <MetricCard
          label="Active Mode"
          value={gpuAcceleration() ? 'Hardware GPU' : 'Software'}
          growth={gpuAcceleration() ? 'Ultra Latency' : 'Fallback'}
          growthType={gpuAcceleration() ? 'pos' : 'neutral'}
          icon="💎"
          iconBg="rgba(16, 185, 129, 0.2)"
        />
        <MetricCard
          label="Total Interactions"
          value={interactionCount()}
          growth="Live Clicks"
          growthType="neutral"
          icon="🎯"
          iconBg="rgba(245, 158, 11, 0.2)"
        />
      </section>

      {/* Studio Two-Column Layout */}
      <div class="studio-layout">
        {/* Left Column: Interactive Controls */}
        <InteractiveControls
          velocity={velocity()}
          onVelocityChange={handleVelocity}
          activeCategory={activeCategory()}
          categories={categories}
          onCategoryChange={handleCategory}
          gpuAcceleration={gpuAcceleration()}
          onGpuToggle={toggleGpu}
        />

        {/* Right Column: Live State Inspector */}
        <div class="glass-panel">
          <div style={{ display: 'flex', 'justify-content': 'space-between', 'align-items': 'center', 'margin-bottom': '1.25rem' }}>
            <h3 class="panel-heading" style={{ 'margin-bottom': 0 }}>🔬 Solid Signals Inspector</h3>
            <button class="btn btn-primary" onClick={() => setIsModalOpen(true)}>
              Open Modal Dialog
            </button>
          </div>

          <p style={{ color: 'var(--text-secondary)', 'font-size': '0.875rem', 'margin-bottom': '1rem' }}>
            Unlike React, this <code>App()</code> component function only executes <strong>ONCE</strong> at mount! Only the signals subscribed inside each specific DOM binding execute when data changes:
          </p>

          <pre class="state-inspector">
{JSON.stringify(
  {
    framework: 'SolidJS (Signals Architecture)',
    theme: theme(),
    activeCategory: activeCategory(),
    velocity: velocity(),
    gpuAcceleration: gpuAcceleration(),
    derivedStats: {
      throughput: throughput(),
      efficiencyScore: `${efficiencyScore()}%`,
    },
    totalInteractions: interactionCount(),
  },
  null,
  2
)}
          </pre>

          <div style={{ 'margin-top': '1.25rem', display: 'flex', gap: '0.75rem' }}>
            <button class="btn btn-secondary" onClick={resetDefaults}>
              Reset to Defaults
            </button>
            <button class="btn btn-secondary" onClick={boostMax}>
              Boost to Max
            </button>
          </div>
        </div>
      </div>

      {/* Educational Callout */}
      <div class="learning-callout">
        <h4>💡 SolidJS Architectural Concept: Fine-Grained Signals</h4>
        <p>
          SolidJS combines the developer ergonomics of JSX with the raw performance of fine-grained reactive signals. Unlike React, there is <strong>no Virtual DOM</strong> and <strong>no component re-rendering</strong>. The JSX is compiled directly to real DOM nodes, and signal accessors (like <code>velocity()</code>) bind microscopic subscription listeners directly to individual text nodes and element properties!
        </p>
      </div>

      {/* Modal Dialog */}
      <ModalDialog
        isOpen={isModalOpen()}
        onClose={() => setIsModalOpen(false)}
        title="SolidJS Modal Architecture"
      >
        <p style={{ 'line-height': 1.6, 'margin-bottom': '0.75rem' }}>
          This modal demonstrates Solid's <code>&lt;Show&gt;</code> control component for conditional rendering.
        </p>
        <p style={{ 'line-height': 1.6 }}>
          It also uses <code>onMount</code> and <code>onCleanup</code> to safely bind and unbind the <kbd style={{ padding: '2px 6px', background: 'var(--surface-inset)', 'border-radius': '4px' }}>Escape</kbd> key without memory leaks!
        </p>
      </ModalDialog>
    </div>
  );
};
