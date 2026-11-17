<script lang="ts">
import ThemeToggle from './components/ThemeToggle.svelte';
import MetricCard from './components/MetricCard.svelte';
import InteractiveControls from './components/InteractiveControls.svelte';
import ModalDialog from './components/ModalDialog.svelte';

// Svelte 5 Runes: $state
let theme = $state<'dark' | 'light'>('dark');
let velocity = $state<number>(65);
let activeCategory = $state<string>('Overview');
let gpuAcceleration = $state<boolean>(true);
let isModalOpen = $state<boolean>(false);
let interactionCount = $state<number>(0);

const categories = ['Overview', 'Telemetry', 'Memory Pool', 'Render Pipeline'];

// Svelte 5 Rune: $effect (synchronizes theme with DOM)
$effect(() => {
  document.documentElement.setAttribute('data-theme', theme);
});

// Svelte 5 Runes: $derived (computed state)
let throughput = $derived.by(() => {
  const base = velocity * 142;
  return gpuAcceleration ? Math.round(base * 1.85) : base;
});

let efficiencyScore = $derived.by(() => {
  return Math.min(100, Math.round((velocity / 200) * 80 + (gpuAcceleration ? 20 : 5)));
});

function toggleTheme() {
  theme = theme === 'dark' ? 'light' : 'dark';
  interactionCount++;
}

function handleVelocity(val: number) {
  velocity = val;
  interactionCount++;
}

function handleCategory(cat: string) {
  activeCategory = cat;
  interactionCount++;
}

function toggleGpu() {
  gpuAcceleration = !gpuAcceleration;
  interactionCount++;
}

function resetDefaults() {
  velocity = 100;
  gpuAcceleration = true;
  interactionCount++;
}

function boostMax() {
  velocity = 200;
  interactionCount++;
}
</script>

<div class="app-container">
  <!-- Header -->
  <header class="app-header">
    <div class="brand-wrapper">
      <div class="framework-badge">
        🔥 Svelte 5 (Runes)
      </div>
      <div>
        <h1 class="header-title">UI Design & Reactivity Studio</h1>
        <p class="header-subtitle">
          Learn compiler-first UI architecture, zero Virtual DOM, and modern Svelte 5 Runes
        </p>
      </div>
    </div>
    <ThemeToggle {theme} ontoggle={toggleTheme} />
  </header>

  <!-- Metrics Row -->
  <section class="grid-metrics">
    <MetricCard
      label="Throughput"
      value={`${throughput.toLocaleString()} ops`}
      growth="+18.4%"
      growthType="pos"
      icon="⚡"
      iconBg="rgba(255, 62, 0, 0.2)"
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

  <!-- Studio Two-Column Layout -->
  <div class="studio-layout">
    <!-- Left Column: Interactive Controls -->
    <InteractiveControls
      {velocity}
      {activeCategory}
      {categories}
      {gpuAcceleration}
      onvelocitychange={handleVelocity}
      oncategorychange={handleCategory}
      ontogglegpu={toggleGpu}
    />

    <!-- Right Column: Live State Inspector -->
    <div class="glass-panel">
      <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 1.25rem;">
        <h3 class="panel-heading" style="margin-bottom: 0;">🔬 Svelte 5 Runes Inspector</h3>
        <button class="btn btn-primary" onclick={() => (isModalOpen = true)}>
          Open Modal Dialog
        </button>
      </div>

      <p style="color: var(--text-secondary); font-size: 0.875rem; margin-bottom: 1rem;">
        In Svelte 5, <code>$state</code> and <code>$derived</code> are compile-time signals. The Svelte compiler compiles this component into direct DOM update instructions with zero virtual DOM overhead:
      </p>

      <pre class="state-inspector">
{JSON.stringify(
  {
    framework: 'Svelte 5 (Runes System)',
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

      <div style="margin-top: 1.25rem; display: flex; gap: 0.75rem;">
        <button class="btn btn-secondary" onclick={resetDefaults}>
          Reset to Defaults
        </button>
        <button class="btn btn-secondary" onclick={boostMax}>
          Boost to Max
        </button>
      </div>
    </div>
  </div>

  <!-- Educational Callout -->
  <div class="learning-callout">
    <h4>💡 Svelte 5 Architectural Concept: Runes & No Virtual DOM</h4>
    <p>
      Unlike React or Vue, Svelte is a true <em>compiler</em>. Instead of shipping a runtime library that creates virtual DOM nodes, Svelte turns your template into precise vanilla JavaScript DOM statements (like <code>node.data = newVelocity</code>). Svelte 5's <code>$state</code> and <code>$derived</code> runes bring universal, fine-grained reactivity anywhere inside or outside components!
    </p>
  </div>

  <!-- Modal Dialog -->
  <ModalDialog
    isOpen={isModalOpen}
    title="Svelte 5 Modal Architecture"
    onclose={() => (isModalOpen = false)}
  >
    <p style="line-height: 1.6; margin-bottom: 0.75rem;">
      This modal demonstrates Svelte 5's new <strong>Snippets</strong> feature (<code>&#123;@render children?.()&#125;</code>) replacing legacy slots.
    </p>
    <p style="line-height: 1.6;">
      It also uses <code>&lt;svelte:window onkeydown&gt;</code> to cleanly listen for the <kbd style="padding: 2px 6px; background: var(--surface-inset); border-radius: 4px;">Escape</kbd> key!
    </p>
  </ModalDialog>
</div>
