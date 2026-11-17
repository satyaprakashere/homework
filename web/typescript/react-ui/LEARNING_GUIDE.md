# ⚛️ React UI Design & Development Guide

## 1. Core Mental Model
In React, **UI is a function of State**:
$$\text{UI} = f(\text{State})$$

Instead of manually modifying DOM nodes with `document.querySelector`, you declare what the UI should look like for any given state. When state changes, React recalculates the virtual DOM tree, computes a minimal diff, and updates the real DOM.

---

## 2. Essential Hooks for UI Design

### `useState`
Primary primitive for reactive component data:
```tsx
const [isOpen, setIsOpen] = useState<boolean>(false);
```

### `useMemo`
Caches expensive calculations or derived UI values between renders:
```tsx
const throughput = useMemo(() => velocity * 142, [velocity]);
```

### `useEffect`
Handles side effects that synchronize with outside systems (DOM attributes, event listeners, API requests):
```tsx
useEffect(() => {
  document.documentElement.setAttribute('data-theme', theme);
}, [theme]);
```

---

## 3. UI Patterns Used in this Project
1. **Glassmorphism Design System**: Modern CSS variables with translucent cards, subtle gradients, and backdrop blur.
2. **Controlled Form Elements**: Two-way data binding via `value={state}` and `onChange={(e) => setState(e.target.value)}`.
3. **Portal & Overlay Pattern**: Clean modal dialogs with escape-key shortcuts and click-outside dismissal.
4. **State Lifting**: Parent (`App.tsx`) coordinates shared state across `MetricCard`, `InteractiveControls`, and `StateInspector`.

---

## 4. How to Run
```bash
bun install
bun run dev
```
Open `http://localhost:5173` in your browser.
