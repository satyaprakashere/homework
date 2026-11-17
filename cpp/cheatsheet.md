# C++ Learning Cheat Sheet 🚀

## 🛠 Essential Commands

| Command | Description |
| :--- | :--- |
| `g++ -std=c++20 main.cpp -o app` | Compile with C++20. |
| `cmake . && make` | Build with CMake. |
| `gdb ./app` | Debug with GDB. |
| `valgrind ./app` | Check for memory leaks. |

## 🏗 Language Features

### Basic Features
- **Pointers & References**: Memory addresses and aliases.
- **STL Containers**: `std::vector`, `std::map`, `std::string`.
- **Classes & OOP**: Encapsulation, Inheritance, Polymorphism.
- **I/O Streams**: `std::cin` and `std::cout`.
- **Namespaces**: Avoiding name collisions with `namespace`.

### Advanced Features
- **[Templates](./advanced/templates.hpp)**: Variadic templates and Metaprogramming.
- **[Smart Pointers](./advanced/smart_pointers.hpp)**: `unique_ptr`, `shared_ptr` (RAII).
- **Move Semantics**: `std::move` and Rvalue references for efficiency.
- **Lambdas**: Anonymous functions with captures.
- **Concepts (C++20)**: Constraints on template parameters.
- **Standard Library Algorithms**: `std::sort`, `std::find`, `std::transform`.

## 💡 Quick Tips

### 1. RAII
Resource Acquisition Is Initialization: Tie resource lifetime (memory, files) to object lifetime.

### 2. Standard Library
Prefer STL containers and algorithms over manual pointer manipulation.

### 3. Move Semantics
Use `std::move` to avoid expensive copies of large objects.
