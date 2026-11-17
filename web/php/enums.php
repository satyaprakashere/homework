<?php

declare(strict_types=1);

/**
 * Modern PHP Enums: Pure, Backed, Methods, Interfaces & Exhaustive Matching
 * Run: php enums.php
 */

echo "=== Modern PHP Enums ===\n\n";

interface HasBadge {
    public function badgeColor(): string;
}

// 1. Backed Enum with Methods and Interface implementation
enum OrderStatus: string implements HasBadge {
    case Pending = "pending";
    case Processing = "processing";
    case Shipped = "shipped";
    case Delivered = "delivered";
    case Cancelled = "cancelled";

    public function badgeColor(): string {
        return match ($this) {
            self::Pending => "yellow",
            self::Processing => "blue",
            self::Shipped => "indigo",
            self::Delivered => "green",
            self::Cancelled => "red",
        };
    }

    public function isFinal(): bool {
        return match ($this) {
            self::Delivered, self::Cancelled => true,
            default => false,
        };
    }

    public function label(): string {
        return match ($this) {
            self::Pending => "Awaiting Payment",
            self::Processing => "Preparing Shipment",
            self::Shipped => "In Transit",
            self::Delivered => "Delivered to Customer",
            self::Cancelled => "Order Voided",
        };
    }
}

// 2. Pure Enum (no backing scalar)
enum Priority {
    case Low;
    case Medium;
    case High;
    case Critical;
}

// 3. Working with Enums
$status = OrderStatus::from("processing"); // strict parse
echo "1. Backed Enum instance:\n";
echo "  Name:  {$status->name}\n";
echo "  Value: {$status->value}\n";
echo "  Badge: {$status->badgeColor()}\n";
echo "  Label: {$status->label()}\n";
echo "  Final: " . ($status->isFinal() ? "Yes" : "No") . "\n";

// Safe parsing with tryFrom
$unknown = OrderStatus::tryFrom("refunded");
echo "\n2. tryFrom('refunded'): " . ($unknown === null ? "Null (Invalid status)" : $unknown->value) . "\n";

// Iterating all cases
echo "\n3. All Order Statuses:\n";
foreach (OrderStatus::cases() as $case) {
    printf("  - %-12s => %-22s (Badge: %s, Final: %s)\n",
        $case->value,
        $case->label(),
        $case->badgeColor(),
        $case->isFinal() ? "✓" : "✗"
    );
}

// Using enums in business logic
function processOrder(string $id, OrderStatus $status, Priority $priority): void {
    echo "\nProcessing Order #$id [Priority: {$priority->name}]\n";
    if ($status->isFinal()) {
        echo "  Cannot update order: already in final state ({$status->value})\n";
        return;
    }
    echo "  Action required: {$status->label()} with badge {$status->badgeColor()}\n";
}

processOrder("ORD-101", OrderStatus::Shipped, Priority::High);
processOrder("ORD-102", OrderStatus::Delivered, Priority::Low);
