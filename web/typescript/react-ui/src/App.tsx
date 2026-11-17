import React, { useState, useMemo, useEffect } from 'react';
import { ThemeToggle } from './components/ThemeToggle';
import { MetricCard } from './components/MetricCard';
import { InteractiveControls } from './components/InteractiveControls';
import { ModalDialog } from './components/ModalDialog';

export const App: React.FC = () => {
  // State: Theme
  const [theme, setTheme] = useState<'dark' | 'light'>('dark');

  // State: Interactive controls
  const [velocity, setVelocity] = useState<number>(65);
  const [activeCategory, setActiveCategory] = useState<string>('Overview');
  const [gpuAcceleration, setGpuAcceleration] = useState<boolean>(true);
  const [isModalOpen, setIsModalOpen] = useState<boolean>(false);
  const [interactionCount, setInteractionCount] = useState<number>(0);

  const categories = ['Overview', 'Telemetry', 'Memory Pool', 'Render Pipeline'];

  // Apply theme to HTML root element
  useEffect(() => {
    document.documentElement.setAttribute('data-theme', theme);
  }, [theme]);

  // Derived / Computed state using useMemo
  const throughput = useMemo(() => {
    const base = velocity * 142;
    return gpuAcceleration ? Math.round(base * 1.85) : base;
  }, [velocity, gpuAcceleration]);

  const efficiencyScore = useMemo(() => {
    return Math.min(100, Math.round((velocity / 200) * 80 + (gpuAcceleration ? 20 : 5)));
  }, [velocity, gpuAcceleration]);

  const handleToggleTheme = () => {
    setTheme((prev) => (prev === 'dark' ? 'light' : 'dark'));
    setInteractionCount((c) => c + 1);
  };

  const handleVelocityChange = (val: number) => {
    setVelocity(val);
    setInteractionCount((c) => c + 1);
  };

  const handleCategoryChange = (cat: string) => {
    setActiveCategory(cat);
    setInteractionCount((c) => c + 1);
  };

  const handleGpuToggle = () => {
    setGpuAcceleration((prev) => !prev);
    setInteractionCount((c) => c + 1);
  };

  return (
    <div className="app-container">
      {/* Header */}
      <header className="app-header">
        <div className="brand-wrapper">
          <div className="framework-badge">
            ⚛️ React 18 / 19
          </div>
          <div>
            <h1 className="header-title">UI Design & Reactivity Studio</h1>
            <p className="header-subtitle">
              Learn React component composition, hooks, and virtual DOM state modeling
            </p>
          </div>
        </div>
        <ThemeToggle theme={theme} onToggle={handleToggleTheme} />
      </header>

      {/* Metrics Row */}
      <section className="grid-metrics">
        <MetricCard
          label="Throughput"
          value={`${throughput.toLocaleString()} ops`}
          growth="+18.4%"
          growthType="pos"
          icon="⚡"
          iconBg="rgba(56, 189, 248, 0.2)"
          progressPercent={efficiencyScore}
        />
        <MetricCard
          label="Engine Velocity"
          value={`${velocity} fps`}
          growth={velocity > 100 ? '+32.1%' : '-4.2%'}
          growthType={velocity > 100 ? 'pos' : 'neutral'}
          icon="🚀"
          iconBg="rgba(168, 85, 247, 0.2)"
          progressPercent={Math.round((velocity / 200) * 100)}
        />
        <MetricCard
          label="Active Mode"
          value={gpuAcceleration ? 'Hardware GPU' : 'Software'}
          growth={gpuAcceleration ? 'Ultra Latency' : 'Fallback'}
          growthType={gpuAcceleration ? 'pos' : 'neutral'}
          icon="💎"
          iconBg="rgba(16, 185, 129, 0.2)"
        />
        <MetricCard
          label="Total Interactions"
          value={interactionCount}
          growth="Live Clicks"
          growthType="neutral"
          icon="🎯"
          iconBg="rgba(245, 158, 11, 0.2)"
        />
      </section>

      {/* Studio Two-Column Layout */}
      <div className="studio-layout">
        {/* Left Column: Interactive Controls */}
        <InteractiveControls
          velocity={velocity}
          onVelocityChange={handleVelocityChange}
          activeCategory={activeCategory}
          categories={categories}
          onCategoryChange={handleCategoryChange}
          gpuAcceleration={gpuAcceleration}
          onGpuToggle={handleGpuToggle}
        />

        {/* Right Column: Live State Inspector & Action Panel */}
        <div className="glass-panel">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1.25rem' }}>
            <h3 className="panel-heading" style={{ marginBottom: 0 }}>🔬 React State Inspector</h3>
            <button className="btn btn-primary" onClick={() => setIsModalOpen(true)}>
              Open Modal Dialog
            </button>
          </div>

          <p style={{ color: 'var(--text-secondary)', fontSize: '0.875rem', marginBottom: '1rem' }}>
            React re-renders this component hierarchy whenever state hooks (<code>useState</code>) update. Watch the live JSON below reflect reactivity in real-time:
          </p>

          <pre className="state-inspector">
{JSON.stringify(
  {
    framework: 'React (with Hooks)',
    theme,
    activeCategory,
    velocity,
    gpuAcceleration,
    derivedStats: {
      throughput,
      efficiencyScore: `${efficiencyScore}%`,
    },
    totalInteractions: interactionCount,
  },
  null,
  2
)}
          </pre>

          <div style={{ marginTop: '1.25rem', display: 'flex', gap: '0.75rem' }}>
            <button
              className="btn btn-secondary"
              onClick={() => {
                setVelocity(100);
                setGpuAcceleration(true);
                setInteractionCount((c) => c + 1);
              }}
            >
              Reset to Defaults
            </button>
            <button
              className="btn btn-secondary"
              onClick={() => {
                setVelocity(200);
                setInteractionCount((c) => c + 1);
              }}
            >
              Boost to Max
            </button>
          </div>
        </div>
      </div>

      {/* Educational Callout */}
      <div className="learning-callout">
        <h4>💡 React Architectural Concept: Virtual DOM & Hooks</h4>
        <p>
          In React, components are pure JavaScript functions that return JSX. When you call <code>setVelocity(newVal)</code>, React flags this component as dirty, re-runs <code>App()</code>, creates a lightweight Virtual DOM tree representation, diffs it against the previous snapshot (reconciliation), and commits only the exact changed DOM text nodes to the browser.
        </p>
      </div>

      {/* Modal Dialog */}
      <ModalDialog
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        title="React Modal Architecture"
      >
        <p style={{ lineHeight: 1.6, marginBottom: '0.75rem' }}>
          This modal demonstrates how React manages overlay state conditionally with <code>isOpen</code>.
        </p>
        <p style={{ lineHeight: 1.6 }}>
          It also binds a global key listener with <code>useEffect</code> to close when the <kbd style={{ padding: '2px 6px', background: 'var(--surface-inset)', borderRadius: '4px' }}>Escape</kbd> key is pressed!
        </p>
      </ModalDialog>
    </div>
  );
};
