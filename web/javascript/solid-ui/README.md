# 🔵 SolidJS UI Studio (Pure JavaScript)

An interactive, dark-glassmorphic UI component studio built with **SolidJS** and **Vite**, using **100% Pure JavaScript Signals** with zero TypeScript dependencies and zero Virtual DOM.

## 🚀 Quick Start

```bash
# Run with Bun (instant)
bun install
bun run dev

# Or with npm
npm install
npm run dev
```

## 🧠 Core SolidJS UI Design Concepts

1. **Fine-Grained Signals**:
   - `createSignal(initial)`: Returns `[getter, setter]`. Reading `count()` subscribes the current reactive context.
   - `createMemo(() => ...)`: Computes a cached reactive derived value.
   - `createEffect(() => ...)`: Side-effect tracking reactive values.
2. **Components Run Once**: Unlike React which re-runs component functions on every render cycle, Solid components run only once at initial setup. Updates are routed directly to specific DOM elements via subscriber closures.
3. **Reactive Control Flow**:
   - `<Show when={...} fallback={...}>`: Conditional rendering without destroying state.
   - `<For each={...}>`: Keyless/keyed list mapping with item reuse.
