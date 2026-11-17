<?php

declare(strict_types=1);

/**
 * Modern PHP Full-HTML Example: Interactive Task Manager (Session-Backed CRUD)
 * Run with built-in server: php -S localhost:8000
 * Direct URL: http://localhost:8000/todos.php
 */

if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

// 1. Domain Modeling
enum Priority: string {
    case Urgent = 'urgent';
    case Medium = 'medium';
    case Low    = 'low';

    public function badgeClasses(): string {
        return match ($this) {
            self::Urgent => 'badge-urgent',
            self::Medium => 'badge-medium',
            self::Low    => 'badge-low',
        };
    }
}

// Escaping helper
function e(string $str): string {
    return htmlspecialchars($str, ENT_QUOTES | ENT_HTML5, 'UTF-8');
}

// 2. Initialize Seed Tasks in Session if empty
if (!isset($_SESSION['todos'])) {
    $_SESSION['todos'] = [
        [
            'id'        => 'task_1',
            'title'     => 'Explore PHP 8.5 Property Hooks & Asymmetric Visibility',
            'priority'  => Priority::Urgent->value,
            'completed' => true,
            'created_at'=> date('Y-m-d H:i', strtotime('-2 hours')),
        ],
        [
            'id'        => 'task_2',
            'title'     => 'Build a cooperative multitasking scheduler with Fibers',
            'priority'  => Priority::Medium->value,
            'completed' => false,
            'created_at'=> date('Y-m-d H:i', strtotime('-1 hour')),
        ],
        [
            'id'        => 'task_3',
            'title'     => 'Profile memory efficiency using PHP Generators',
            'priority'  => Priority::Low->value,
            'completed' => false,
            'created_at'=> date('Y-m-d H:i', strtotime('-30 minutes')),
        ],
    ];
}

// 3. Handle Actions (POST)
if (($_SERVER['REQUEST_METHOD'] ?? 'GET') === 'POST') {
    $action = $_POST['action'] ?? '';

    // Action: Add new task
    if ($action === 'add') {
        $title = trim((string)($_POST['title'] ?? ''));
        $priorityInput = trim((string)($_POST['priority'] ?? 'medium'));
        $priority = Priority::tryFrom($priorityInput) ?? Priority::Medium;

        if (!empty($title)) {
            array_unshift($_SESSION['todos'], [
                'id'        => 'task_' . bin2hex(random_bytes(4)),
                'title'     => $title,
                'priority'  => $priority->value,
                'completed' => false,
                'created_at'=> date('Y-m-d H:i'),
            ]);
        }
    }

    // Action: Toggle completion status
    if ($action === 'toggle') {
        $taskId = $_POST['task_id'] ?? '';
        foreach ($_SESSION['todos'] as &$todo) {
            if ($todo['id'] === $taskId) {
                $todo['completed'] = !$todo['completed'];
                break;
            }
        }
        unset($todo);
    }

    // Action: Delete task
    if ($action === 'delete') {
        $taskId = $_POST['task_id'] ?? '';
        $_SESSION['todos'] = array_values(array_filter(
            $_SESSION['todos'],
            fn(array $item): bool => $item['id'] !== $taskId
        ));
    }

    // Action: Clear all completed
    if ($action === 'clear_completed') {
        $_SESSION['todos'] = array_values(array_filter(
            $_SESSION['todos'],
            fn(array $item): bool => !$item['completed']
        ));
    }

    header("Location: todos.php" . (!empty($_GET['filter']) ? '?filter=' . urlencode($_GET['filter']) : ''));
    exit;
}

// 4. Filtering Logic
$currentFilter = $_GET['filter'] ?? 'all';
$allTodos = $_SESSION['todos'];

$filteredTodos = match ($currentFilter) {
    'active'    => array_filter($allTodos, fn(array $t): bool => !$t['completed']),
    'completed' => array_filter($allTodos, fn(array $t): bool => (bool)$t['completed']),
    default     => $allTodos,
};

$totalCount = count($allTodos);
$activeCount = count(array_filter($allTodos, fn(array $t): bool => !$t['completed']));
$completedCount = $totalCount - $activeCount;

?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Task Manager - PHP 8.5 Full HTML Example</title>
    <meta name="description" content="An interactive session-backed task management web app built with modern PHP 8.5 and vanilla CSS.">
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@400;500;600;700&family=Inter:wght@400;500;600&display=swap" rel="stylesheet">
    <style>
        :root {
            --bg-primary: #0a0e1a;
            --bg-card: rgba(19, 26, 44, 0.7);
            --border: rgba(255, 255, 255, 0.08);
            --border-hover: rgba(255, 255, 255, 0.16);
            --text-main: #f8fafc;
            --text-muted: #94a3b8;
            --accent-primary: #6366f1;
            --accent-gradient: linear-gradient(135deg, #6366f1 0%, #a855f7 100%);
            --accent-glow: rgba(99, 102, 241, 0.25);
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
                radial-gradient(circle at 10% 20%, rgba(99, 102, 241, 0.12) 0%, transparent 40%),
                radial-gradient(circle at 90% 80%, rgba(168, 85, 247, 0.1) 0%, transparent 45%);
            background-attachment: fixed;
            padding: 2.5rem 1rem;
        }

        .container {
            max-width: 760px;
            margin: 0 auto;
        }

        /* Top Navigation */
        .nav-bar {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 2rem;
            padding-bottom: 1rem;
            border-bottom: 1px solid var(--border);
        }

        .nav-link {
            color: var(--text-muted);
            text-decoration: none;
            font-size: 0.875rem;
            transition: color 0.2s ease;
        }

        .nav-link:hover {
            color: var(--text-main);
        }

        /* App Header */
        .app-header {
            margin-bottom: 2rem;
            text-align: center;
        }

        .app-header h1 {
            font-family: 'Outfit', sans-serif;
            font-size: 2.2rem;
            font-weight: 700;
            background: linear-gradient(to right, #ffffff, #cbd5e1);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
        }

        .app-header p {
            color: var(--text-muted);
            font-size: 0.95rem;
            margin-top: 0.35rem;
        }

        /* Input Form Card */
        .composer-card {
            background: var(--bg-card);
            backdrop-filter: blur(16px);
            border: 1px solid var(--border);
            border-radius: var(--radius-lg);
            padding: 1.5rem;
            margin-bottom: 2rem;
            box-shadow: 0 10px 30px rgba(0, 0, 0, 0.25);
        }

        .composer-form {
            display: flex;
            gap: 0.75rem;
            flex-wrap: wrap;
        }

        .input-title {
            flex: 1;
            min-width: 240px;
            background: rgba(10, 14, 26, 0.8);
            border: 1px solid var(--border);
            border-radius: var(--radius-md);
            padding: 0.75rem 1rem;
            color: var(--text-main);
            font-size: 0.95rem;
            font-family: inherit;
            transition: all 0.2s ease;
        }

        .input-title:focus {
            outline: none;
            border-color: var(--accent-primary);
            box-shadow: 0 0 0 3px rgba(99, 102, 241, 0.2);
        }

        .select-priority {
            width: 130px;
            background: rgba(10, 14, 26, 0.8);
            border: 1px solid var(--border);
            border-radius: var(--radius-md);
            padding: 0.75rem 0.75rem;
            color: var(--text-main);
            font-size: 0.875rem;
            font-family: inherit;
            cursor: pointer;
        }

        .btn-add {
            background: var(--accent-gradient);
            color: #ffffff;
            border: none;
            padding: 0.75rem 1.4rem;
            border-radius: var(--radius-md);
            font-size: 0.9rem;
            font-weight: 600;
            cursor: pointer;
            box-shadow: 0 4px 14px var(--accent-glow);
            transition: all 0.2s ease;
            white-space: nowrap;
        }

        .btn-add:hover {
            transform: translateY(-1px);
            box-shadow: 0 6px 20px var(--accent-glow);
        }

        /* Filter Pills & Controls */
        .filter-bar {
            display: flex;
            justify-content: space-between;
            align-items: center;
            flex-wrap: wrap;
            gap: 1rem;
            margin-bottom: 1.25rem;
            padding: 0 0.5rem;
        }

        .filter-tabs {
            display: flex;
            gap: 0.35rem;
            background: rgba(255, 255, 255, 0.04);
            padding: 0.25rem;
            border-radius: var(--radius-md);
            border: 1px solid var(--border);
        }

        .tab-btn {
            color: var(--text-muted);
            text-decoration: none;
            padding: 0.4rem 0.85rem;
            border-radius: var(--radius-sm);
            font-size: 0.8rem;
            font-weight: 500;
            transition: all 0.2s ease;
        }

        .tab-btn.active {
            background: var(--accent-primary);
            color: #ffffff;
        }

        .tab-btn:hover:not(.active) {
            color: var(--text-main);
        }

        .clear-btn {
            background: none;
            border: none;
            color: var(--text-muted);
            font-size: 0.8rem;
            cursor: pointer;
            transition: color 0.2s ease;
            padding: 0.4rem;
        }

        .clear-btn:hover {
            color: var(--danger);
        }

        /* Task Items List */
        .tasks-card {
            background: var(--bg-card);
            backdrop-filter: blur(16px);
            border: 1px solid var(--border);
            border-radius: var(--radius-lg);
            overflow: hidden;
        }

        .task-item {
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 1.1rem 1.4rem;
            border-bottom: 1px solid var(--border);
            transition: background 0.15s ease;
            gap: 1rem;
        }

        .task-item:last-child {
            border-bottom: none;
        }

        .task-item:hover {
            background: rgba(255, 255, 255, 0.02);
        }

        .task-left {
            display: flex;
            align-items: center;
            gap: 1rem;
            flex: 1;
        }

        .checkbox-submit {
            background: none;
            border: none;
            cursor: pointer;
            padding: 0;
            display: flex;
            align-items: center;
            justify-content: center;
        }

        .check-circle {
            width: 22px;
            height: 22px;
            border-radius: 50%;
            border: 2px solid rgba(255, 255, 255, 0.2);
            display: flex;
            align-items: center;
            justify-content: center;
            transition: all 0.2s ease;
        }

        .check-circle:hover {
            border-color: var(--accent-primary);
        }

        .check-circle.checked {
            background: #10b981;
            border-color: #10b981;
            color: #ffffff;
            font-size: 0.75rem;
        }

        .task-content {
            display: flex;
            flex-direction: column;
            gap: 0.2rem;
        }

        .task-title {
            font-size: 0.95rem;
            color: var(--text-main);
            transition: all 0.2s ease;
        }

        .task-title.completed {
            text-decoration: line-through;
            color: var(--text-muted);
            opacity: 0.7;
        }

        .task-meta {
            font-size: 0.75rem;
            color: var(--text-muted);
        }

        .task-right {
            display: flex;
            align-items: center;
            gap: 0.75rem;
        }

        /* Priority Badges */
        .priority-badge {
            font-size: 0.7rem;
            font-weight: 600;
            padding: 0.2rem 0.5rem;
            border-radius: 9999px;
            text-transform: uppercase;
            letter-spacing: 0.05em;
        }

        .badge-urgent {
            background: rgba(239, 68, 68, 0.15);
            color: #f87171;
            border: 1px solid rgba(239, 68, 68, 0.3);
        }

        .badge-medium {
            background: rgba(245, 158, 11, 0.15);
            color: #fbbf24;
            border: 1px solid rgba(245, 158, 11, 0.3);
        }

        .badge-low {
            background: rgba(99, 102, 241, 0.15);
            color: #a5b4fc;
            border: 1px solid rgba(99, 102, 241, 0.3);
        }

        .btn-delete {
            background: none;
            border: none;
            color: rgba(255, 255, 255, 0.2);
            cursor: pointer;
            padding: 0.3rem;
            font-size: 1.1rem;
            border-radius: var(--radius-sm);
            transition: color 0.2s ease;
        }

        .btn-delete:hover {
            color: var(--danger);
        }

        .empty-tasks {
            padding: 3.5rem 1.5rem;
            text-align: center;
            color: var(--text-muted);
        }

        .empty-tasks h3 {
            font-size: 1.1rem;
            color: var(--text-main);
            margin-bottom: 0.4rem;
        }
    </style>
</head>
<body>
    <div class="container">
        <nav class="nav-bar">
            <a href="index.php" class="nav-link">← Return to Showcase Hub</a>
            <div style="display: flex; gap: 1rem;">
                <a href="dashboard.php" class="nav-link">Analytics</a>
                <a href="form_handling.php" class="nav-link">Secure Form</a>
            </div>
        </nav>

        <header class="app-header">
            <h1>Dynamic Task Queue</h1>
            <p>Session-backed state machine with PHP 8.5 Enums and server-rendered controls.</p>
        </header>

        <!-- New Task Form -->
        <div class="composer-card">
            <form method="POST" action="todos.php" class="composer-form">
                <input type="hidden" name="action" value="add">
                <input 
                    type="text" 
                    name="title" 
                    id="title"
                    class="input-title" 
                    placeholder="Enter a new engineering objective..." 
                    required 
                    autofocus
                >
                <select name="priority" id="priority" class="select-priority">
                    <option value="urgent">Urgent</option>
                    <option value="medium" selected>Medium</option>
                    <option value="low">Low</option>
                </select>
                <button type="submit" class="btn-add">+ Add Task</button>
            </form>
        </div>

        <!-- Filter Controls -->
        <div class="filter-bar">
            <div class="filter-tabs">
                <a href="todos.php?filter=all" class="tab-btn <?= $currentFilter === 'all' ? 'active' : '' ?>">
                    All (<?= $totalCount ?>)
                </a>
                <a href="todos.php?filter=active" class="tab-btn <?= $currentFilter === 'active' ? 'active' : '' ?>">
                    Active (<?= $activeCount ?>)
                </a>
                <a href="todos.php?filter=completed" class="tab-btn <?= $currentFilter === 'completed' ? 'active' : '' ?>">
                    Completed (<?= $completedCount ?>)
                </a>
            </div>

            <?php if ($completedCount > 0): ?>
                <form method="POST" action="todos.php">
                    <input type="hidden" name="action" value="clear_completed">
                    <button type="submit" class="clear-btn">Clear Completed</button>
                </form>
            <?php endif; ?>
        </div>

        <!-- Task List -->
        <main class="tasks-card">
            <?php if (empty($filteredTodos)): ?>
                <div class="empty-tasks">
                    <h3>No tasks in this view</h3>
                    <p>All clear! Create a task above or switch your filter view.</p>
                </div>
            <?php else: ?>
                <?php foreach ($filteredTodos as $todo): 
                    $priorityEnum = Priority::tryFrom($todo['priority']) ?? Priority::Medium;
                ?>
                    <div class="task-item">
                        <div class="task-left">
                            <form method="POST" action="todos.php">
                                <input type="hidden" name="action" value="toggle">
                                <input type="hidden" name="task_id" value="<?= e($todo['id']) ?>">
                                <button type="submit" class="checkbox-submit" title="Toggle status">
                                    <div class="check-circle <?= $todo['completed'] ? 'checked' : '' ?>">
                                        <?= $todo['completed'] ? '✓' : '' ?>
                                    </div>
                                </button>
                            </form>

                            <div class="task-content">
                                <span class="task-title <?= $todo['completed'] ? 'completed' : '' ?>">
                                    <?= e($todo['title']) ?>
                                </span>
                                <span class="task-meta">Added <?= e($todo['created_at']) ?></span>
                            </div>
                        </div>

                        <div class="task-right">
                            <span class="priority-badge <?= $priorityEnum->badgeClasses() ?>">
                                <?= e(ucfirst($priorityEnum->value)) ?>
                            </span>

                            <form method="POST" action="todos.php" onsubmit="return confirm('Delete this task?');">
                                <input type="hidden" name="action" value="delete">
                                <input type="hidden" name="task_id" value="<?= e($todo['id']) ?>">
                                <button type="submit" class="btn-delete" title="Delete task">×</button>
                            </form>
                        </div>
                    </div>
                <?php endforeach; ?>
            <?php endif; ?>
        </main>
    </div>
</body>
</html>
