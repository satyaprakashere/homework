# ⚛️ React UI Studio (Pure JavaScript)

An interactive, dark-glassmorphic UI component studio built with **React 18** and **Vite**, using **100% Pure JavaScript (JSX)** with zero TypeScript dependencies.

## 🚀 Quick Start

```bash
# Run with Bun (recommended, instant)
bun install
bun run dev

# Or with npm
npm install
npm run dev
```

## 🧠 Core React UI Design Concepts

1. **Declarative UI**: Instead of mutating DOM elements directly, you describe what the UI should look like for any given state (`UI = f(state)`).
2. **Component Composition**: UI is broken down into small, reusable building blocks (`MetricCard`, `InteractiveControls`, `DataList`, `ModalDialog`).
3. **Controlled Inputs**: Form controls (`input`, `range`, `select`) mirror React state directly with `value={state}` and `onChange={(e) => setState(e.target.value)}`.
4. **State Lifting**: Sibling components communicate by lifting state to their common parent (`App.jsx`) and passing down updater callbacks.
5. **Virtual DOM Reconciliation**: When state changes, React recalculates the virtual DOM tree, computes diffs, and updates only the changed real DOM nodes.
