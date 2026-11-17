# 🏔️ Alpine.js UI Studio (Pure JavaScript)

An interactive, dark-glassmorphic UI component studio built with **Alpine.js 3**, using **100% Pure JavaScript Directives** directly embedded in the HTML markup.

## 🚀 Quick Start

```bash
# Run with Bun (instant)
bun install
bun run dev

# Or with npm
npm install
npm run dev
```

> **Zero-Build Option**: You can also open `index.html` directly in any web browser if you include Alpine via CDN `<script src="https://cdn.jsdelivr.net/npm/alpinejs@3.x.x/dist/cdn.min.js" defer></script>`.

## 🧠 Core Alpine.js UI Design Concepts

1. **`x-data`**: Defines a reactive component scope with standard JavaScript object properties and methods.
2. **`x-bind` (`:`)**: Reactively binds HTML attributes and dynamic style/classes.
3. **`x-on` (`@`)**: Listens to browser events (`@click`, `@input`, `@submit.prevent`).
4. **`x-model`**: Two-way data binding on inputs, checkboxes, sliders, and selects.
5. **`x-show` / `x-transition`**: Seamlessly toggles visibility with automatic CSS transitions.
6. **`x-for`**: Loops over arrays using standard HTML `<template>` tags.
