<?php

declare(strict_types=1);

/**
 * Modern PHP Full-HTML Example: Form Processing, CSRF Protection, and Validation
 * Run with built-in server: php -S localhost:8000
 * Direct URL: http://localhost:8000/form_handling.php
 */

if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

// 1. CSRF Token Setup
if (empty($_SESSION['csrf_token'])) {
    $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
}
$csrfToken = $_SESSION['csrf_token'];

// Helper escaping function
function e(string $value): string {
    return htmlspecialchars($value, ENT_QUOTES | ENT_HTML5, 'UTF-8');
}

// 2. Initialize State
$errors = [];
$values = [
    'name'      => '',
    'email'     => '',
    'role'      => 'developer',
    'experience'=> '3-5',
    'bio'       => '',
    'newsletter'=> false,
];
$flashSuccess = $_SESSION['flash_success'] ?? null;
unset($_SESSION['flash_success']);

// Ensure submitted items array exists in session
if (!isset($_SESSION['registrations'])) {
    $_SESSION['registrations'] = [
        [
            'name' => 'Ada Lovelace',
            'email' => 'ada@computing.org',
            'role' => 'architect',
            'experience' => '5+',
            'time' => '10 minutes ago',
        ]
    ];
}

// 3. Process POST Request
if (($_SERVER['REQUEST_METHOD'] ?? 'GET') === 'POST') {
    // CSRF verification
    $submittedToken = $_POST['csrf_token'] ?? '';
    if (!hash_equals($csrfToken, $submittedToken)) {
        http_response_code(403);
        die("CSRF Token verification failed. Please refresh and try again.");
    }

    // Capture & sanitize inputs
    $values['name']       = trim((string)($_POST['name'] ?? ''));
    $values['email']      = trim((string)($_POST['email'] ?? ''));
    $values['role']       = trim((string)($_POST['role'] ?? 'developer'));
    $values['experience'] = trim((string)($_POST['experience'] ?? '3-5'));
    $values['bio']        = trim((string)($_POST['bio'] ?? ''));
    $values['newsletter'] = isset($_POST['newsletter']);

    // Validation Rules
    if (empty($values['name'])) {
        $errors['name'] = 'Full name is required.';
    } elseif (mb_strlen($values['name']) < 3) {
        $errors['name'] = 'Name must be at least 3 characters.';
    }

    if (empty($values['email'])) {
        $errors['email'] = 'Email address is required.';
    } elseif (!filter_var($values['email'], FILTER_VALIDATE_EMAIL)) {
        $errors['email'] = 'Please provide a valid email format (e.g. name@domain.com).';
    }

    $validRoles = ['developer', 'designer', 'architect', 'product_lead'];
    if (!in_array($values['role'], $validRoles, true)) {
        $errors['role'] = 'Please select a valid specialization.';
    }

    if (mb_strlen($values['bio']) > 300) {
        $errors['bio'] = 'Bio cannot exceed 300 characters.';
    }

    if (!isset($_POST['agree_terms'])) {
        $errors['agree_terms'] = 'You must accept the community terms of service.';
    }

    // Successful validation branch
    if (empty($errors)) {
        // Prepend to stored registrations
        array_unshift($_SESSION['registrations'], [
            'name'       => $values['name'],
            'email'      => $values['email'],
            'role'       => $values['role'],
            'experience' => $values['experience'],
            'time'       => 'Just now',
        ]);

        $_SESSION['flash_success'] = "Welcome, {$values['name']}! Your developer profile was registered successfully.";
        // Rotate CSRF token after successful state change
        $_SESSION['csrf_token'] = bin2hex(random_bytes(32));

        // Post/Redirect/Get pattern
        header("Location: form_handling.php");
        exit;
    }
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Secure Form Handling - PHP 8.5 Full HTML Example</title>
    <meta name="description" content="A complete demonstration of robust PHP form handling, CSRF defense, sticky fields, and server-side validation.">
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@400;500;600;700&family=Inter:wght@400;500;600&display=swap" rel="stylesheet">
    <style>
        :root {
            --bg-primary: #0b0f19;
            --bg-card: rgba(22, 30, 49, 0.75);
            --border: rgba(255, 255, 255, 0.08);
            --border-focus: #6366f1;
            --text-main: #f8fafc;
            --text-muted: #94a3b8;
            --accent-primary: #6366f1;
            --accent-gradient: linear-gradient(135deg, #6366f1 0%, #8b5cf6 100%);
            --accent-glow: rgba(99, 102, 241, 0.25);
            --success-bg: rgba(16, 185, 129, 0.15);
            --success-text: #34d399;
            --error-bg: rgba(239, 68, 68, 0.15);
            --error-text: #f87171;
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
            line-height: 1.6;
            background-image: 
                radial-gradient(circle at 80% 20%, rgba(99, 102, 241, 0.12) 0%, transparent 40%),
                radial-gradient(circle at 20% 80%, rgba(139, 92, 246, 0.1) 0%, transparent 45%);
            background-attachment: fixed;
            padding: 2rem 1rem;
        }

        .container {
            max-width: 1080px;
            margin: 0 auto;
        }

        /* Nav & Header */
        .top-nav {
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
            font-size: 0.9rem;
            display: inline-flex;
            align-items: center;
            gap: 0.4rem;
            transition: color 0.2s ease;
        }

        .nav-link:hover {
            color: var(--text-main);
        }

        .page-header {
            margin-bottom: 2rem;
        }

        .page-header h1 {
            font-family: 'Outfit', sans-serif;
            font-size: 2rem;
            font-weight: 700;
            background: linear-gradient(to right, #ffffff, #cbd5e1);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
        }

        .page-header p {
            color: var(--text-muted);
            font-size: 0.95rem;
            margin-top: 0.25rem;
        }

        /* Success Alert */
        .alert-success {
            background: var(--success-bg);
            border: 1px solid rgba(16, 185, 129, 0.35);
            color: var(--success-text);
            padding: 1rem 1.25rem;
            border-radius: var(--radius-md);
            margin-bottom: 2rem;
            display: flex;
            align-items: center;
            gap: 0.75rem;
            animation: slideDown 0.3s ease-out;
        }

        @keyframes slideDown {
            from { opacity: 0; transform: translateY(-8px); }
            to { opacity: 1; transform: translateY(0); }
        }

        /* Layout Grid */
        .content-grid {
            display: grid;
            grid-template-columns: 1.4fr 1fr;
            gap: 2rem;
            align-items: start;
        }

        @media (max-width: 860px) {
            .content-grid {
                grid-template-columns: 1fr;
            }
        }

        /* Form Card */
        .form-card {
            background: var(--bg-card);
            backdrop-filter: blur(16px);
            border: 1px solid var(--border);
            border-radius: var(--radius-lg);
            padding: 2rem;
            box-shadow: 0 10px 30px rgba(0, 0, 0, 0.25);
        }

        .form-group {
            margin-bottom: 1.4rem;
        }

        label {
            display: block;
            font-size: 0.85rem;
            font-weight: 500;
            color: var(--text-main);
            margin-bottom: 0.45rem;
        }

        .required-mark {
            color: var(--error-text);
            margin-left: 2px;
        }

        .form-control {
            width: 100%;
            background: rgba(11, 15, 25, 0.8);
            border: 1px solid var(--border);
            border-radius: var(--radius-md);
            padding: 0.75rem 1rem;
            color: var(--text-main);
            font-size: 0.9rem;
            font-family: inherit;
            transition: all 0.2s ease;
        }

        .form-control:focus {
            outline: none;
            border-color: var(--border-focus);
            box-shadow: 0 0 0 3px rgba(99, 102, 241, 0.2);
        }

        .form-control.is-invalid {
            border-color: #ef4444;
            background-color: rgba(239, 68, 68, 0.05);
        }

        select.form-control {
            appearance: none;
            background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='16' height='16' viewBox='0 0 24 24' fill='none' stroke='%2394a3b8' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'%3E%3Cpath d='m6 9 6 6 6-6'/%3E%3C/svg%3E");
            background-repeat: no-repeat;
            background-position: right 1rem center;
            background-size: 14px;
        }

        textarea.form-control {
            resize: vertical;
            min-height: 90px;
        }

        .field-error {
            color: var(--error-text);
            font-size: 0.775rem;
            margin-top: 0.35rem;
            display: flex;
            align-items: center;
            gap: 0.3rem;
        }

        .checkbox-group {
            display: flex;
            align-items: flex-start;
            gap: 0.65rem;
            margin-bottom: 1.5rem;
        }

        .checkbox-group input[type="checkbox"] {
            margin-top: 0.25rem;
            accent-color: var(--accent-primary);
            width: 16px;
            height: 16px;
            cursor: pointer;
        }

        .checkbox-label {
            font-size: 0.85rem;
            color: var(--text-muted);
            cursor: pointer;
            margin-bottom: 0;
        }

        .btn-submit {
            width: 100%;
            background: var(--accent-gradient);
            color: #ffffff;
            border: none;
            padding: 0.85rem 1.5rem;
            border-radius: var(--radius-md);
            font-size: 0.95rem;
            font-weight: 600;
            cursor: pointer;
            box-shadow: 0 4px 14px var(--accent-glow);
            transition: all 0.2s ease;
        }

        .btn-submit:hover {
            transform: translateY(-1px);
            box-shadow: 0 6px 22px var(--accent-glow);
        }

        /* Sidebar / Registrations Feed */
        .feed-card {
            background: var(--bg-card);
            backdrop-filter: blur(16px);
            border: 1px solid var(--border);
            border-radius: var(--radius-lg);
            padding: 1.5rem;
        }

        .feed-card h2 {
            font-family: 'Outfit', sans-serif;
            font-size: 1.15rem;
            font-weight: 600;
            margin-bottom: 1rem;
            display: flex;
            align-items: center;
            justify-content: space-between;
        }

        .badge-count {
            background: rgba(99, 102, 241, 0.2);
            color: #a5b4fc;
            padding: 0.2rem 0.5rem;
            border-radius: 9999px;
            font-size: 0.75rem;
            font-weight: 600;
        }

        .registration-item {
            padding: 0.9rem;
            background: rgba(11, 15, 25, 0.6);
            border: 1px solid var(--border);
            border-radius: var(--radius-md);
            margin-bottom: 0.75rem;
        }

        .reg-header {
            display: flex;
            justify-content: space-between;
            align-items: baseline;
            margin-bottom: 0.25rem;
        }

        .reg-name {
            font-weight: 600;
            font-size: 0.9rem;
        }

        .reg-time {
            font-size: 0.75rem;
            color: var(--text-muted);
        }

        .reg-meta {
            font-size: 0.8rem;
            color: var(--text-muted);
        }

        .security-badge-box {
            margin-top: 1.5rem;
            padding: 1rem;
            background: rgba(255, 255, 255, 0.02);
            border: 1px dashed var(--border);
            border-radius: var(--radius-md);
            font-size: 0.8rem;
            color: var(--text-muted);
        }

        .security-badge-box strong {
            color: #e2e8f0;
        }
    </style>
</head>
<body>
    <div class="container">
        <nav class="top-nav">
            <a href="index.php" class="nav-link">← Back to PHP Showcase</a>
            <div style="display: flex; gap: 1rem;">
                <a href="dashboard.php" class="nav-link">Analytics Dashboard</a>
                <a href="todos.php" class="nav-link">Todo Manager</a>
            </div>
        </nav>

        <header class="page-header">
            <h1>Developer Community Registration</h1>
            <p>Demonstrates sticky form handling, CSRF token validation, input sanitization, and session state persistence.</p>
        </header>

        <?php if ($flashSuccess): ?>
            <div class="alert-success" role="alert">
                <span style="font-size: 1.2rem;">✓</span>
                <span><?= e($flashSuccess) ?></span>
            </div>
        <?php endif; ?>

        <div class="content-grid">
            <!-- Registration Form -->
            <main class="form-card">
                <form method="POST" action="form_handling.php" novalidate>
                    <!-- CSRF Token (Hidden) -->
                    <input type="hidden" name="csrf_token" value="<?= e($csrfToken) ?>">

                    <!-- Full Name -->
                    <div class="form-group">
                        <label for="name">Full Name <span class="required-mark">*</span></label>
                        <input 
                            type="text" 
                            name="name" 
                            id="name" 
                            class="form-control <?= isset($errors['name']) ? 'is-invalid' : '' ?>" 
                            placeholder="e.g. Linus Torvalds"
                            value="<?= e($values['name']) ?>"
                            required
                        >
                        <?php if (isset($errors['name'])): ?>
                            <div class="field-error">⚠ <?= e($errors['name']) ?></div>
                        <?php endif; ?>
                    </div>

                    <!-- Email Address -->
                    <div class="form-group">
                        <label for="email">Email Address <span class="required-mark">*</span></label>
                        <input 
                            type="email" 
                            name="email" 
                            id="email" 
                            class="form-control <?= isset($errors['email']) ? 'is-invalid' : '' ?>" 
                            placeholder="you@domain.com"
                            value="<?= e($values['email']) ?>"
                            required
                        >
                        <?php if (isset($errors['email'])): ?>
                            <div class="field-error">⚠ <?= e($errors['email']) ?></div>
                        <?php endif; ?>
                    </div>

                    <!-- Role / Track -->
                    <div class="form-group">
                        <label for="role">Primary Focus</label>
                        <select name="role" id="role" class="form-control">
                            <option value="developer" <?= $values['role'] === 'developer' ? 'selected' : '' ?>>Backend / Full-Stack Engineer</option>
                            <option value="architect" <?= $values['role'] === 'architect' ? 'selected' : '' ?>>Systems & Cloud Architect</option>
                            <option value="designer"  <?= $values['role'] === 'designer'  ? 'selected' : '' ?>>UI / UX Systems Designer</option>
                            <option value="product_lead" <?= $values['role'] === 'product_lead' ? 'selected' : '' ?>>Product & Technical Lead</option>
                        </select>
                    </div>

                    <!-- Experience Level -->
                    <div class="form-group">
                        <label for="experience">Experience Level</label>
                        <select name="experience" id="experience" class="form-control">
                            <option value="1-2" <?= $values['experience'] === '1-2' ? 'selected' : '' ?>>1 – 2 Years</option>
                            <option value="3-5" <?= $values['experience'] === '3-5' ? 'selected' : '' ?>>3 – 5 Years</option>
                            <option value="5+"  <?= $values['experience'] === '5+'  ? 'selected' : '' ?>>5+ Years (Senior)</option>
                        </select>
                    </div>

                    <!-- Short Bio -->
                    <div class="form-group">
                        <label for="bio">Professional Bio <small style="color: var(--text-muted);">(Optional, max 300 chars)</small></label>
                        <textarea 
                            name="bio" 
                            id="bio" 
                            class="form-control <?= isset($errors['bio']) ? 'is-invalid' : '' ?>" 
                            placeholder="Tell the community about what you love building..."
                        ><?= e($values['bio']) ?></textarea>
                        <?php if (isset($errors['bio'])): ?>
                            <div class="field-error">⚠ <?= e($errors['bio']) ?></div>
                        <?php endif; ?>
                    </div>

                    <!-- Terms & Conditions Checkbox -->
                    <div class="checkbox-group">
                        <input 
                            type="checkbox" 
                            name="agree_terms" 
                            id="agree_terms" 
                            value="1"
                        >
                        <label for="agree_terms" class="checkbox-label">
                            I agree to the Community Code of Conduct and Terms of Service. <span class="required-mark">*</span>
                        </label>
                    </div>
                    <?php if (isset($errors['agree_terms'])): ?>
                        <div class="field-error" style="margin-top: -1rem; margin-bottom: 1.2rem;">
                            ⚠ <?= e($errors['agree_terms']) ?>
                        </div>
                    <?php endif; ?>

                    <button type="submit" class="btn-submit">Submit Registration</button>
                </form>
            </main>

            <!-- Sidebar / Registrations Live Feed -->
            <aside class="feed-card">
                <h2>
                    <span>Active Members</span>
                    <span class="badge-count"><?= count($_SESSION['registrations']) ?></span>
                </h2>

                <div class="registrations-list">
                    <?php foreach ($_SESSION['registrations'] as $reg): ?>
                        <article class="registration-item">
                            <div class="reg-header">
                                <span class="reg-name"><?= e($reg['name']) ?></span>
                                <span class="reg-time"><?= e($reg['time']) ?></span>
                            </div>
                            <div class="reg-meta">
                                <?= e(ucfirst($reg['role'])) ?> • <?= e($reg['experience']) ?> yrs exp
                            </div>
                        </article>
                    <?php endforeach; ?>
                </div>

                <div class="security-badge-box">
                    <strong>🛡 Security Protections:</strong>
                    <ul style="margin-left: 1.2rem; margin-top: 0.5rem; line-height: 1.6;">
                        <li>Cryptographic CSRF token verification via <code>hash_equals()</code></li>
                        <li>Contextual HTML entity escaping with <code>htmlspecialchars</code></li>
                        <li>Strict Post/Redirect/Get lifecycle prevents double submissions</li>
                    </ul>
                </div>
            </aside>
        </div>
    </div>
</body>
</html>
