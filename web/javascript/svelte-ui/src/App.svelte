<script>
  // Svelte 5 Runes in Pure JavaScript
  import ThemeToggle from './components/ThemeToggle.svelte';
  import MetricCard from './components/MetricCard.svelte';
  import InteractiveControls from './components/InteractiveControls.svelte';
  import DataList from './components/DataList.svelte';
  import ModalDialog from './components/ModalDialog.svelte';

  let theme = $state('dark');
  let velocity = $state(6);
  let activeCategory = $state('All');
  let gpuAcceleration = $state(true);
  let searchTerm = $state('');
  let isModalOpen = $state(false);

  let services = $state([
    { id: 1, name: 'api-gateway-edge', category: 'Network', latency: 12, status: 'active' },
    { id: 2, name: 'vector-search-engine', category: 'Compute', latency: 28, status: 'active' },
    { id: 3, name: 'redis-cache-cluster', category: 'Storage', latency: 4, status: 'active' },
    { id: 4, name: 'neural-inference-worker', category: 'Compute', latency: 64, status: 'standby' },
    { id: 5, name: 's3-blob-replicator', category: 'Storage', latency: 45, status: 'active' },
  ]);

  // $effect rune: runs reactively when theme changes
  $effect(() => {
    document.documentElement.setAttribute('data-theme', theme);
  });

  function toggleTheme() {
    theme = theme === 'dark' ? 'light' : 'dark';
  }

  function handleAddService(newService) {
    services = [newService, ...services];
  }

  // $derived runes: automatically recalculated derived values
  let throughput = $derived((velocity * 482).toLocaleString());
  let memoryUtilization = $derived(Math.min(96, Math.round(32 + velocity * 3.2)));
</script>

<div class="container">
  <!-- Header -->
  <header class="app-header">
    <div class="logo-group">
      <div style="font-size: 2rem;">🔥</div>
      <div>
        <div style="display: flex; align-items: center; gap: 0.5rem;">
          <h1 class="app-title">Svelte 5 UI Studio</h1>
          <span class="framework-badge">Svelte 5 / Runes (JS)</span>
        </div>
        <p class="app-subtitle">
          Compiler-driven fine-grained reactivity, $state / $derived runes, and zero virtual DOM.
        </p>
      </div>
    </div>

    <ThemeToggle {theme} onToggle={toggleTheme} />
  </header>

  <!-- Metrics Grid -->
  <section class="metrics-grid">
    <MetricCard
      label="Cluster Throughput"
      value="{throughput} req/s"
      growth="+18.4%"
      growthType="pos"
      icon="⚡"
      iconBg="rgba(56, 189, 248, 0.2)"
      progressPercent={velocity * 5}
    />
    <MetricCard
      label="Memory Allocation"
      value="{memoryUtilization}%"
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

  <!-- Main Dashboard Columns -->
  <div class="dashboard-columns">
    <InteractiveControls
      bind:velocity
      bind:activeCategory
      categories={['All', 'Compute', 'Storage', 'Network']}
      bind:gpuAcceleration
      onToggleGpu={() => gpuAcceleration = !gpuAcceleration}
    />

    <DataList
      items={services}
      bind:searchTerm
      {activeCategory}
      onOpenModal={() => isModalOpen = true}
    />
  </div>

  <!-- Educational Framework Note -->
  <div class="info-box">
    💡 <strong>Svelte 5 Mental Model (JavaScript)</strong>: Svelte is a compiler. There is no Virtual DOM.
    Variables declared with <code>$state(...)</code> become fine-grained reactive signals that surgically mutate specific DOM text nodes.
    Runes (<code>$state</code>, <code>$derived</code>, <code>$effect</code>, <code>$props</code>) provide universal reactivity in pure JavaScript.
  </div>

  <!-- Service Modal -->
  <ModalDialog
    isOpen={isModalOpen}
    onClose={() => isModalOpen = false}
    onAddService={handleAddService}
  />
</div>
