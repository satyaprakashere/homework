# 💚 Vue 3 UI Studio (Pure JavaScript)

An interactive, dark-glassmorphic UI component studio built with **Vue 3** and **Vite**, using **100% Pure JavaScript Single File Components (`.vue`)** and the Composition API.

## 🚀 Quick Start

```bash
# Run with Bun (instant)
bun install
bun run dev

# Or with npm
npm install
npm run dev
```

## 🧠 Core Vue 3 UI Design Concepts

1. **Reactivity via Proxies**: `ref(initialValue)` wraps primitives in reactive getters/setters. Mutating `count.value++` automatically schedules DOM updates.
2. **Computed Properties**: `computed(() => ...)` caches derived state and automatically re-computes only when dependencies change.
3. **Template Directives**:
   - `v-model`: Two-way data binding on inputs and child components.
   - `v-for`: Efficient keyed list rendering.
   - `v-if` / `v-show`: Declarative DOM toggling.
   - `@event` and `:prop`: Idiomatic event listening and prop passing.
4. **Single-File Component (SFC)**: Bundles `<script setup>`, `<template>`, and `<style>` in one cohesive file.
