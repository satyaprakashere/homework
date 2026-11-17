# 🎨 Modern JS/TS UI Frameworks: Architectural & Design Comparison

Welcome! This workspace contains 4 standalone, production-ready educational projects designed to teach you modern UI design across the 4 most popular and influential JavaScript/TypeScript UI frameworks:

| Directory | Framework | Core Paradigm | Reactivity Model | DOM Strategy |
| :--- | :--- | :--- | :--- | :--- |
| [`react-ui/`](./react-ui) | **React 18/19** | Component Functions + JSX | Hooks (`useState`, `useMemo`) | Virtual DOM Reconciliation |
| [`vue-ui/`](./vue-ui) | **Vue 3** | Single File Components (`.vue`) | Proxies (`ref`, `reactive`, `computed`) | Optimized Virtual DOM with compiler hints |
| [`svelte-ui/`](./svelte-ui) | **Svelte 5** | Compiler-First Svelte Files | Runes (`$state`, `$derived`, `$props`) | Direct DOM surgically updated by compiler |
| [`solid-ui/`](./solid-ui) | **SolidJS** | Reactive JSX | Fine-grained Signals (`createSignal`, `createMemo`) | Direct DOM, components execute once only |

---

## ⚡ Quick Start: How to Run Any Showcase

Each project is completely self-contained with Vite. You can run any of them using `bun` or `npm`:

```bash
# Example for React:
cd react-ui
bun install   # or: npm install
bun run dev   # or: npm run dev

# Example for Vue 3:
cd vue-ui
bun install
bun run dev

# Example for Svelte 5:
cd svelte-ui
bun install
bun run dev

# Example for SolidJS:
cd solid-ui
bun install
bun run dev
```

---

## 🔍 Conceptual Side-by-Side Comparison

### 1. State Declaration
* **React**:
  ```tsx
  const [count, setCount] = useState<number>(0);
  // Update:
  setCount(c => c + 1);
  ```
* **Vue 3**:
  ```ts
  const count = ref<number>(0);
  // Update:
  count.value++;
  ```
* **Svelte 5**:
  ```ts
  let count = $state(0);
  // Update:
  count++;
  ```
* **SolidJS**:
  ```tsx
  const [count, setCount] = createSignal<number>(0);
  // Update:
  setCount(c => c + 1);
  // Read (getter function):
  console.log(count());
  ```

---

### 2. Computed / Derived State
* **React**:
  ```tsx
  const double = useMemo(() => count * 2, [count]);
  ```
* **Vue 3**:
  ```ts
  const double = computed(() => count.value * 2);
  ```
* **Svelte 5**:
  ```ts
  let double = $derived(count * 2);
  ```
* **SolidJS**:
  ```tsx
  const double = createMemo(() => count() * 2);
  ```

---

### 3. Conditional Rendering
* **React**:
  ```tsx
  {isVisible && <Card />}
  {status === 'active' ? <ActiveBadge /> : <InactiveBadge />}
  ```
* **Vue 3**:
  ```html
  <Card v-if="isVisible" />
  <ActiveBadge v-if="status === 'active'" />
  <InactiveBadge v-else />
  ```
* **Svelte 5**:
  ```svelte
  {#if isVisible}
    <Card />
  {/if}
  ```
* **SolidJS**:
  ```tsx
  <Show when={isVisible()} fallback={<EmptyState />}>
    <Card />
  </Show>
  ```

---

### 4. Rendering Loops & Lists
* **React**:
  ```tsx
  items.map(item => <Item key={item.id} data={item} />)
  ```
* **Vue 3**:
  ```html
  <Item v-for="item in items" :key="item.id" :data="item" />
  ```
* **Svelte 5**:
  ```svelte
  {#each items as item (item.id)}
    <Item data={item} />
  {/each}
  ```
* **SolidJS**:
  ```tsx
  <For each={items()}>
    {(item) => <Item data={item} />}
  </For>
  ```

---

## 🎯 Which One Should You Choose For Your Projects?

1. **Choose React** if you want the largest ecosystem, the most job opportunities, huge UI component libraries (shadcn/ui, Radix, Tailwind UI, MUI), and React Native cross-platform capabilities.
2. **Choose Vue** if you love clean separation of concerns, intuitive templating, world-class official documentation, and balanced flexibility with simplicity.
3. **Choose Svelte** if you want the cleanest code with the least boilerplate, built-in transitions, and ultra-lean compiled bundles without virtual DOM overhead.
4. **Choose SolidJS** if you love React's JSX paradigm but want lightning-fast performance, zero virtual DOM diffing, and predictable fine-grained reactivity.
