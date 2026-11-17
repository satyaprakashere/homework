# 🔥 Svelte 5 UI Design & Development Guide

## 1. Core Mental Model: Compiler-Driven UI
Svelte shifts the work from runtime in the browser to the compile step at build time:
* **No Virtual DOM**: Instead of diffing virtual tree snapshots, Svelte outputs microscopic JavaScript that directly mutates target DOM elements.
* **Runes**: Starting in Svelte 5, reactivity uses universal runes (prefixed with `$`) that work inside `.svelte` files and standard `.svelte.ts` utility files.

---

## 2. Essential Svelte 5 Runes

### `$state(initialValue)`
Declares deeply reactive state:
```ts
let velocity = $state(65);
// Direct assignment triggers UI update:
velocity = 80;
```

### `$derived(expression)` or `$derived.by(() => ...)`
Declares computed/derived reactive values:
```ts
let throughput = $derived(velocity * 142);
```

### `$props()`
Type-safe props declaration with destructuring:
```ts
interface Props {
  theme: 'dark' | 'light';
  ontoggle: () => void;
}
let { theme, ontoggle }: Props = $props();
```

### `$effect(() => ...)`
Runs side effects when reactive values change:
```ts
$effect(() => {
  document.documentElement.setAttribute('data-theme', theme);
});
```

---

## 3. UI Patterns Used in this Project
* **Shorthand Attributes & Styles**: `style:width={`${progress}%`}` and `class:active={isActive}` provide clean inline style manipulation.
* **Snippets**: Replaces legacy `<slot>` with first-class renderable snippets `{#snippet}` and `{@render children()}`.
* **Direct DOM Windows**: `<svelte:window onkeydown={...}>` cleanly registers and cleans up window-level keyboard events.

---

## 4. How to Run
```bash
bun install
bun run dev
```
Open `http://localhost:5173` in your browser.
