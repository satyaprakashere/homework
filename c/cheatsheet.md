# C Learning Cheat Sheet 🧊

## 🛠 Essential Commands

| Command | Description |
| :--- | :--- |
| `gcc main.c -o app` | Compile a C file. |
| `make` | Build with Makefile. |
| `gdb ./app` | Debug with GDB. |

## 🏗 Advanced Concepts

- **[Pointers](file:///Users/prakash/Documents/homework/c/advanced/pointers.c)**: Function pointers and memory addresses.

## 💡 Quick Tips

### 1. Manual Memory Management
Use `malloc()` to allocate and `free()` to release. Always check for NULL.

### 2. Header Guards
Use `#ifndef HEADER_H` to prevent multiple inclusions.

### 3. Structs
`typedef struct { int x; int y; } Point;`
