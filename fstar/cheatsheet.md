# F* Learning Cheat Sheet ✨

## 🛠 Essential Commands

| Command | Description |
| :--- | :--- |
| `fstar.exe main.fst` | Verify and run. |

## 🏗 Advanced Concepts

- **[Proof Engineering](./advanced/Proof.fst)**: Refinement types and automated verification.

## 💡 Quick Tips

### 1. Refinement Types
`x:int{x > 0}` - A type for positive integers.

### 2. Verification
F* uses Z3 to prove that your code satisfies its specifications at compile-time.
