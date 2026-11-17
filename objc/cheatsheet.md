# Objective-C Learning Cheat Sheet 🍎

## 🛠 Essential Commands

| Command | Description |
| :--- | :--- |
| `clang -framework Foundation main.m -o app` | Compile. |

## 🏗 Advanced Concepts

- **[Blocks](../obj-c/advanced/blocks.m)**: Inline closures and callbacks.

## 💡 Quick Tips

### 1. ARC
Automatic Reference Counting manages memory.

### 2. Message Passing
`[object method:argument]` - Instead of `object.method(argument)`.

### 3. Categories
Extend existing classes without subclassing: `@interface NSString (MyCategory)`
