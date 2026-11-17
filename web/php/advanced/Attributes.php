<?php

declare(strict_types=1);

/**
 * Modern PHP Attributes & Reflection
 * Run: php advanced/Attributes.php
 */

echo "=== PHP Attributes & Reflection Demo ===\n\n";

// 1. Defining Attributes with Targets and Flags
#[\Attribute(\Attribute::TARGET_METHOD | \Attribute::TARGET_FUNCTION)]
class Route {
    public function __construct(
        public string $path,
        public string $method = "GET"
    ) {}
}

#[\Attribute(\Attribute::TARGET_PROPERTY)]
class ValidateLength {
    public function __construct(
        public int $min = 0,
        public int $max = PHP_INT_MAX
    ) {}

    public function validate(string $name, string $value): void {
        $len = strlen($value);
        if ($len < $this->min || $len > $this->max) {
            throw new \InvalidArgumentException(
                "Property '$name' length must be between {$this->min} and {$this->max} (actual: $len)"
            );
        }
    }
}

// 2. Applying Attributes to Class and Methods
class UserController {
    #[ValidateLength(min: 3, max: 15)]
    public string $username;

    public function __construct(string $username) {
        $this->username = $username;
        $this->validateProperties();
    }

    #[Route("/api/users", method: "GET")]
    public function listUsers(): array {
        return ["alice", "bob", "carol"];
    }

    #[Route("/api/users", method: "POST")]
    public function createUser(): string {
        return "User {$this->username} created";
    }

    private function validateProperties(): void {
        $ref = new \ReflectionClass($this);
        foreach ($ref->getProperties() as $prop) {
            $attrs = $prop->getAttributes(ValidateLength::class);
            foreach ($attrs as $attr) {
                /** @var ValidateLength $validator */
                $validator = $attr->newInstance();
                $validator->validate($prop->getName(), $prop->getValue($this));
            }
        }
    }
}

// 3. Inspecting Attributes via Reflection
$controllerRef = new \ReflectionClass(UserController::class);

echo "1. Discovered Routes on " . $controllerRef->getShortName() . ":\n";
foreach ($controllerRef->getMethods() as $method) {
    $routes = $method->getAttributes(Route::class);
    foreach ($routes as $routeAttr) {
        /** @var Route $route */
        $route = $routeAttr->newInstance();
        printf("  [%-4s] %-15s => %s::%s()\n",
            $route->method,
            $route->path,
            $controllerRef->getShortName(),
            $method->getName()
        );
    }
}

echo "\n2. Validation via Attributes:\n";
try {
    $validUser = new UserController("alex_dev");
    echo "  ✓ Successfully created user: {$validUser->username}\n";

    echo "  Attempting invalid user creation (length < 3)...\n";
    $invalidUser = new UserController("al");
} catch (\InvalidArgumentException $e) {
    echo "  ✗ Caught expected validation error: " . $e->getMessage() . "\n";
}
