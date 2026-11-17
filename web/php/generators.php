<?php

declare(strict_types=1);

/**
 * Modern PHP Generators: Memory-Efficient Iteration & Pipelines
 * Run: php generators.php
 */

echo "=== PHP Generators & Streaming ===\n\n";

// 1. Infinite Fibonacci Generator
function fibonacci(): \Generator {
    $a = 0;
    $b = 1;
    while (true) {
        yield $a;
        [$a, $b] = [$b, $a + $b];
    }
}

echo "1. First 10 Fibonacci Numbers from infinite generator:\n";
$count = 0;
foreach (fibonacci() as $n) {
    echo "$n ";
    if (++$count === 10) break;
}
echo "\n\n";

// 2. Memory Usage Comparison: Array vs Generator
function generateNumbersArray(int $limit): array {
    $data = [];
    for ($i = 0; $i < $limit; $i++) {
        $data[] = $i;
    }
    return $data;
}

function generateNumbersYield(int $limit): \Generator {
    for ($i = 0; $i < $limit; $i++) {
        yield $i;
    }
}

$limit = 100_000;

$memBeforeArray = memory_get_usage();
$array = generateNumbersArray($limit);
$memAfterArray = memory_get_usage();
$arrayMemKb = ($memAfterArray - $memBeforeArray) / 1024;
unset($array); // Free memory

$memBeforeGen = memory_get_usage();
$gen = generateNumbersYield($limit);
$memAfterGen = memory_get_usage();
$genMemKb = ($memAfterGen - $memBeforeGen) / 1024;

echo "2. Memory Comparison for generating " . number_format($limit) . " integers:\n";
printf("  - Array in memory:     %.2f KB\n", $arrayMemKb);
printf("  - Generator in memory: %.2f KB (~%dx more efficient)\n", $genMemKb, (int)($arrayMemKb / max($genMemKb, 0.01)));

// 3. Generator Delegation (yield from)
function chunkOne(): \Generator {
    yield "Header";
    yield "Intro";
}

function chunkTwo(): \Generator {
    yield "Body paragraph 1";
    yield "Body paragraph 2";
}

function fullDocument(): \Generator {
    yield from chunkOne();
    yield from chunkTwo();
    yield "Footer";
}

echo "\n3. Generator Delegation (yield from):\n";
foreach (fullDocument() as $line) {
    echo "  -> $line\n";
}

// 4. Generator Pipeline: Filtering & Transforming on the fly
function filterEven(iterable $stream): \Generator {
    foreach ($stream as $val) {
        if ($val % 2 === 0) {
            yield $val;
        }
    }
}

function squareStream(iterable $stream): \Generator {
    foreach ($stream as $val) {
        yield $val * $val;
    }
}

echo "\n4. Generator Pipeline (Filter Even -> Square):\n";
$pipeline = squareStream(filterEven(generateNumbersYield(10)));
foreach ($pipeline as $result) {
    echo "  $result\n";
}
