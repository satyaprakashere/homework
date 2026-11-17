<?php

declare(strict_types=1);

/**
 * Modern PHP Collections & Array Primitives
 * Run: php collections.php
 */

echo "=== Modern PHP Collections & Arrays ===\n\n";

// 1. Destructuring (Positional and Key-based)
$coordinates = [12.9716, 77.5946, 920]; // lat, lng, altitude
[$latitude, $longitude, $altitude] = $coordinates;
echo "1. Destructuring: lat=$latitude, lng=$longitude, alt={$altitude}m\n";

$book = ["title" => "Clean Code", "author" => "Robert C. Martin", "pages" => 464];
["title" => $title, "author" => $author] = $book;
echo "   Keyed Destructuring: '$title' by $author\n";

// 2. Spread / Unpacking Operator (...) with numerical & string keys
$frontend = ["html" => "semantic", "css" => "vanilla"];
$backend = ["php" => "8.5", "db" => "postgresql"];
$fullStack = ["server" => "caddy", ...$frontend, ...$backend];

echo "\n2. Array Unpacking (Spread):\n";
print_r($fullStack);

// 3. Functional Pipelines (filter, map, reduce)
$products = [
    ["id" => 1, "name" => "Mechanical Keyboard", "price" => 120, "inStock" => true],
    ["id" => 2, "name" => "Ergonomic Mouse",     "price" => 80,  "inStock" => false],
    ["id" => 3, "name" => "UltraWide Monitor",   "price" => 450, "inStock" => true],
    ["id" => 4, "name" => "USB-C Hub",           "price" => 40,  "inStock" => true],
];

// Get total value of in-stock items
$totalInventoryValue = array_reduce(
    array_filter($products, fn(array $item): bool => $item["inStock"]),
    fn(int $carry, array $item): int => $carry + $item["price"],
    0
);

echo "\n3. Functional Pipelines:\n";
echo "Total value of in-stock items: \${$totalInventoryValue}\n";

// 4. PHP 8.4+ Array Functions: array_find, array_find_key, array_any, array_all
echo "\n4. PHP 8.4+ Array Utilities:\n";

// array_find: returns first matching element or null
$firstBudgetGadget = array_find($products, fn(array $item): bool => $item["price"] < 50);
echo "First item under \$50: " . ($firstBudgetGadget["name"] ?? "None") . "\n";

// array_find_key: returns the index or key of first matching element
$expensiveIndex = array_find_key($products, fn(array $item): bool => $item["price"] > 400);
echo "Index of product > \$400: $expensiveIndex\n";

// array_any: check if any element meets the condition
$hasOutOfStock = array_any($products, fn(array $item): bool => !$item["inStock"]);
echo "Has out-of-stock items: " . ($hasOutOfStock ? "Yes" : "No") . "\n";

// array_all: check if all elements meet the condition
$allPositivePriced = array_all($products, fn(array $item): bool => $item["price"] > 0);
echo "All items have price > 0: " . ($allPositivePriced ? "Yes" : "No") . "\n";

// 5. Custom sorting with spaceship operator (<=>)
usort($products, fn(array $a, array $b): int => $b["price"] <=> $a["price"]);
echo "\n5. Sorted by price descending:\n";
foreach ($products as $p) {
    printf("  - %-22s: \$%d\n", $p["name"], $p["price"]);
}
