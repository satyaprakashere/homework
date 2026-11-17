# PHP Learning Cheat Sheet 🐘

A modern guide for PHP 8.1 - 8.5+ highlighting language fundamentals, object-oriented paradigms, concurrency with fibers, and full HTML web application patterns.

---

## 🛠 Essential Commands

| Command | Description |
| :--- | :--- |
| `php -S localhost:8000` | Start built-in development web server for HTML apps. |
| `php script.php` | Run a CLI script directly. |
| `php -l script.php` | Syntax check (lint) without running. |
| `php -a` | Interactive PHP shell (REPL). |
| `php -v` | Show installed PHP version and OPcache status. |
| `composer install` | Install Composer dependencies from `composer.json`. |
| `composer dump-autoload` | Regenerate autoloader files. |

---

## 🌐 Full HTML Web Applications

Run `php -S localhost:8000` from this directory to launch the interactive apps in your browser.

| Application | Entry File | Key Concepts Demonstrated |
| :--- | :--- | :--- |
| **Showcase Portal & Explorer** | **[index.php](file:///Users/prakash/Documents/homework/php/index.php)** | Central hub, telemetry inspection (Zend Engine, OPcache, memory limits), card navigation, dynamic in-browser source code viewer. |
| **Enterprise Analytics** | **[dashboard.php](file:///Users/prakash/Documents/homework/php/dashboard.php)** | Dynamic analytics dashboard, search/filter pipeline, sorting, PHP 8 Enums driving visual status badges, computed KPIs. |
| **Secure Form & Session Pipeline** | **[form_handling.php](file:///Users/prakash/Documents/homework/php/form_handling.php)** | Cryptographic CSRF defense via `hash_equals()`, sticky inputs, field-level validation error bags, flash notifications, session storage. |
| **Interactive Task Manager** | **[todos.php](file:///Users/prakash/Documents/homework/php/todos.php)** | Session-backed CRUD state machine, completion toggles, priority tags (`Urgent`, `Medium`, `Low`), and view filter tabs (`all`, `active`, `completed`). |
| **Component System & Sparklines** | **[components.php](file:///Users/prakash/Documents/homework/php/components.php)** | Component rendering functions in native PHP, dynamic SVG sparkline charts generated with pure PHP math, alert notifications. |

---

## 📂 CLI Language Architecture Examples

| File | Topic | Key Highlights |
| :--- | :--- | :--- |
| **[main.php](file:///Users/prakash/Documents/homework/php/main.php)** | Modern PHP Fundamentals | Named arguments, nullsafe operator `?->`, match expressions, first-class callables `strlen(...)`, short arrow functions. |
| **[collections.php](file:///Users/prakash/Documents/homework/php/collections.php)** | Collections & Arrays | Positional & keyed destructuring, array unpacking, functional pipelines (`array_reduce`, `array_filter`), PHP 8.4+ utilities (`array_find`, `array_find_key`, `array_any`, `array_all`). |
| **[oop.php](file:///Users/prakash/Documents/homework/php/oop.php)** | Modern OOP | Constructor property promotion, `readonly` classes, interfaces, traits, asymmetric visibility (`public private(set)`), property hooks. |
| **[enums.php](file:///Users/prakash/Documents/homework/php/enums.php)** | First-Class Enums | Pure enums, backed enums (`string`/`int`), enum methods, interface implementation, `tryFrom()`, and exhaustive `match` handling. |
| **[generators.php](file:///Users/prakash/Documents/homework/php/generators.php)** | Generators & Streaming | Infinite sequences (`yield`), delegation (`yield from`), memory benchmarking vs arrays, streaming data pipelines. |
| **[fibers.php](file:///Users/prakash/Documents/homework/php/fibers.php)** | Concurrency & Fibers | Cooperative multitasking with `Fiber` (coroutines), bidirectional data passing (`suspend`/`resume`), and an event loop scheduler. |
| **[advanced/Attributes.php](file:///Users/prakash/Documents/homework/php/advanced/Attributes.php)** | Attributes & Reflection | Native metadata attributes, target constraints, and dynamic reflection inspection for routing and validation. |
| **[advanced/property_hooks.php](file:///Users/prakash/Documents/homework/php/advanced/property_hooks.php)** | PHP 8.4+ Property Hooks | Virtual computed properties, backed properties with custom `get`/`set` hooks, input sanitization, and asymmetric visibility. |

---

## 💡 Modern Syntax Quick Reference

### 1. Property Hooks (PHP 8.4+)
```php
class User {
    // Virtual computed property
    public string $fullName {
        get => "{$this->firstName} {$this->lastName}";
    }

    // Backed property with validation in set hook
    public string $email {
        set => strtolower(trim($value));
    }
}
```

### 2. Asymmetric Visibility (PHP 8.4+)
```php
class Article {
    // Read publicly, mutate only internally
    public private(set) int $views = 0;

    public function recordView(): void {
        $this->views++;
    }
}
```

### 3. Constructor Promotion & Readonly Classes
```php
readonly class Point {
    public function __construct(
        public int $x,
        public int $y,
    ) {}
}
```

### 4. Nullsafe Operator & Null Coalescing
```php
$city = $user?->address?->city ?? 'Default City';
```

### 5. Pattern Matching Expression
```php
$message = match ($statusCode) {
    200, 201 => 'OK',
    400 => 'Bad Request',
    404 => 'Not Found',
    default => 'Unknown Status',
};
```

### 6. First-Class Callable Syntax
```php
$lengths = array_map(strlen(...), ['modern', 'php']);
```

### 7. Modern Type System
```php
// Union Types
function find(string|int $id): User|null { ... }

// Intersection Types
function process(Countable&Traversable $collection): void { ... }

// DNF (Disjunctive Normal Form) Types
function handle((A&B)|null $item): void { ... }
```
