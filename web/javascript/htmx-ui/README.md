# ⚡ HTMX UI Studio (Hypermedia & Pure JavaScript)

An interactive, dark-glassmorphic UI dashboard powered by **HTMX 2.x** and **Pure JavaScript / Node / Bun**, demonstrating hypermedia-driven reactive UI design without client-side heavy frameworks.

## 🚀 Quick Start

```bash
# Run with Node or Bun (instant, zero installs needed!)
bun run dev
# or
node server.js
```
Then visit `http://localhost:3008` in your browser.

## 🧠 Core HTMX UI Design Concepts

1. **HATEOAS (Hypermedia as the Engine of Application State)**: Instead of sending JSON and having a client framework parse and rebuild HTML, the server sends small HTML fragments ready to be swapped directly into the DOM.
2. **`hx-get` / `hx-post`**: Allows *any* HTML element (not just `<form>` and `<a>`) to trigger network interactions.
3. **`hx-target`**: Specifies where the returned HTML should be injected (CSS selector, e.g. `#services-container`).
4. **`hx-swap`**: Dictates how content is inserted:
   - `outerHTML`: Replaces the element itself.
   - `innerHTML`: Replaces the children.
   - `afterbegin` / `beforeend`: Appends or prepends new items to lists.
5. **`hx-trigger` with modifiers**:
   - `keyup changed delay:250ms`: Instant search-as-you-type with debouncing.
   - `serviceAdded from:body`: Cross-component event messaging.
6. **`hx-indicator`**: Declarative loading states and spinners without managing boolean `isLoading` state in JS.
