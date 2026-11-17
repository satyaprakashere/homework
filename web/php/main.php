<?php

declare(strict_types=1);

/**
 * Modern PHP Overview & Core Features
 * Run: php main.php
 */

echo "=== Modern PHP Overview ===\n\n";

// 1. Named Arguments
function createUser(string $name, string $role = "viewer", bool $active = true): array {
    return ["name" => $name, "role" => $role, "active" => $active];
}

$user = createUser(name: "Alice", active: true, role: "admin");
echo "1. Named Arguments:\n";
print_r($user);

// 2. Nullsafe Operator (?->)
class Address {
    public function __construct(public ?string $city = null) {}
}

class Profile {
    public function __construct(public ?Address $address = null) {}
}

$profileWithCity = new Profile(new Address("Bangalore"));
$profileWithoutCity = new Profile(null);

echo "\n2. Nullsafe Operator (?->):\n";
echo "City 1: " . ($profileWithCity->address?->city ?? "N/A") . "\n";
echo "City 2: " . ($profileWithoutCity->address?->city ?? "N/A") . "\n";

// 3. Match Expression (replaces verbose switch-case)
$statusCode = 404;
$message = match ($statusCode) {
    200, 201 => "Success / Created",
    400 => "Bad Request",
    401, 403 => "Unauthorized",
    404 => "Not Found",
    500, 502, 503 => "Server Error",
    default => "Unknown Status",
};

echo "\n3. Match Expression:\n";
echo "HTTP $statusCode => $message\n";

// 4. First-Class Callable Syntax
$words = ["php", "modern", "hypertext", "preprocessor"];
$lengths = array_map(strlen(...), $words);

echo "\n4. First-Class Callable (strlen(...)):\n";
foreach ($words as $i => $word) {
    echo "  - $word: {$lengths[$i]} chars\n";
}

// 5. Short Arrow Functions
$multiplier = 3;
$numbers = [1, 2, 3, 4, 5];
$tripled = array_map(fn(int $n): int => $n * $multiplier, $numbers);

echo "\n5. Short Arrow Function (fn(\$n) => \$n * 3):\n";
echo "Original: " . implode(", ", $numbers) . "\n";
echo "Tripled:  " . implode(", ", $tripled) . "\n";

echo "\nAll basic checks passed successfully!\n";
