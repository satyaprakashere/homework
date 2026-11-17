# 🎨 Modern Pure JavaScript UI Frameworks: Architectural & Design Guide

Welcome! This directory provides standalone, self-contained educational projects demonstrating modern UI design across the 5 most popular JavaScript UI frameworks + HTMX.

Every project is written in **100% Pure JavaScript** (no TypeScript, no `.ts`/`.tsx`, no `tsconfig.json`) using standard ESM and modern JavaScript features.

---

## 📊 Framework Comparison Matrix

| Directory | Framework | Paradigm | Reactivity Engine | DOM Rendering Model | Best Suited For |
| :--- | :--- | :--- | :--- | :--- | :--- |
| [`react-ui/`](./react-ui) | **React 18** | Functional Components + JSX | Hooks (`useState`, `useMemo`) | Virtual DOM Reconciliation | Large enterprise apps, enormous ecosystem, cross-platform |
| [`vue-ui/`](./vue-ui) | **Vue 3** | Single-File Components (`.vue`) | ES6 Proxies (`ref`, `computed`) | Compiler-optimized Virtual DOM | Progressive development, rapid prototyping, clean separation |
| [`svelte-ui/`](./svelte-ui) | **Svelte 5** | Compiler-First Templates | Runes (`$state`, `$derived`) | Direct DOM mutations (No VDOM) | High-performance dashboards, lightweight bundles, low latency |
| [`solid-ui/`](./solid-ui) | **SolidJS** | Single-Execution JSX | Fine-Grained Signals | Direct DOM nodes, functions as subscribers | Extreme runtime performance, real-time telemetry, lean memory |
| [`alpine-ui/`](./alpine-ui) | **Alpine.js** | In-DOM Declarative Directives | Vue-based reactivity in HTML | Direct DOM manipulation via attributes | Enhancing server-rendered HTML (PHP/Django/Rails), zero build |
| [`htmx-ui/`](./htmx-ui) | **HTMX 2.x** | Hypermedia as State (HATEOAS) | Server-driven HTML swaps | Partial DOM replacement (`outerHTML`) | Fullstack web apps with minimal client JS, server-first systems |

---

## ⚡ Quick Start: How to Run Any Showcase

All projects run smoothly using `bun` (instant) or `npm`:

```bash
# 1. React (JS / JSX)
cd react-ui
bun install && bun run dev

# 2. Vue 3 (JS SFC)
cd vue-ui
bun install && bun run dev

# 3. Svelte 5 (JS Runes)
cd svelte-ui
bun install && bun run dev

# 4. SolidJS (JS Signals)
cd solid-ui
bun install && bun run dev

# 5. Alpine.js (JS Directives)
cd alpine-ui
bun install && bun run dev

# 6. HTMX (Hypermedia + JS Server)
cd htmx-ui
bun run dev
```

---

## 🔍 Conceptual Code Comparison: How Each Framework Solves Core UI Problems

### 1. Declaring Reactive State

#### React (JavaScript)
```jsx
const [velocity, setVelocity] = useState(6);
// Updating:
setVelocity(v => v + 1);
```

#### Vue 3 (JavaScript Composition API)
```js
const velocity = ref(6);
// Updating:
velocity.value++;
```

#### Svelte 5 (JavaScript Runes)
```js
let velocity = $state(6);
// Updating:
velocity++;
```

#### SolidJS (JavaScript Signals)
```jsx
const [velocity, setVelocity] = createSignal(6);
// Reading: velocity()
// Updating:
setVelocity(v => v + 1);
```

#### Alpine.js (JavaScript in HTML)
```html
<div x-data="{ velocity: 6 }">
  <!-- Updating: -->
  <button @click="velocity++">Boost</button>
</div>
```

#### HTMX (Hypermedia Event)
```html
<!-- State lives on server; client requests updated HTML -->
<button hx-post="/api/velocity/increment" hx-target="#metric-box">
  Boost
</button>
```

---

### 2. Computed / Derived State

#### React
```jsx
const throughput = useMemo(() => (velocity * 482).toLocaleString(), [velocity]);
```

#### Vue 3
```js
const throughput = computed(() => (velocity.value * 482).toLocaleString());
```

#### Svelte 5
```js
let throughput = $derived((velocity * 482).toLocaleString());
```

#### SolidJS
```jsx
const throughput = createMemo(() => (velocity() * 482).toLocaleString());
```

#### Alpine.js
```js
Alpine.data('dashboard', () => ({
  velocity: 6,
  get throughput() {
    return (this.velocity * 482).toLocaleString();
  }
}));
```

---

### 3. Rendering Lists & Key Tracking

#### React
```jsx
{items.map(item => (
  <div key={item.id} className="data-item">
    {item.name}
  </div>
))}
```

#### Vue 3
```html
<div v-for="item in items" :key="item.id" class="data-item">
  {{ item.name }}
</div>
```

#### Svelte 5
```svelte
{#each items as item (item.id)}
  <div class="data-item">
    {item.name}
  </div>
{/each}
```

#### SolidJS
```jsx
<For each={items()}>
  {(item) => (
    <div class="data-item">
      {item.name}
    </div>
  )}
</For>
```

#### Alpine.js
```html
<template x-for="item in items" :key="item.id">
  <div class="data-item" x-text="item.name"></div>
</template>
```

#### HTMX
```html
<!-- Server renders HTML list and swaps container -->
<div id="services-container" hx-get="/api/services" hx-trigger="load"></div>
```

---

### 4. Two-Way Form Binding

#### React (Controlled Input)
```jsx
<input
  type="text"
  value={searchTerm}
  onChange={(e) => setSearchTerm(e.target.value)}
/>
```

#### Vue 3
```html
<input v-model="searchTerm" type="text" />
```

#### Svelte 5
```svelte
<input bind:value={searchTerm} type="text" />
```

#### SolidJS
```jsx
<input
  type="text"
  value={searchTerm()}
  onInput={(e) => setSearchTerm(e.target.value)}
/>
```

#### Alpine.js
```html
<input x-model="searchTerm" type="text" />
```

#### HTMX (Search-as-you-type)
```html
<input
  type="text"
  name="search"
  hx-get="/api/services"
  hx-trigger="keyup changed delay:250ms, search"
  hx-target="#services-container"
/>
```

---

## 🏗️ Architecture Breakdown

1. **React**: Executes component function on every state change. Rebuilds virtual DOM tree, diffs with previous tree, updates dirty nodes.
2. **Vue 3**: Components compile with dynamic slot flags and block trees. When reactive properties change, the component re-renders, but only dirty bindings are checked.
3. **Svelte 5**: Zero virtual DOM. Code is compiled ahead-of-time into micro-effects that surgically set `node.textContent = ...` or `element.classList.toggle(...)`.
4. **SolidJS**: Components run once to establish bindings. Signals hold direct references to DOM nodes. Zero virtual DOM overhead.
5. **Alpine.js**: Mutation observer scans DOM for `x-` directives and wires Alpine's reactivity engine directly into real DOM elements.
6. **HTMX**: No client state machinery. Server handles all business logic, rendering, and validation, returning concise HTML fragments that replace DOM slices.
