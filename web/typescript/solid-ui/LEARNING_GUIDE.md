# 💙 SolidJS UI Design & Development Guide

## 1. Core Mental Model: Components Run Once!
In React, when state changes, the component function executes over and over.
In SolidJS:
* **The component function runs ONCE** during initialization to set up the reactive graph and create DOM nodes.
* Future signal changes **NEVER re-execute the component body**! Only the specific fine-grained listeners attached to signals re-run.
* **Golden Rule**: Never destructure `props` (e.g. `const { theme } = props`), because accessing `props.theme` is a getter that tracks reactivity!

---

## 2. Essential Signals & Primitives

### `createSignal(initialValue)`
Returns a `[getter, setter]` tuple:
```tsx
const [velocity, setVelocity] = createSignal<number>(65);
// Read (always call as a function!):
console.log(velocity());
// Write:
setVelocity(80);
```

### `createMemo(() => ...)`
A cached derived calculation:
```tsx
const throughput = createMemo(() => velocity() * 142);
```

### `createEffect(() => ...)`
Automatically tracks signals accessed inside it and runs side effects:
```tsx
createEffect(() => {
  document.documentElement.setAttribute('data-theme', theme());
});
```

---

## 3. Control Flow Components
Instead of JavaScript ternaries or `.map()`, Solid provides optimized control flow components:
* `<Show when={isOpen()} fallback={...}>`: Mounts/unmounts DOM nodes without re-evaluating unchanged content.
* `<For each={items()}>`: Highly optimized list reconciler that reuses real DOM nodes when items change position.

---

## 4. How to Run
```bash
bun install
bun run dev
```
Open `http://localhost:5173` in your browser.
