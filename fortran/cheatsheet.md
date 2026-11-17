# Fortran Learning Cheat Sheet 🔢

## 🛠 Essential Commands

| Command | Description |
| :--- | :--- |
| `gfortran main.f90 -o app` | Compile. |
| `fpm run` | Use Fortran Package Manager. |

## 🏗 Advanced Concepts

- **[Arrays](./advanced/arrays.f90)**: Slicing and dynamic allocation.

## 💡 Quick Tips

### 1. 1-Based Indexing
By default, Fortran arrays start at index 1.

### 2. Implicit None
Always use `implicit none` to avoid accidental variable declarations.

### 3. Column-Major
Fortran stores arrays in column-major order (opposite of C).
