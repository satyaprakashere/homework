# Python Learning Cheat Sheet 🐍

## 🛠 Essential Commands

| Command | Description |
| :--- | :--- |
| `python -m venv venv` | Create a virtual environment. |
| `pip install <pkg>` | Install a package. |
| `pytest` | Run tests. |
| `black .` | Format code. |
| `mypy .` | Check types. |

## 🏗 Language Features

### Basic Features
- **Dynamic Typing**: Variables don't need explicit types.
- **Lists, Dicts, Sets**: Versatile built-in collections.
- **List Comprehensions**: `[x*2 for x in data if x > 0]`.
- **F-Strings**: `f"Value: {val:.2f}"`.
- **Exceptions**: `try...except...finally` for error handling.

### Advanced Features
- **[Decorators](file:///Users/prakash/Documents/homework/python/advanced/decorators.py)**: Modifying behavior of functions or classes.
- **[AsyncIO](file:///Users/prakash/Documents/homework/python/advanced/async_io.py)**: Concurrency using `async/await`.
- **[Advanced Typing](file:///Users/prakash/Documents/homework/python/advanced/typing_adv.py)**: Type hints, Generics, and Protocols.
- **Context Managers**: `with` statement for resource management.
- **Generators**: Lazy iterators using `yield`.
- **Metaprogramming**: Using `type()` or Metaclasses to customize class creation.

## 💡 Quick Tips

### 1. Zen of Python
Run `import this` in the REPL to see the guiding principles of Python.

### 2. Virtual Environments
Always use a venv to avoid polluting your global Python installation.

### 3. PEP 8
Follow the official style guide for clean, readable code.
