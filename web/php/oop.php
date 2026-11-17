<?php

declare(strict_types=1);

/**
 * Modern PHP OOP: Constructor Promotion, Readonly, Property Hooks & Asymmetric Visibility
 * Run: php oop.php
 */

echo "=== Modern PHP Object-Oriented Programming ===\n\n";

// 1. Interface & Trait
interface Loggable {
    public function log(string $message): void;
}

trait TimestampTrait {
    public readonly \DateTimeImmutable $createdAt;

    public function initTimestamp(): void {
        $this->createdAt = new \DateTimeImmutable();
    }
}

// 2. Readonly Value Object with Constructor Promotion
readonly class Money {
    public function __construct(
        public int $amountInCents,
        public string $currency = "USD",
    ) {
        if ($amountInCents < 0) {
            throw new \InvalidArgumentException("Amount cannot be negative");
        }
    }

    public function format(): string {
        return sprintf("%s %.2f", $this->currency, $this->amountInCents / 100);
    }
}

// 3. Class with Asymmetric Visibility & Property Hooks (PHP 8.4+)
class BankAccount implements Loggable {
    use TimestampTrait;

    // Asymmetric visibility: readable by everyone, modifiable only internally
    public private(set) int $transactionCount = 0;

    // Property hook for computed / validated property
    public string $accountNumber {
        get => "ACCT-****-" . substr($this->rawAccountNumber, -4);
        set (string $value) {
            if (strlen($value) < 8) {
                throw new \InvalidArgumentException("Account number must be at least 8 chars");
            }
            $this->rawAccountNumber = $value;
        }
    }

    private string $rawAccountNumber = "";
    private int $balanceCents = 0;

    public function __construct(
        public readonly string $ownerName,
        string $initialAccountNumber,
        Money $initialDeposit
    ) {
        $this->accountNumber = $initialAccountNumber; // triggers set hook
        $this->balanceCents = $initialDeposit->amountInCents;
        $this->initTimestamp();
        $this->log("Account opened for {$this->ownerName} with {$initialDeposit->format()}");
    }

    public function deposit(Money $money): void {
        $this->balanceCents += $money->amountInCents;
        $this->transactionCount++;
        $this->log("Deposited {$money->format()}. New balance: {$this->getBalance()->format()}");
    }

    public function withdraw(Money $money): void {
        if ($money->amountInCents > $this->balanceCents) {
            throw new \RuntimeException("Insufficient funds");
        }
        $this->balanceCents -= $money->amountInCents;
        $this->transactionCount++;
        $this->log("Withdrew {$money->format()}. New balance: {$this->getBalance()->format()}");
    }

    public function getBalance(): Money {
        return new Money($this->balanceCents);
    }

    public function log(string $message): void {
        echo "[LOG " . $this->createdAt->format("H:i:s") . "] $message\n";
    }
}

// --- Execution Demo ---
$initialDeposit = new Money(50000, "USD"); // $500.00
$account = new BankAccount(
    ownerName: "Ada Lovelace",
    initialAccountNumber: "9876543210",
    initialDeposit: $initialDeposit
);

echo "\nAccount details:\n";
echo "  Owner: {$account->ownerName}\n";
echo "  Masked Number: {$account->accountNumber}\n";
echo "  Initial Balance: {$account->getBalance()->format()}\n";
echo "  Transactions count (asymmetric visibility): {$account->transactionCount}\n\n";

$account->deposit(new Money(15000));  // +$150.00
$account->withdraw(new Money(6500));  // -$65.00

echo "\nFinal Balance: {$account->getBalance()->format()}\n";
echo "Total transactions: {$account->transactionCount}\n";
