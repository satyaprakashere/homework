# Rekursion, Loki, HTML & CSS Examples

This directory contains standalone, single-file reference examples demonstrating the **Rekursion** programming language ecosystem, the **Loki** frontend syntax, and **HTML & CSS integration using the Rekursion VM**.

---

## Directory Index

| File | Language / Format | Description | Run Command |
| :--- | :--- | :--- | :--- |
| [`01_rekursion_basics.rek`](file:///Users/prakash/Documents/homework/rekursion/01_rekursion_basics.rek) | Rekursion Core | Pure functions, Gödel bounded recursion (`recur`), no math operators (`add`, `mul`), immutable `let`. | `./out/rekursion ~/Documents/homework/rekursion/01_rekursion_basics.rek` |
| [`02_rekursion_data_oriented_arrays.rek`](file:///Users/prakash/Documents/homework/rekursion/02_rekursion_data_oriented_arrays.rek) | Rekursion Core | Data-Oriented Programming (DOP) with contiguous arrays (`array_make`, `array_get`, `array_slice`). | `./out/rekursion ~/Documents/homework/rekursion/02_rekursion_data_oriented_arrays.rek` |
| [`03_rekursion_types_and_pattern_matching.rek`](file:///Users/prakash/Documents/homework/rekursion/03_rekursion_types_and_pattern_matching.rek) | Rekursion Core | PascalCase types (`record Point`, `variant Shape`), `match` and fallback `unless` with guards (`:when`). | `./out/rekursion ~/Documents/homework/rekursion/03_rekursion_types_and_pattern_matching.rek` |
| [`04_rekursion_godel_mu_minimization.rek`](file:///Users/prakash/Documents/homework/rekursion/04_rekursion_godel_mu_minimization.rek) | Rekursion Core | Kurt Gödel's $\mu$-operator (unbounded minimization), `bounded_search`, `forall_bounded`, `exists_bounded`. | `./out/rekursion ~/Documents/homework/rekursion/04_rekursion_godel_mu_minimization.rek` |
| [`05_rekursion_procedures_and_io.rek`](file:///Users/prakash/Documents/homework/rekursion/05_rekursion_procedures_and_io.rek) | Rekursion Core | Side-effecting `procedure` with sequential `let`, mutation optimization (`set_var`), and formatted I/O. | `./out/rekursion ~/Documents/homework/rekursion/05_rekursion_procedures_and_io.rek` |
| [`06_loki_fundamentals.loki`](file:///Users/prakash/Documents/homework/rekursion/06_loki_fundamentals.loki) | Loki Frontend | Bare top-level bindings, pure `function` definitions, arithmetic lowering, and console logging. | `./out/rekursion ~/Documents/homework/rekursion/06_loki_fundamentals.loki` |
| [`07_loki_tail_recursion_and_guards.loki`](file:///Users/prakash/Documents/homework/rekursion/07_loki_tail_recursion_and_guards.loki) | Loki Frontend | Bounded tail recursion with `recur(...)`, multi-case & single-line `unless` guards, fallback values. | `./out/rekursion ~/Documents/homework/rekursion/07_loki_tail_recursion_and_guards.loki` |
| [`08_loki_data_structures_and_records.loki`](file:///Users/prakash/Documents/homework/rekursion/08_loki_data_structures_and_records.loki) | Loki Frontend | Array literals `[...]`, Object dictionaries `{ ... }`, and `match` pattern matching expressions. | `./out/rekursion ~/Documents/homework/rekursion/08_loki_data_structures_and_records.loki` |
| [`09_loki_godel_minimization.loki`](file:///Users/prakash/Documents/homework/rekursion/09_loki_godel_minimization.loki) | Loki Frontend | Kurt Gödel $\mu$-operator minimization blocks in Loki syntax (`root = mu n { ... }`) finding inverses. | `./out/rekursion ~/Documents/homework/rekursion/09_loki_godel_minimization.loki` |
| [`10_server_rendered_page.rhtml`](file:///Users/prakash/Documents/homework/rekursion/10_server_rendered_page.rhtml) | Rekursion VM Web | Server-side templating combining HTML, CSS variables, and embedded `<server>` recursive VM blocks. | `./out/rekursion ~/Documents/homework/rekursion/10_server_rendered_page.rhtml` |
| [`11_dashboard_interactive.rhtml`](file:///Users/prakash/Documents/homework/rekursion/11_dashboard_interactive.rhtml) | Rekursion VM Web | Full single-file Web Dashboard application with dark theme CSS, responsive flex layout, and VM data logic. | `./out/rekursion ~/Documents/homework/rekursion/11_dashboard_interactive.rhtml` |
| [`12_microweb_spatial_component.html`](file:///Users/prakash/Documents/homework/rekursion/12_microweb_spatial_component.html) | MicroWeb HTML | Declarative UI for Rekursion's SoA DOM engine using `<row>`, `<col>`, `<spacer>`, and box attributes. | Parsed by `lang/html` |
| [`13_microweb_stylesheet.css`](file:///Users/prakash/Documents/homework/rekursion/13_microweb_stylesheet.css) | MicroWeb CSS | CSS Design System for Rekursion's cascade engine with CSS variables, nesting (`&`), and `px`/`py`. | Parsed by `lang/css` |
| [`14_microweb_ui_pipeline.rek`](file:///Users/prakash/Documents/homework/rekursion/14_microweb_ui_pipeline.rek) | Rekursion Core | Data-oriented UI tree pipeline: flat SoA DOM arena, tail-recursive layout solver, and HTML5 emitter. | `./out/rekursion ~/Documents/homework/rekursion/14_microweb_ui_pipeline.rek` |

---

## Architectural Highlights

### 1. Rekursion Core Rules (`.rek`)
- **Kurt Gödel Recursive Model**: General recursion is forbidden by default. Computation is driven by primitive bounded recursion (`recur`) and unbounded search (`mu`).
- **Data-Oriented Programming (DOP)**: Prefers contiguous arrays over linked lists for hardware cache locality (`array`, `array_make`, `array_get`, `array_slice`).
- **No Mathematical Operators**: Core syntax uses explicit names (`add`, `sub`, `mul`, `div`, `less_than`, `equal`).
- **Strict Distinction**: `function` for pure expressions, `procedure`/`proc` for state mutation and side-effects.

### 2. Loki Language (`.loki`)
- Modern functional syntax with JavaScript familiarity that lowers directly into canonical Rekursion S-expressions.
- Tail recursion via `recur(...)` and pattern matching guards via `unless` and `match`.
- Gödel minimization via `mu n { ... }`.

### 3. MicroWeb & Server-Side Templating (`.rhtml`, `.html`, `.css`)
- **`.rhtml` Templates**: Evaluated natively by `./out/rekursion <file.rhtml>`. Computes server-side data models and generates clean HTML+CSS without external runtimes.
- **MicroWeb Declarative UI**: First-class spatial primitives (`<row>`, `<col>`, `<spacer>`, `<stack>`) managed in flat Struct-of-Arrays (SoA) memory arenas.
- **MicroWeb CSS**: CSS variables, native rule nesting (`&`), and directional box shorthands (`px`, `py`).
