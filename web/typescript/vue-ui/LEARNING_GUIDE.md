# 🟢 Vue 3 UI Design & Development Guide

## 1. Core Mental Model: Single File Components (SFC)
Vue structures components into three distinct blocks in a single `.vue` file:
1. `<script setup lang="ts">`: Component logic, reactive variables, and life-cycle hooks.
2. `<template>`: HTML structure with reactive directives (`v-if`, `v-for`, `v-model`, `@click`, `:class`).
3. `<style scoped>`: Optional CSS styles isolated specifically to this component.

---

## 2. Essential Composition API Primitives

### `ref(initialValue)`
Creates a reactive proxy wrapper around primitive or object values:
```ts
const velocity = ref(65);
// Mutate in script:
velocity.value = 80;
// In template, .value is automatically unwrapped:
// <span>{{ velocity }}</span>
```

### `computed(() => ...)`
Creates an auto-cached derived reactive value that only re-evaluates when its dependencies mutate:
```ts
const throughput = computed(() => velocity.value * 142);
```

### `watchEffect(() => ...)`
Automatically runs a callback and re-runs it whenever any reactive dependency used inside changes:
```ts
watchEffect(() => {
  document.documentElement.setAttribute('data-theme', theme.value);
});
```

---

## 3. UI Directives Used in this Project
* `:value` and `@input`: Explicit one-way data binding and event listening.
* `v-for="cat in categories"`: Iterating lists with unique `:key`.
* `:class="{ active: activeCategory === cat }"`: Declarative conditional CSS classes.
* `v-if="isOpen"`: Conditional mounting/unmounting of DOM elements (e.g. Modals).
* `<slot />`: Content distribution allowing parent components to pass template markup inside children.

---

## 4. How to Run
```bash
bun install
bun run dev
```
Open `http://localhost:5173` in your browser.
