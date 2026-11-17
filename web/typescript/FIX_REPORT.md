# TypeScript Check Report — `web/typescript`

**Date:** 2026-10-20
**Command:** `bun check .` (Bun 1.4.3)
**Result:** 486 errors → **0 type errors in 20 files across 8 projects** ✅

---

## Summary of issues & fixes

| # | Issue | Affected projects | Errors |
|---|-------|------------------|--------|
| 1 | Dependencies never installed (`bun install` not run) + missing `@types/bun` | react-ui, solid-ui, svelte-ui, vue-ui, fib.ts | ~193 cascades |
| 2 | `@webgpu/types` package conflicts with WebGPU types built into Bun 1.4's `lib.dom.d.ts` | typegpu (explicit), text-rendering (via canvaskit-wasm) | 111 |
| 3 | CSS side-effect imports had no type declarations (TS2882) | react-ui, solid-ui, svelte-ui | 3 |
| 4 | canvaskit-wasm 0.42 API change — old surface API no longer exists | text-rendering | 3 |
| 5 | typegpu 0.12.8 API change — `withVertex` chain removed | typegpu | 1 |
| 6 | Stale `// @ts-expect-error` directive (TS2578) | typegpu | 1 |

### Error counts by file (original run)

```
  111  ~/.bun/install/cache/links/@webgpu+types@0.1.74-.../dist/index.d.ts
   68  react-ui/src/App.tsx
   55  react-ui/src/components/InteractiveControls.tsx
   74  solid-ui/src/App.tsx
   49  solid-ui/src/components/InteractiveControls.tsx
   28  react-ui/src/components/MetricCard.tsx
   75  solid-ui/src/components/{MetricCard,ModalDialog}.tsx
  ...  react-ui/{ModalDialog,ThemeToggle}.tsx, solid-ui/{index.tsx,ThemeToggle}.tsx
    4  react-ui/src/main.tsx, solid-ui/src/index.tsx, svelte-ui/src/main.ts (CSS imports)
    3  text-rendering/src/main.ts, svelte-ui (CSS)
    1  typegpu/index.ts (stale @ts-expect-error)
    1  typegpu/src/index.ts (withVertex)
    1  fib.ts (missing @types/bun)
```

---

## 1. Missing dependencies

**Problem:** Several sub-projects had `package.json` deps but no `node_modules` — every framework import
(`react`, `solid-js`, `vue`, `svelte`, `vite`) failed to resolve, cascading into implicit `any` errors on
JSX props, hook returns, etc. Bun's own runtime types (`console`, `fetch`, `Bun`) were also missing for `fib.ts`.

**Fix:**
```sh
bun install --cwd=react-ui
bun install --cwd=solid-ui
bun install --cwd=svelte-ui
bun install --cwd=vue-ui
bun install --cwd=text-rendering
bun install --cwd=effects-ex
bun install --cwd=typegpu
bun add -d @types/bun   # discovered via nearest package.json boundary (workspace root)
```

This alone reduced 486 errors → 119.

---

## 2. `@webgpu/types` duplicate global declarations (111 errors, TS2300/TS2717/TS2403/TS2687)

**Problem:** Bun 1.4's bundled TypeScript `lib.dom.d.ts` now ships the WebGPU API types
(`GPUBuffer`, `GPUColor`, `viewFormats`, `GPU` global, …) natively. The standalone
`@webgpu/types@0.1.74` package re-declares all of those identifiers globally, producing
duplicates on every load.

### a) typegpu — explicit loading via tsconfig

`typegpu/tsconfig.json` had `"types": ["@webgpu/types"]`, forcing the package in.

**Fix:** removed the entry, removed the devDependency, and deleted the stale
`typegpu/node_modules/@webgpu` symlink left by a previous install:

```diff
- "types": ["@webgpu/types"],
+ "types": [],
```
```diff
     "devDependencies": {
         "typescript": "^7.0.2",
-        "vite": "^8.3.4",
-        "@webgpu/types": "^0.1.74"
+        "vite": "^8.3.4"
```
```sh
rm -rf typegpu/node_modules/@webgpu
bun install --cwd=typegpu
```

### b) text-rendering — the sneaky transitive path

Even with `@webgpu/types` removed from `text-rendering/package.json`, errors persisted.
Root cause: **canvaskit-wasm itself** declares `@webgpu/types` as a real dependency and loads it
via a triple-slash reference inside its type definitions:

```ts
/// <reference types="@webgpu/types" />
```

Since Bun's checker doesn't apply `skipLibCheck` to these duplicate-identifier errors, the
only reliable stop is to redirect that reference through tsconfig `paths` to an empty stub
(WebGPU globals then come from `lib.dom.d.ts`).

**Fix files:**

`text-rendering/tsconfig.json`:
```json
{
  "compilerOptions": {
    "target": "ESNext",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "lib": ["dom", "esnext"],
    "strict": true,
    "skipLibCheck": true,
    "types": ["canvaskit-wasm"],
    "paths": {
      "@webgpu/types": ["./stubs/webgpu-types-stub.d.ts"]
    }
  }
}
```

`text-rendering/stubs/webgpu-types-stub.d.ts` (new file):
```ts
// Stub: WebGPU ambient types are provided by the TypeScript lib.dom.
// This keeps canvaskit-wasm's `/// <reference types="@webgpu/types" />`
// from loading the standalone @webgpu/types package, which conflicts with
// the WebGPU types built into lib.dom.d.ts under Bun 1.4+.
export {};
```

Also cleaned up the same fight's earlier hacks in `text-rendering/package.json` — removed the
non-standard `"compilerOptions"` block and the now-pointless `"overrides": { "@webgpu/types": "0.1.74" }`.

---

## 3. CSS side-effect imports (TS2882)

**Problem:** `import './index.css'` failed with
`Cannot find module or type declarations for side-effect import of './index.css'` in
`react-ui/src/main.tsx`, `solid-ui/src/index.tsx`, `svelte-ui/src/main.ts`.

**Fix:** added the standard Vite scaffold file to each project:

`src/vite-env.d.ts` (react-ui, solid-ui, svelte-ui):
```ts
/// <reference types="vite/client" />
```
(Vite's client types declare `*.css` and other asset modules.)

---

## 4. canvaskit-wasm 0.42 API change (text-rendering/src/main.ts)

**Problem:** The old surface API is gone in 0.42 — `MakeGPUCanvasSurface(GPUDevice, canvas)`
and `Surface.draw(cb)` no longer exist. The current API requires a device context and a
canvas context, and frames go through `requestAnimationFrame` on the WebGPU canvas context.

**Before:**
```ts
const surface = CK.MakeGPUCanvasSurface(device, canvasElement);
renderWithCustomFont(CK, surface!, fontBuffer);

function renderWithCustomFont(CK: CanvasKit, surface: Surface, fontData: ArrayBuffer) {
  using typeface = disposable(CK.Typeface.MakeFreeTypeFaceFromData(fontData)!);
  surface.draw((canvas) => { /* ... */ });
}
```

**After:**
```ts
const deviceContext = CK.MakeGPUDeviceContext(device)!;
const gpuCanvasContext = CK.MakeGPUCanvasContext(deviceContext, canvasElement)!;
renderWithCustomFont(CK, gpuCanvasContext, fontBuffer);

function renderWithCustomFont(CK: CanvasKit, gpuContext: WebGPUCanvasContext, fontData: ArrayBuffer) {
  using typeface = disposable(CK.Typeface.MakeFreeTypeFaceFromData(fontData)!);
  gpuContext.requestAnimationFrame((canvas) => { /* ... */ });
}
```

Import updated too: `Surface`/`Typeface` imports dropped, `WebGPUCanvasContext` added:

```diff
- import CanvasKitInit, { CanvasKit, Surface, Typeface } from 'canvaskit-wasm';
+ import CanvasKitInit, { CanvasKit, WebGPUCanvasContext } from 'canvaskit-wasm';
```

---

## 5. typegpu 0.12.8 API change (typegpu/src/index.ts)

**Problem:** `root['~unstable']` in typegpu 0.12.8 is a `Pick<ExperimentalTgpuRoot, ...>` that no
longer exposes render-pipeline builders, so `.withVertex(...)` (TS2339) — and the whole
builder-chain pattern — is gone.

**Before:**
```ts
const voronoiPipeline = root['~unstable']
  .withVertex(fullScreenTriangle, {})
  .withFragment(voronoiFrag, { format: presentationFormat })
  .createPipeline();
```

**After (stable 0.12 API, `root.createRenderPipeline`):**
```ts
const voronoiPipeline = root.createRenderPipeline({
  vertex: fullScreenTriangle,
  fragment: voronoiFrag,
  targets: { format: presentationFormat },   // single object, NOT an array
});
```

Note: `targets` takes a **single `TgpuColorTargetState`** object (`format` optional; defaults to
`navigator.gpu.getPreferredCanvasFormat()`), not a WebGPU-style array. The existing
`.with(bindGroup).withColorAttachment(...).draw(3)` usage needed no changes.

---

## 6. Stale `@ts-expect-error` (typegpu/index.ts:69)

**Problem:** TS2578 `Unused '@ts-expect-error' directive` — the dynamic
`import('./src/index.ts')` no longer errors once `moduleResolution: "bundler"` +
`allowImportingTsExtensions` were set (part of the project's in-progress migration).

**Fix:**
```diff
 // Execute example
-// @ts-expect-error
 const example = await import('./src/index.ts');
```

---

## Notes & follow-ups

- Your uncommitted WIP edits in `text-rendering`/`typegpu` were already partially attempting
  fix #2 — this work kept the good parts (removing `@webgpu/types` types/deps, `bundler`
  moduleResolution) and replaced the approach (suppression flags / `overrides`) with a
  resolution-level fix (stub + `paths`).
- All changes were made in place; the affected projects' `build` scripts (`tsc && vite build`)
  share the same tsconfigs, so they benefit from the same fixes.
- To re-check the whole workspace: `bun check .` — or one project at a time:
  `bun check -p <project>/tsconfig.json`.
- If a future Bun/TS update changes `lib.dom` WebGPU coverage, the text-rendering stub path
  (`text-rendering/stubs/webgpu-types-stub.d.ts`) is the single place to revisit.
