<?php

declare(strict_types=1);

/**
 * Modern PHP Full-HTML Example: Dynamic Analytics Dashboard
 * Run with built-in server: php -S localhost:8000
 * Direct URL: http://localhost:8000/dashboard.php
 */

// --- 1. Enums & Data Structures ---
enum OrderStatus: string {
    case Pending    = 'pending';
    case Processing = 'processing';
    case Completed  = 'completed';
    case Cancelled  = 'cancelled';

    public function badgeClasses(): string {
        return match ($this) {
            self::Pending    => 'badge-pending',
            self::Processing => 'badge-processing',
            self::Completed  => 'badge-completed',
            self::Cancelled  => 'badge-cancelled',
        };
    }

    public function label(): string {
        return match ($this) {
            self::Pending    => 'Pending',
            self::Processing => 'Processing',
            self::Completed  => 'Completed',
            self::Cancelled  => 'Cancelled',
        };
    }
}

readonly class Order {
    public function __construct(
        public string $id,
        public string $customerName,
        public string $customerEmail,
        public float $amount,
        public OrderStatus $status,
        public string $date,
        public string $itemCount,
    ) {}
}

// --- 2. Helper Functions ---
function e(string $str): string {
    return htmlspecialchars($str, ENT_QUOTES | ENT_HTML5, 'UTF-8');
}

function formatCurrency(float $amount): string {
    return '$' . number_format($amount, 2);
}

// --- 3. Mock Dataset ---
/** @var Order[] $allOrders */
$allOrders = [
    new Order('ORD-9021', 'Sophia Martinez', 'sophia.m@example.com', 489.50, OrderStatus::Completed, '2026-09-08 11:32', '3 items'),
    new Order('ORD-9022', 'Liam Chen',       'liam.chen@example.com', 124.00, OrderStatus::Processing, '2026-09-08 10:15', '1 item'),
    new Order('ORD-9023', 'Ava Johansson',   'ava.j@example.com',     899.99, OrderStatus::Pending,    '2026-09-08 09:44', '5 items'),
    new Order('ORD-9024', 'Noah Patel',      'noah.p@example.com',     45.20, OrderStatus::Cancelled,  '2026-09-07 18:20', '1 item'),
    new Order('ORD-9025', 'Emma Wilson',     'emma.w@example.com',    312.80, OrderStatus::Completed,  '2026-09-07 16:05', '2 items'),
    new Order('ORD-9026', 'Ethan Brown',     'ethan.b@example.com',   178.40, OrderStatus::Processing, '2026-09-07 14:50', '2 items'),
    new Order('ORD-9027', 'Isabella Garcia', 'isabella.g@example.com', 640.00, OrderStatus::Completed,  '2026-09-06 20:10', '4 items'),
    new Order('ORD-9028', 'Lucas Miller',    'lucas.m@example.com',    95.00, OrderStatus::Pending,    '2026-09-06 13:22', '1 item'),
];

// --- 4. Filtering & Stats Logic ---
$search = trim($_GET['search'] ?? '');
$statusFilter = trim($_GET['status'] ?? 'all');
$sortBy = trim($_GET['sort'] ?? 'date_desc');

$filteredOrders = array_filter($allOrders, function (Order $order) use ($search, $statusFilter): bool {
    $matchesSearch = empty($search)
        || stripos($order->id, $search) !== false
        || stripos($order->customerName, $search) !== false
        || stripos($order->customerEmail, $search) !== false;

    $matchesStatus = ($statusFilter === 'all')
        || $order->status->value === $statusFilter;

    return $matchesSearch && $matchesStatus;
});

// Sorting
usort($filteredOrders, function (Order $a, Order $b) use ($sortBy): int {
    return match ($sortBy) {
        'amount_desc' => $b->amount <=> $a->amount,
        'amount_asc'  => $a->amount <=> $b->amount,
        'customer'    => strcmp($a->customerName, $b->customerName),
        default       => strcmp($b->date, $a->date), // date_desc
    };
});

// Aggregated Stats
$totalRevenue = array_reduce($allOrders, fn(float $carry, Order $o) => $o->status === OrderStatus::Completed ? $carry + $o->amount : $carry, 0.0);
$pendingCount = count(array_filter($allOrders, fn(Order $o) => $o->status === OrderStatus::Pending));
$processingCount = count(array_filter($allOrders, fn(Order $o) => $o->status === OrderStatus::Processing));
$completedCount = count(array_filter($allOrders, fn(Order $o) => $o->status === OrderStatus::Completed));

?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Enterprise Analytics Dashboard - PHP 8.5 Full HTML Example</title>
    <meta name="description" content="A modern, high-performance analytics dashboard rendered entirely with PHP 8.5 and vanilla CSS.">
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@400;500;600;700&family=Inter:wght@400;500;600&display=swap" rel="stylesheet">
    <style>
        :root {
            --bg-primary: #090d16;
            --bg-secondary: #0f172a;
            --bg-card: rgba(30, 41, 59, 0.7);
            --border: rgba(255, 255, 255, 0.08);
            --border-hover: rgba(255, 255, 255, 0.16);
            --text-main: #f8fafc;
            --text-muted: #94a3b8;
            --accent-primary: #6366f1;
            --accent-gradient: linear-gradient(135deg, #6366f1 0%, #a855f7 100%);
            --accent-glow: rgba(99, 102, 241, 0.25);
            --success: #10b981;
            --warning: #f59e0b;
            --info: #0ea5e9;
            --danger: #ef4444;
            --radius-lg: 16px;
            --radius-md: 10px;
            --radius-sm: 6px;
        }

        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: 'Inter', sans-serif;
            background-color: var(--bg-primary);
            color: var(--text-main);
            min-height: 100vh;
            line-height: 1.5;
            background-image: 
                radial-gradient(circle at 15% 10%, rgba(99, 102, 241, 0.12) 0%, transparent 40%),
                radial-gradient(circle at 85% 85%, rgba(168, 85, 247, 0.1) 0%, transparent 45%);
            background-attachment: fixed;
        }

        .container {
            max-width: 1280px;
            margin: 0 auto;
            padding: 2rem 1.5rem;
        }

        /* Header Bar */
        header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            flex-wrap: wrap;
            gap: 1.5rem;
            margin-bottom: 2rem;
            padding-bottom: 1.5rem;
            border-bottom: 1px solid var(--border);
        }

        .brand-group h1 {
            font-family: 'Outfit', sans-serif;
            font-size: 1.85rem;
            font-weight: 700;
            letter-spacing: -0.02em;
            background: linear-gradient(to right, #ffffff, #cbd5e1);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
        }

        .brand-group p {
            color: var(--text-muted);
            font-size: 0.9rem;
            margin-top: 0.25rem;
        }

        .header-actions {
            display: flex;
            align-items: center;
            gap: 0.75rem;
        }

        .btn {
            display: inline-flex;
            align-items: center;
            gap: 0.5rem;
            padding: 0.6rem 1.1rem;
            border-radius: var(--radius-md);
            font-size: 0.875rem;
            font-weight: 500;
            text-decoration: none;
            transition: all 0.2s ease;
            cursor: pointer;
            border: 1px solid transparent;
        }

        .btn-primary {
            background: var(--accent-gradient);
            color: #ffffff;
            box-shadow: 0 4px 14px var(--accent-glow);
        }

        .btn-primary:hover {
            transform: translateY(-1px);
            box-shadow: 0 6px 20px var(--accent-glow);
        }

        .btn-secondary {
            background: rgba(255, 255, 255, 0.05);
            color: var(--text-main);
            border-color: var(--border);
        }

        .btn-secondary:hover {
            background: rgba(255, 255, 255, 0.1);
            border-color: var(--border-hover);
        }

        /* Metric Cards Grid */
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
            gap: 1.25rem;
            margin-bottom: 2rem;
        }

        .stat-card {
            background: var(--bg-card);
            backdrop-filter: blur(16px);
            border: 1px solid var(--border);
            border-radius: var(--radius-lg);
            padding: 1.5rem;
            transition: transform 0.25s ease, border-color 0.25s ease;
            position: relative;
            overflow: hidden;
        }

        .stat-card:hover {
            transform: translateY(-2px);
            border-color: var(--border-hover);
        }

        .stat-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 0.75rem;
        }

        .stat-title {
            color: var(--text-muted);
            font-size: 0.85rem;
            font-weight: 500;
            text-transform: uppercase;
            letter-spacing: 0.05em;
        }

        .stat-icon {
            width: 36px;
            height: 36px;
            border-radius: var(--radius-sm);
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 1.1rem;
            background: rgba(255, 255, 255, 0.05);
        }

        .stat-value {
            font-family: 'Outfit', sans-serif;
            font-size: 1.9rem;
            font-weight: 700;
            color: #ffffff;
            margin-bottom: 0.35rem;
        }

        .stat-subtext {
            font-size: 0.8rem;
            display: flex;
            align-items: center;
            gap: 0.4rem;
        }

        .text-success { color: var(--success); }
        .text-warning { color: var(--warning); }
        .text-info    { color: var(--info); }

        /* Filter Controls */
        .filter-section {
            background: var(--bg-card);
            backdrop-filter: blur(16px);
            border: 1px solid var(--border);
            border-radius: var(--radius-lg);
            padding: 1.25rem;
            margin-bottom: 1.5rem;
        }

        .filter-form {
            display: flex;
            flex-wrap: wrap;
            gap: 1rem;
            align-items: center;
        }

        .input-group {
            flex: 1;
            min-width: 220px;
            position: relative;
        }

        .input-control {
            width: 100%;
            background: rgba(15, 23, 42, 0.8);
            border: 1px solid var(--border);
            border-radius: var(--radius-md);
            padding: 0.65rem 1rem;
            color: var(--text-main);
            font-size: 0.875rem;
            transition: border-color 0.2s ease, box-shadow 0.2s ease;
        }

        .input-control:focus {
            outline: none;
            border-color: var(--accent-primary);
            box-shadow: 0 0 0 3px rgba(99, 102, 241, 0.2);
        }

        select.input-control {
            appearance: none;
            background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='16' height='16' viewBox='0 0 24 24' fill='none' stroke='%2394a3b8' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'%3E%3Cpath d='m6 9 6 6 6-6'/%3E%3C/svg%3E");
            background-repeat: no-repeat;
            background-position: right 0.75rem center;
            background-size: 14px;
            padding-right: 2.25rem;
        }

        /* Table Design */
        .table-card {
            background: var(--bg-card);
            backdrop-filter: blur(16px);
            border: 1px solid var(--border);
            border-radius: var(--radius-lg);
            overflow: hidden;
        }

        .table-responsive {
            width: 100%;
            overflow-x: auto;
        }

        table {
            width: 100%;
            border-collapse: collapse;
            text-align: left;
            font-size: 0.875rem;
        }

        thead {
            background: rgba(15, 23, 42, 0.7);
            border-bottom: 1px solid var(--border);
        }

        th {
            padding: 1rem 1.25rem;
            color: var(--text-muted);
            font-weight: 600;
            text-transform: uppercase;
            font-size: 0.75rem;
            letter-spacing: 0.05em;
        }

        tbody tr {
            border-bottom: 1px solid var(--border);
            transition: background 0.15s ease;
        }

        tbody tr:hover {
            background: rgba(255, 255, 255, 0.02);
        }

        td {
            padding: 1rem 1.25rem;
            color: var(--text-main);
            vertical-align: middle;
        }

        .order-id {
            font-family: 'Outfit', monospace;
            font-weight: 600;
            color: var(--accent-primary);
        }

        .customer-info {
            display: flex;
            flex-direction: column;
        }

        .customer-name {
            font-weight: 500;
        }

        .customer-email {
            font-size: 0.775rem;
            color: var(--text-muted);
        }

        .amount-cell {
            font-family: 'Outfit', sans-serif;
            font-weight: 600;
            font-size: 0.95rem;
        }

        /* Status Badges */
        .badge {
            display: inline-flex;
            align-items: center;
            gap: 0.35rem;
            padding: 0.25rem 0.65rem;
            border-radius: 9999px;
            font-size: 0.75rem;
            font-weight: 500;
            line-height: 1;
        }

        .badge::before {
            content: '';
            width: 6px;
            height: 6px;
            border-radius: 50%;
        }

        .badge-completed {
            background: rgba(16, 185, 129, 0.15);
            color: #34d399;
            border: 1px solid rgba(16, 185, 129, 0.3);
        }
        .badge-completed::before { background: #10b981; }

        .badge-processing {
            background: rgba(14, 165, 233, 0.15);
            color: #38bdf8;
            border: 1px solid rgba(14, 165, 233, 0.3);
        }
        .badge-processing::before { background: #0ea5e9; }

        .badge-pending {
            background: rgba(245, 158, 11, 0.15);
            color: #fbbf24;
            border: 1px solid rgba(245, 158, 11, 0.3);
        }
        .badge-pending::before { background: #f59e0b; }

        .badge-cancelled {
            background: rgba(239, 68, 68, 0.15);
            color: #f87171;
            border: 1px solid rgba(239, 68, 68, 0.3);
        }
        .badge-cancelled::before { background: #ef4444; }

        .empty-state {
            padding: 3rem 1rem;
            text-align: center;
            color: var(--text-muted);
        }

        .empty-state h3 {
            font-size: 1.1rem;
            color: var(--text-main);
            margin-bottom: 0.5rem;
        }

        /* Footer */
        footer {
            margin-top: 3rem;
            text-align: center;
            font-size: 0.85rem;
            color: var(--text-muted);
        }

        .version-tag {
            display: inline-block;
            background: rgba(255, 255, 255, 0.05);
            border: 1px solid var(--border);
            padding: 0.2rem 0.5rem;
            border-radius: var(--radius-sm);
            font-size: 0.75rem;
            margin-left: 0.5rem;
        }
    </style>
</head>
<body>
    <div class="container">
        <!-- Header -->
        <header>
            <div class="brand-group">
                <h1>Commerce Analytics</h1>
                <p>Real-time telemetry powered by PHP <?= e(PHP_VERSION) ?> server-side rendering</p>
            </div>
            <div class="header-actions">
                <a href="index.php" class="btn btn-secondary">← Back to Hub</a>
                <a href="form_handling.php" class="btn btn-secondary">Form Example</a>
                <a href="todos.php" class="btn btn-primary">+ Interactive App</a>
            </div>
        </header>

        <!-- Dynamic Statistics (Aggregated in PHP) -->
        <section class="stats-grid" aria-label="Key Performance Indicators">
            <div class="stat-card">
                <div class="stat-header">
                    <span class="stat-title">Settled Revenue</span>
                    <div class="stat-icon text-success">💰</div>
                </div>
                <div class="stat-value"><?= formatCurrency($totalRevenue) ?></div>
                <div class="stat-subtext text-success">↑ 18.4% from previous cycle</div>
            </div>

            <div class="stat-card">
                <div class="stat-header">
                    <span class="stat-title">In Fulfillment</span>
                    <div class="stat-icon text-info">⚙️</div>
                </div>
                <div class="stat-value"><?= $processingCount ?></div>
                <div class="stat-subtext text-info">Orders actively dispatching</div>
            </div>

            <div class="stat-card">
                <div class="stat-header">
                    <span class="stat-title">Pending Payment</span>
                    <div class="stat-icon text-warning">⏳</div>
                </div>
                <div class="stat-value"><?= $pendingCount ?></div>
                <div class="stat-subtext text-warning">Awaiting customer clearance</div>
            </div>

            <div class="stat-card">
                <div class="stat-header">
                    <span class="stat-title">Completed Today</span>
                    <div class="stat-icon text-success">✓</div>
                </div>
                <div class="stat-value"><?= $completedCount ?></div>
                <div class="stat-subtext text-muted">98.2% fulfillment rating</div>
            </div>
        </section>

        <!-- Filter & Search Section -->
        <section class="filter-section">
            <form method="GET" action="dashboard.php" class="filter-form">
                <div class="input-group">
                    <input 
                        type="text" 
                        name="search" 
                        id="search" 
                        class="input-control" 
                        placeholder="Search ID, customer name, email..." 
                        value="<?= e($search) ?>"
                    >
                </div>

                <div style="min-width: 160px;">
                    <select name="status" id="status" class="input-control" onchange="this.form.submit()">
                        <option value="all" <?= $statusFilter === 'all' ? 'selected' : '' ?>>All Statuses</option>
                        <option value="completed" <?= $statusFilter === 'completed' ? 'selected' : '' ?>>Completed</option>
                        <option value="processing" <?= $statusFilter === 'processing' ? 'selected' : '' ?>>Processing</option>
                        <option value="pending" <?= $statusFilter === 'pending' ? 'selected' : '' ?>>Pending</option>
                        <option value="cancelled" <?= $statusFilter === 'cancelled' ? 'selected' : '' ?>>Cancelled</option>
                    </select>
                </div>

                <div style="min-width: 170px;">
                    <select name="sort" id="sort" class="input-control" onchange="this.form.submit()">
                        <option value="date_desc" <?= $sortBy === 'date_desc' ? 'selected' : '' ?>>Newest First</option>
                        <option value="amount_desc" <?= $sortBy === 'amount_desc' ? 'selected' : '' ?>>Highest Amount</option>
                        <option value="amount_asc" <?= $sortBy === 'amount_asc' ? 'selected' : '' ?>>Lowest Amount</option>
                        <option value="customer" <?= $sortBy === 'customer' ? 'selected' : '' ?>>Customer Name</option>
                    </select>
                </div>

                <button type="submit" class="btn btn-secondary">Apply Filters</button>

                <?php if (!empty($search) || $statusFilter !== 'all' || $sortBy !== 'date_desc'): ?>
                    <a href="dashboard.php" class="btn btn-secondary" style="color: var(--danger);">Reset</a>
                <?php endif; ?>
            </form>
        </section>

        <!-- Orders Table -->
        <main class="table-card">
            <?php if (empty($filteredOrders)): ?>
                <div class="empty-state">
                    <h3>No matching records found</h3>
                    <p>Try refining your search keyword or clearing the status filter.</p>
                </div>
            <?php else: ?>
                <div class="table-responsive">
                    <table>
                        <thead>
                            <tr>
                                <th>Order Ref</th>
                                <th>Customer</th>
                                <th>Date & Time</th>
                                <th>Volume</th>
                                <th>Total</th>
                                <th>Status</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php foreach ($filteredOrders as $order): ?>
                                <tr>
                                    <td>
                                        <span class="order-id"><?= e($order->id) ?></span>
                                    </td>
                                    <td>
                                        <div class="customer-info">
                                            <span class="customer-name"><?= e($order->customerName) ?></span>
                                            <span class="customer-email"><?= e($order->customerEmail) ?></span>
                                        </div>
                                    </td>
                                    <td>
                                        <time datetime="<?= e($order->date) ?>"><?= e($order->date) ?></time>
                                    </td>
                                    <td><?= e($order->itemCount) ?></td>
                                    <td>
                                        <span class="amount-cell"><?= formatCurrency($order->amount) ?></span>
                                    </td>
                                    <td>
                                        <span class="badge <?= $order->status->badgeClasses() ?>">
                                            <?= e($order->status->label()) ?>
                                        </span>
                                    </td>
                                </tr>
                            <?php endforeach; ?>
                        </tbody>
                    </table>
                </div>
            <?php endif; ?>
        </main>

        <!-- Footer -->
        <footer>
            <p>
                Demonstrating PHP Enums, Readonly Objects, Filtering Pipelines, and Semantic HTML.
                <span class="version-tag">PHP <?= e(PHP_VERSION) ?></span>
            </p>
        </footer>
    </div>
</body>
</html>
