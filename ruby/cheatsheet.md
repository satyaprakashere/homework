# Ruby Learning Cheat Sheet 💎

## 🛠 Essential Commands

| Command | Description |
| :--- | :--- |
| `ruby main.rb` | Run a script. |
| `irb` | Start interactive Ruby shell. |
| `bundle install` | Install gems from Gemfile. |
| `rake` | Run tasks. |

## 📚 Basics Examples

| Topic | File | Description |
| :--- | :--- | :--- |
| **Variables & Types** | [variables_and_types.rb](./basics/variables_and_types.rb) | Primitives, symbols, dynamic typing, strings, and constants |
| **Control Flow** | [control_flow.rb](./basics/control_flow.rb) | `if/else`, `unless`, `case/when`, loops, and pattern matching |
| **Arrays & Hashes** | [arrays_and_hashes.rb](./basics/arrays_and_hashes.rb) | Array indexing, slices, transformations, and hash operations |
| **Methods** | [methods.rb](./basics/methods.rb) | Default, keyword, splat (`*args`), and double splat (`**kwargs`) |
| **Blocks, Procs & Lambdas** | [blocks_procs_lambdas.rb](./basics/blocks_procs_lambdas.rb) | `yield`, `Proc.new`, lambdas, closures, and `&block` |
| **Enumerable** | [enumerable.rb](./basics/enumerable.rb) | `map`, `select`, `reject`, `reduce`, `group_by`, `all?`, `any?` |
| **Classes & OOP** | [classes_and_oop.rb](./basics/classes_and_oop.rb) | Classes, instance/class variables, inheritance, and access control |
| **Modules & Mixins** | [modules_and_mixins.rb](./basics/modules_and_mixins.rb) | Namespacing, `include`, `extend`, and module composition |
| **Error Handling** | [error_handling.rb](./basics/error_handling.rb) | `begin/rescue/ensure`, custom exceptions, and retry patterns |

## 🚀 Advanced Examples

| Topic | File | Description |
| :--- | :--- | :--- |
| **Metaprogramming** | [metaprogramming.rb](./advanced/metaprogramming.rb) | `send`, `define_method`, `method_missing`, `instance_eval`, hooks |
| **DSL Design** | [dsl_design.rb](./advanced/dsl_design.rb) | Declarative DSLs with `instance_eval`, chaining, Sinatra-style routes, XML/HTML builder |
| **Concurrency & Parallelism** | [concurrency_and_parallelism.rb](./advanced/concurrency_and_parallelism.rb) | Multi-threading, `Mutex`, thread-safe `Queue`, `Fiber` coroutines, and `Ractor` multi-core execution |
| **Object Model & Singletons** | [object_model_and_singleton_classes.rb](./advanced/object_model_and_singleton_classes.rb) | Eigenclasses (`class << self`), `prepend` vs `include` lookup chain, and metaclass inheritance |
| **Refinements** | [refinements_and_monkey_patching.rb](./advanced/refinements_and_monkey_patching.rb) | Lexically scoped class extensions (`refine` / `using`) avoiding global monkey-patch collisions |
| **Delegation & Patterns** | [delegation_and_patterns.rb](./advanced/delegation_and_patterns.rb) | `Forwardable`, `SimpleDelegator` decorators, method objects, and PubSub event buses |
| **Lazy Enumerators & Streams** | [lazy_enumerators_and_fibers.rb](./advanced/lazy_enumerators_and_fibers.rb) | Custom `Enumerator`, external iteration, infinite streams with `.lazy`, and Fiber coroutine pipelines |

## 💡 Quick Tips

### 1. The Ruby Way
Follow "Matz's principle" of minimizing programmer frustration. Use idiomatic methods like `map`, `select`, `reduce`.

### 2. Gems
Use RubyGems for package management. `bundle exec <command>` ensures gem versions stay consistent with your `Gemfile.lock`.

### 3. Ruby 3+ Features
Take advantage of modern Ruby features: pattern matching (`case in`), Ractors for CPU parallelism, and Fiber schedulers for high-throughput non-blocking IO.
