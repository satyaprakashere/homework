<?php

declare(strict_types=1);

/**
 * PHP 8.4+ Deep Dive: Property Hooks & Asymmetric Visibility
 * Run: php advanced/property_hooks.php
 */

echo "=== PHP 8.4+ Property Hooks & Asymmetric Visibility ===\n\n";

class CustomerAccount {
    // 1. Asymmetric Visibility:
    // Anyone can read $status, but only internal methods can mutate it.
    public private(set) string $status = "pending";

    // 2. Backed Property with 'set' hook:
    // Automatically sanitizes and trims email on every assignment.
    public string $email {
        set {
            $sanitized = strtolower(trim($value));
            if (!filter_var($sanitized, FILTER_VALIDATE_EMAIL)) {
                throw new \InvalidArgumentException("Invalid email format: '$value'");
            }
            $this->email = $sanitized;
        }
    }

    public function __construct(
        public string $firstName,
        public string $lastName,
        string $email
    ) {
        $this->email = $email; // triggers set hook
    }

    // 3. Virtual Property with 'get' and 'set' hooks (no underlying storage variable):
    public string $fullName {
        get => "{$this->firstName} {$this->lastName}";
        set {
            [$first, $last] = explode(" ", $value, 2) + ["", ""];
            $this->firstName = $first;
            $this->lastName = $last;
        }
    }

    // 4. Virtual computed property for slug
    public string $usernameSlug {
        get => strtolower(preg_replace('/[^a-zA-Z0-9]/', '-', $this->fullName));
    }

    public function activate(): void {
        $this->status = "active";
    }

    public function suspend(string $reason): void {
        $this->status = "suspended ($reason)";
    }
}

// --- Demonstration ---
$user = new CustomerAccount(
    firstName: "Grace",
    lastName: "Hopper",
    email: "   GRACE.HOPPER@Example.COM   "
);

echo "1. Initial Object State:\n";
echo "  Full Name:      {$user->fullName}\n";
echo "  Sanitized Email: {$user->email}\n";
echo "  Username Slug:  {$user->usernameSlug}\n";
echo "  Status (read):  {$user->status}\n\n";

// Modifying full name via virtual property set hook
echo "2. Modifying via \$user->fullName = 'Admiral Grace':\n";
$user->fullName = "Admiral Grace";
echo "  First Name:     {$user->firstName}\n";
echo "  Last Name:      {$user->lastName}\n";
echo "  Username Slug:  {$user->usernameSlug}\n\n";

// Testing Asymmetric Visibility
echo "3. Modifying status via method:\n";
$user->activate();
echo "  Status after activate(): {$user->status}\n";

$user->suspend("payment failed");
echo "  Status after suspend():  {$user->status}\n\n";

// Validation error demonstration
echo "4. Testing set hook validation with invalid email:\n";
try {
    $user->email = "not-an-email";
} catch (\InvalidArgumentException $e) {
    echo "  Caught expected error: " . $e->getMessage() . "\n";
}
