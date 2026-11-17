# 🔥 Svelte 5 UI Studio (Pure JavaScript)

An interactive, dark-glassmorphic UI component studio built with **Svelte 5** and **Vite**, using **100% Pure JavaScript Runes** with zero TypeScript dependencies and zero Virtual DOM.

## 🚀 Quick Start

```bash
# Run with Bun (instant)
bun install
bun run dev

# Or with npm
npm install
npm run dev
```

## 🧠 Core Svelte 5 UI Design Concepts

1. **Runes**: Universal reactivity symbols introduced in Svelte 5:
   - `$state(val)`: Declares reactive state.
   - `$derived(expr)`: Declares computed reactive state.
   - `$effect(() => ...)`: Runs side-effects when dependencies change.
   - `$props()`: Declares component props (replaces `export let`).
   - `$bindable()`: Marks props that can be two-way bound with `bind:prop`.
2. **Compiler-First Architecture**: Svelte compiles components to tiny surgical JS instructions that directly modify DOM text nodes and attributes without comparing virtual DOM trees.
3. **Scoped CSS by Default**: In Svelte components, `<style>` blocks are scoped strictly to the component elements at compile time.
