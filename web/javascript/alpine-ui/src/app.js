import Alpine from 'alpinejs';
import './style.css';

// Register Alpine Data Component
Alpine.data('dashboard', () => ({
  theme: 'dark',
  velocity: 6,
  activeCategory: 'All',
  categories: ['All', 'Compute', 'Storage', 'Network'],
  gpuAcceleration: true,
  searchTerm: '',
  isModalOpen: false,
  newServiceName: '',
  newServiceCategory: 'Compute',

  services: [
    { id: 1, name: 'api-gateway-edge', category: 'Network', latency: 12, status: 'active' },
    { id: 2, name: 'vector-search-engine', category: 'Compute', latency: 28, status: 'active' },
    { id: 3, name: 'redis-cache-cluster', category: 'Storage', latency: 4, status: 'active' },
    { id: 4, name: 'neural-inference-worker', category: 'Compute', latency: 64, status: 'standby' },
    { id: 5, name: 's3-blob-replicator', category: 'Storage', latency: 45, status: 'active' },
  ],

  init() {
    this.syncTheme();
  },

  syncTheme() {
    document.documentElement.setAttribute('data-theme', this.theme);
  },

  toggleTheme() {
    this.theme = this.theme === 'dark' ? 'light' : 'dark';
    this.syncTheme();
  },

  get throughput() {
    return (this.velocity * 482).toLocaleString();
  },

  get memoryUtilization() {
    return Math.min(96, Math.round(32 + this.velocity * 3.2));
  },

  get filteredServices() {
    return this.services.filter((item) => {
      const matchesSearch = item.name
        .toLowerCase()
        .includes(this.searchTerm.toLowerCase());
      const matchesCategory =
        this.activeCategory === 'All' || item.category === this.activeCategory;
      return matchesSearch && matchesCategory;
    });
  },

  addService() {
    if (!this.newServiceName.trim()) return;
    this.services.unshift({
      id: Date.now(),
      name: this.newServiceName.trim(),
      category: this.newServiceCategory,
      latency: Math.floor(Math.random() * 40) + 5,
      status: 'active',
    });
    this.newServiceName = '';
    this.isModalOpen = false;
  },
}));

window.Alpine = Alpine;
Alpine.start();
