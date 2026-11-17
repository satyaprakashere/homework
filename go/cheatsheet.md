# Go Learning Cheat Sheet 🚀

## 🛠 Essential Commands

| Command | Description |
| :--- | :--- |
| `go mod init <name>` | Initialize a new module. |
| `go run .` | Run the current package. |
| `go build` | Compile the current package. |
| `go test ./...` | Run all tests in the project. |
| `go mod tidy` | Add missing and remove unused modules. |

## 🏗 Language Features

### Basic Features
- **Pointers**: Memory addresses with `*` and `&`.
- **Slices**: Dynamically-sized arrays: `s := []int{1, 2}`.
- **Maps**: Key-value pairs: `m := make(map[string]int)`.
- **Structs**: Custom data types: `type User struct { ... }`.
- **Methods**: Functions with a receiver: `func (u User) Greet() { ... }`.

### Advanced Features
- **[Goroutines](./advanced/workerpool.go)**: Lightweight threads with `go func()`.
- **Channels**: Synchronous communication between goroutines.
- **[Interfaces](./advanced/di.go)**: Implicit satisfaction for decoupling.
- **[Generics](./advanced/generics.go)**: Reusable code with `[T any]`.
- **[Context](./advanced/workerpool.go)**: Deadlines and cancellation signals.
- **[Functional Options](./advanced/options.go)**: Clean configuration pattern.

## 💡 Quick Tips

### 1. Error Handling
Go uses explicit error returns: `if err != nil { return err }`.

### 2. Defer
`defer f.Close()` - Ensures cleanup happens at function exit.

### 3. Composition over Inheritance
Use struct embedding to share behavior.
