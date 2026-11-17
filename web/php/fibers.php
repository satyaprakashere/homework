<?php

declare(strict_types=1);

/**
 * Modern PHP Concurrency: Cooperative Multitasking with Fibers (PHP 8.1+)
 * Run: php fibers.php
 */

echo "=== PHP Fibers (Cooperative Multitasking) ===\n\n";

// 1. Basic Fiber Lifecycle & Bidirectional Data Passing
$fiber = new Fiber(function (string $initMessage): void {
    echo "  [Fiber] Started with message: '$initMessage'\n";
    $input = Fiber::suspend("Need additional data");
    echo "  [Fiber] Resumed with input: '$input'\n";
    Fiber::suspend("Final step reached");
    echo "  [Fiber] Terminating cleanly\n";
});

echo "1. Single Fiber Step-by-Step:\n";
$status1 = $fiber->start("Worker 1 initialized");
echo "  [Main]  Fiber yielded: '$status1'\n";

$status2 = $fiber->resume("Credentials verified");
echo "  [Main]  Fiber yielded: '$status2'\n";

$fiber->resume();
echo "  [Main]  Fiber is terminated: " . ($fiber->isTerminated() ? "Yes" : "No") . "\n\n";

// 2. Cooperative Task Scheduler
class Scheduler {
    /** @var \Fiber[] */
    private array $queue = [];

    public function enqueue(\Fiber $fiber): void {
        $this->queue[] = $fiber;
    }

    public function run(): void {
        echo "2. Cooperative Scheduler Running Concurrent Tasks:\n";
        while (!empty($this->queue)) {
            $fiber = array_shift($this->queue);

            if (!$fiber->isStarted()) {
                $fiber->start();
            } elseif ($fiber->isSuspended()) {
                $fiber->resume();
            }

            // If task is still not terminated, put it back at the end of the queue
            if (!$fiber->isTerminated()) {
                $this->queue[] = $fiber;
            }
        }
        echo "  All scheduled fibers completed!\n";
    }
}

// Simulating two long-running cooperative tasks
function makeTask(string $taskName, int $steps): \Fiber {
    return new Fiber(function () use ($taskName, $steps): void {
        for ($i = 1; $i <= $steps; $i++) {
            echo "  [$taskName] working on step $i / $steps...\n";
            Fiber::suspend(); // Yield control back to scheduler
        }
        echo "  [$taskName] finished!\n";
    });
}

$scheduler = new Scheduler();
$scheduler->enqueue(makeTask("Task-Alpha", 3));
$scheduler->enqueue(makeTask("Task-Beta", 4));
$scheduler->enqueue(makeTask("Task-Gamma", 2));

$scheduler->run();
