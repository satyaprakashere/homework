<?php

declare(strict_types=1);

/**
 * Modern PHP 8.5 Interactive Showcase Hub & Example Explorer
 * Run: php -S localhost:8000
 * Open: http://localhost:8000
 */

// Handle source code inspection request via AJAX / Query param
if (isset($_GET['view_source'])) {
    $file = basename((string)$_GET['view_source']);
    $allowedFiles = [
        'index.php', 'dashboard.php', 'form_handling.php', 'todos.php', 'components.php',
        'main.php', 'collections.php', 'oop.php', 'enums.php', 'generators.php', 'fibers.php',
    ];

    if (in_array($file, $allowedFiles, true) && file_exists(__DIR__ . '/' . $file)) {
        header('Content-Type: text/plain; charset=utf-8');
        readfile(__DIR__ . '/' . $file);
        exit;
    }

    http_response_code(404);
    echo "File not found or access restricted.";
    exit;
}

function e(string $str): string {
    return htmlspecialchars($str, ENT_QUOTES | ENT_HTML5, 'UTF-8');
}

// System Telemetry
$phpVersion = PHP_VERSION;
$zendVersion = zend_version();
$extensions = get_loaded_extensions();
$memoryLimit = ini_get('memory_limit') ?: 'N/A';
$opcacheEnabled = function_exists('opcache_get_status') && (opcache_get_status()['opcache_enabled'] ?? false);

// Web App Examples
$webExamples = [
    [
        'title'       => 'Enterprise Analytics Dashboard',
        'file'        => 'dashboard.php',
        'badge'       => 'Full HTML / SSR',
        'badgeColor'  => '#10b981',
        'description' => 'Real-time telemetry, data filtering, sorting, server-side aggregations, and PHP 8 Enums driving visual status badges.',
        'icon'        => '📊',
        'tags'        => ['PHP 8 Enums', 'Filtering', 'Readonly Classes', 'Analytics'],
    ],
    [
        'title'       => 'Secure Form & Session Pipeline',
        'file'        => 'form_handling.php',
        'badge'       => 'Security & Forms',
        'badgeColor'  => '#f59e0b',
        'description' => 'Robust form handling featuring cryptographic CSRF defense (hash_equals), sticky fields, input sanitization, and Post/Redirect/Get flow.',
        'icon'        => '🛡️',
        'tags'        => ['CSRF Defense', 'Session Auth', 'Validation', 'Sticky Fields'],
    ],
    [
        'title'       => 'Interactive Task Manager',
        'file'        => 'todos.php',
        'badge'       => 'State Machine',
        'badgeColor'  => '#6366f1',
        'description' => 'Session-backed CRUD application with task state toggling, priority classification, filtering tabs, and custom interactive controls.',
        'icon'        => '✓',
        'tags'        => ['CRUD Actions', 'Session State', 'Priority Tags', 'Responsive UI'],
    ],
    [
        'title'       => 'UI Components & SVG Sparklines',
        'file'        => 'components.php',
        'badge'       => 'Component System',
        'badgeColor'  => '#0ea5e9',
        'description' => 'Component-based server-side rendering in native PHP, dynamic SVG sparklines plotted with pure PHP math, and clean alerts.',
        'icon'        => '🧩',
        'tags'        => ['Component Pattern', 'Server SVG', 'Clean Styling', 'Telemetry'],
    ],
];

// CLI / Language Features
$cliExamples = [
    [
        'title'       => 'PHP Core Fundamentals',
        'file'        => 'main.php',
        'description' => 'Named arguments, nullsafe operator ?->, match expressions, first-class callables strlen(...), and arrow functions.',
        'icon'        => '⚡',
        'command'     => 'php main.php',
    ],
    [
        'title'       => 'Collections & PHP 8.4+ Utilities',
        'file'        => 'collections.php',
        'description' => 'Array destructuring, spread operator, functional pipelines, array_find, array_find_key, array_any, and array_all.',
        'icon'        => '📦',
        'command'     => 'php collections.php',
    ],
    [
        'title'       => 'Modern OOP & Value Objects',
        'file'        => 'oop.php',
        'description' => 'Constructor property promotion, readonly classes, interfaces, traits, and asymmetric visibility.',
        'icon'        => '🏛️',
        'command'     => 'php oop.php',
    ],
    [
        'title'       => 'First-Class Enums',
        'file'        => 'enums.php',
        'description' => 'Pure and backed enums, methods on enums, interface implementation, tryFrom(), and exhaustive pattern matching.',
        'icon'        => '🏷️',
        'command'     => 'php enums.php',
    ],
    [
        'title'       => 'Generators & Memory Streams',
        'file'        => 'generators.php',
        'description' => 'Memory-efficient sequence generation with yield and yield from, memory benchmarking vs arrays, and data pipelines.',
        'icon'        => '🌊',
        'command'     => 'php generators.php',
    ],
    [
        'title'       => 'Cooperative Fibers (Coroutines)',
        'file'        => 'fibers.php',
        'description' => 'PHP 8.1+ Fibers for cooperative multitasking, bidirectional suspension/resumption, and a round-robin task scheduler.',
        'icon'        => '🔄',
        'command'     => 'php fibers.php',
    ],
    [
        'title'       => 'Property Hooks & Asymmetric Visibility',
        'file'        => 'advanced/property_hooks.php',
        'description' => 'PHP 8.4/8.5 virtual computed properties, backed set/get hooks with validation, and public private(set) modifiers.',
        'icon'        => '🪝',
        'command'     => 'php advanced/property_hooks.php',
    ],
    [
        'title'       => 'Attributes & Reflection',
        'file'        => 'advanced/Attributes.php',
        'description' => 'Structured native metadata annotations (#[Route], #[ValidateLength]) and runtime reflection extraction.',
        'icon'        => '🏷️',
        'command'     => 'php advanced/Attributes.php',
    ],
];
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Modern PHP 8.5 Showcase Hub - Examples & Interactive Apps</title>
    <meta name="description" content="An interactive portal and code explorer for modern PHP 8.5, featuring full HTML web applications and language architecture examples.">
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@400;500;600;700&family=Inter:wght@400;500;600&family=JetBrains+Mono:wght@400;500&display=swap" rel="stylesheet">
    <style>
        :root {
            --bg-primary: #090d16;
            --bg-secondary: #0f172a;
            --bg-card: rgba(22, 32, 54, 0.7);
            --border: rgba(255, 255, 255, 0.08);
            --border-hover: rgba(255, 255, 255, 0.18);
            --text-main: #f8fafc;
            --text-muted: #94a3b8;
            --accent-primary: #6366f1;
            --accent-gradient: linear-gradient(135deg, #6366f1 0%, #a855f7 100%);
            --accent-glow: rgba(99, 102, 241, 0.25);
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
                radial-gradient(circle at 10% 10%, rgba(99, 102, 241, 0.15) 0%, transparent 40%),
                radial-gradient(circle at 90% 90%, rgba(168, 85, 247, 0.12) 0%, transparent 45%);
            background-attachment: fixed;
            padding: 2.5rem 1.5rem;
        }

        .container {
            max-width: 1200px;
            margin: 0 auto;
        }

        /* Hero Header */
        .hero {
            display: flex;
            justify-content: space-between;
            align-items: center;
            flex-wrap: wrap;
            gap: 2rem;
            margin-bottom: 3rem;
            padding-bottom: 2rem;
            border-bottom: 1px solid var(--border);
        }

        .hero-text {
            flex: 1;
            min-width: 300px;
        }

        .version-badge {
            display: inline-flex;
            align-items: center;
            gap: 0.5rem;
            background: rgba(99, 102, 241, 0.15);
            border: 1px solid rgba(99, 102, 241, 0.35);
            color: #a5b4fc;
            padding: 0.3rem 0.75rem;
            border-radius: 9999px;
            font-size: 0.8rem;
            font-weight: 600;
            margin-bottom: 1rem;
        }

        .hero h1 {
            font-family: 'Outfit', sans-serif;
            font-size: 2.6rem;
            font-weight: 700;
            line-height: 1.15;
            letter-spacing: -0.02em;
            background: linear-gradient(135deg, #ffffff 30%, #cbd5e1 100%);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
        }

        .hero p {
            color: var(--text-muted);
            font-size: 1.05rem;
            margin-top: 0.75rem;
            max-width: 640px;
        }

        /* System Telemetry Bar */
        .telemetry-bar {
            display: flex;
            gap: 1.5rem;
            flex-wrap: wrap;
            background: var(--bg-card);
            backdrop-filter: blur(16px);
            border: 1px solid var(--border);
            border-radius: var(--radius-lg);
            padding: 1rem 1.5rem;
        }

        .telemetry-item {
            display: flex;
            flex-direction: column;
        }

        .telemetry-label {
            font-size: 0.75rem;
            text-transform: uppercase;
            letter-spacing: 0.05em;
            color: var(--text-muted);
        }

        .telemetry-val {
            font-family: 'JetBrains Mono', monospace;
            font-size: 0.95rem;
            font-weight: 600;
            color: #ffffff;
        }

        /* Section Headings */
        .section-header {
            display: flex;
            justify-content: space-between;
            align-items: baseline;
            margin: 3rem 0 1.5rem;
        }

        .section-header h2 {
            font-family: 'Outfit', sans-serif;
            font-size: 1.5rem;
            font-weight: 700;
            display: flex;
            align-items: center;
            gap: 0.6rem;
        }

        .section-subtitle {
            color: var(--text-muted);
            font-size: 0.9rem;
        }

        /* Web Examples Grid */
        .web-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
            gap: 1.5rem;
        }

        .web-card {
            background: var(--bg-card);
            backdrop-filter: blur(16px);
            border: 1px solid var(--border);
            border-radius: var(--radius-lg);
            padding: 1.6rem;
            display: flex;
            flex-direction: column;
            justify-content: space-between;
            transition: all 0.25s ease;
            position: relative;
            box-shadow: 0 10px 25px rgba(0, 0, 0, 0.2);
        }

        .web-card:hover {
            transform: translateY(-3px);
            border-color: var(--border-hover);
            box-shadow: 0 14px 35px rgba(0, 0, 0, 0.35);
        }

        .card-top {
            margin-bottom: 1.5rem;
        }

        .card-header-line {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 1rem;
        }

        .card-icon-box {
            font-size: 1.6rem;
        }

        .badge-pill {
            font-size: 0.75rem;
            font-weight: 600;
            padding: 0.25rem 0.65rem;
            border-radius: 9999px;
            background: rgba(255, 255, 255, 0.05);
            border: 1px solid var(--border);
        }

        .web-card h3 {
            font-family: 'Outfit', sans-serif;
            font-size: 1.25rem;
            font-weight: 600;
            color: #ffffff;
            margin-bottom: 0.5rem;
        }

        .web-card p {
            color: var(--text-muted);
            font-size: 0.9rem;
            line-height: 1.5;
        }

        .tag-list {
            display: flex;
            flex-wrap: wrap;
            gap: 0.4rem;
            margin-top: 1rem;
        }

        .tag {
            background: rgba(255, 255, 255, 0.03);
            border: 1px solid rgba(255, 255, 255, 0.06);
            color: #94a3b8;
            font-size: 0.725rem;
            padding: 0.2rem 0.5rem;
            border-radius: var(--radius-sm);
        }

        .card-actions {
            display: flex;
            gap: 0.75rem;
            margin-top: 1rem;
            padding-top: 1rem;
            border-top: 1px solid var(--border);
        }

        .btn {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 0.4rem;
            padding: 0.6rem 1rem;
            border-radius: var(--radius-md);
            font-size: 0.85rem;
            font-weight: 600;
            text-decoration: none;
            cursor: pointer;
            transition: all 0.2s ease;
            flex: 1;
        }

        .btn-launch {
            background: var(--accent-gradient);
            color: #ffffff;
            box-shadow: 0 4px 14px var(--accent-glow);
        }

        .btn-launch:hover {
            opacity: 0.95;
            transform: translateY(-1px);
        }

        .btn-view {
            background: rgba(255, 255, 255, 0.05);
            color: var(--text-main);
            border: 1px solid var(--border);
        }

        .btn-view:hover {
            background: rgba(255, 255, 255, 0.1);
        }

        /* CLI Grid */
        .cli-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(260px, 1fr));
            gap: 1.25rem;
        }

        .cli-card {
            background: var(--bg-card);
            backdrop-filter: blur(16px);
            border: 1px solid var(--border);
            border-radius: var(--radius-md);
            padding: 1.25rem;
            display: flex;
            flex-direction: column;
            justify-content: space-between;
        }

        .cli-header {
            display: flex;
            align-items: center;
            gap: 0.6rem;
            margin-bottom: 0.6rem;
        }

        .cli-header h3 {
            font-family: 'Outfit', sans-serif;
            font-size: 1.05rem;
            font-weight: 600;
            color: #ffffff;
        }

        .cli-card p {
            color: var(--text-muted);
            font-size: 0.825rem;
            margin-bottom: 1rem;
        }

        .code-box {
            background: #050811;
            border: 1px solid var(--border);
            border-radius: var(--radius-sm);
            padding: 0.5rem 0.75rem;
            font-family: 'JetBrains Mono', monospace;
            font-size: 0.775rem;
            color: #a5b4fc;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }

        /* Source Code Modal */
        .modal-backdrop {
            position: fixed;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background: rgba(0, 0, 0, 0.85);
            backdrop-filter: blur(8px);
            display: none;
            align-items: center;
            justify-content: center;
            padding: 1.5rem;
            z-index: 1000;
        }

        .modal-content {
            background: #0d1322;
            border: 1px solid var(--border);
            border-radius: var(--radius-lg);
            width: 100%;
            max-width: 900px;
            max-height: 85vh;
            display: flex;
            flex-direction: column;
            overflow: hidden;
            box-shadow: 0 25px 60px rgba(0, 0, 0, 0.6);
        }

        .modal-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 1rem 1.5rem;
            border-bottom: 1px solid var(--border);
            background: rgba(255, 255, 255, 0.02);
        }

        .modal-title {
            font-family: 'JetBrains Mono', monospace;
            font-size: 0.95rem;
            color: #ffffff;
        }

        .modal-close {
            background: none;
            border: none;
            color: var(--text-muted);
            font-size: 1.5rem;
            cursor: pointer;
            padding: 0.2rem;
            line-height: 1;
        }

        .modal-close:hover {
            color: #ffffff;
        }

        .modal-body {
            padding: 1.25rem 1.5rem;
            overflow: auto;
            flex: 1;
        }

        pre code {
            font-family: 'JetBrains Mono', monospace;
            font-size: 0.85rem;
            line-height: 1.6;
            color: #cbd5e1;
        }

        /* Footer */
        footer {
            margin-top: 4rem;
            padding-top: 2rem;
            border-top: 1px solid var(--border);
            text-align: center;
            color: var(--text-muted);
            font-size: 0.85rem;
        }
    </style>
</head>
<body>
    <div class="container">
        <!-- Hero Header -->
        <header class="hero">
            <div class="hero-text">
                <div class="version-badge">
                    <span>🐘 PHP <?= e($phpVersion) ?></span>
                    <span>•</span>
                    <span>Zend Engine v<?= e($zendVersion) ?></span>
                </div>
                <h1>Modern PHP Architecture & Web Applications</h1>
                <p>Interactive web applications, server-rendered components, and modern language paradigms. Explore full HTML examples or inspect CLI runtime benchmarks.</p>
            </div>

            <div class="telemetry-bar">
                <div class="telemetry-item">
                    <span class="telemetry-label">PHP Engine</span>
                    <span class="telemetry-val"><?= e($phpVersion) ?></span>
                </div>
                <div class="telemetry-item">
                    <span class="telemetry-label">Memory Limit</span>
                    <span class="telemetry-val"><?= e($memoryLimit) ?></span>
                </div>
                <div class="telemetry-item">
                    <span class="telemetry-label">OPcache</span>
                    <span class="telemetry-val" style="color: <?= $opcacheEnabled ? '#10b981' : '#f59e0b' ?>">
                        <?= $opcacheEnabled ? 'Active' : 'Disabled' ?>
                    </span>
                </div>
                <div class="telemetry-item">
                    <span class="telemetry-label">Extensions</span>
                    <span class="telemetry-val"><?= count($extensions) ?> Loaded</span>
                </div>
            </div>
        </header>

        <!-- Full HTML Web Applications Section -->
        <section aria-labelledby="web-apps-title">
            <div class="section-header">
                <h2 id="web-apps-title">🌐 Full HTML Web Applications</h2>
                <span class="section-subtitle">Live interactive pages with server-side rendering</span>
            </div>

            <div class="web-grid">
                <?php foreach ($webExamples as $ex): ?>
                    <article class="web-card">
                        <div class="card-top">
                            <div class="card-header-line">
                                <span class="card-icon-box"><?= $ex['icon'] ?></span>
                                <span class="badge-pill" style="color: <?= $ex['badgeColor'] ?>; border-color: <?= $ex['badgeColor'] ?>44;">
                                    <?= e($ex['badge']) ?>
                                </span>
                            </div>
                            <h3><?= e($ex['title']) ?></h3>
                            <p><?= e($ex['description']) ?></p>
                            <div class="tag-list">
                                <?php foreach ($ex['tags'] as $tag): ?>
                                    <span class="tag"><?= e($tag) ?></span>
                                <?php endforeach; ?>
                            </div>
                        </div>

                        <div class="card-actions">
                            <a href="<?= e($ex['file']) ?>" class="btn btn-launch">Launch App →</a>
                            <button onclick="inspectSource('<?= e($ex['file']) ?>')" class="btn btn-view">View Source</button>
                        </div>
                    </article>
                <?php endforeach; ?>
            </div>
        </section>

        <!-- CLI & Language Features Section -->
        <section aria-labelledby="cli-title">
            <div class="section-header">
                <h2 id="cli-title">⚡ Language Paradigms & CLI Examples</h2>
                <span class="section-subtitle">Modern syntax, memory streams, fibers, and OOP</span>
            </div>

            <div class="cli-grid">
                <?php foreach ($cliExamples as $cli): ?>
                    <div class="cli-card">
                        <div>
                            <div class="cli-header">
                                <span><?= $cli['icon'] ?></span>
                                <h3><?= e($cli['title']) ?></h3>
                            </div>
                            <p><?= e($cli['description']) ?></p>
                        </div>
                        <div class="code-box">
                            <span><?= e($cli['command']) ?></span>
                            <button 
                                onclick="inspectSource('<?= e($cli['file']) ?>')" 
                                style="background: none; border: none; color: #94a3b8; cursor: pointer; font-size: 0.75rem;"
                                title="View Code"
                            >
                                [Source]
                            </button>
                        </div>
                    </div>
                <?php endforeach; ?>
            </div>
        </section>

        <!-- Footer -->
        <footer>
            <p>PHP <?= e($phpVersion) ?> Example Suite • Run local server via <code>php -S localhost:8000</code></p>
        </footer>
    </div>

    <!-- Source Code Viewer Modal -->
    <div id="sourceModal" class="modal-backdrop" onclick="if(event.target === this) closeModal()">
        <div class="modal-content">
            <div class="modal-header">
                <span id="modalTitle" class="modal-title">Source Viewer</span>
                <button onclick="closeModal()" class="modal-close" aria-label="Close modal">×</button>
            </div>
            <div class="modal-body">
                <pre><code id="sourceCode">Loading source code...</code></pre>
            </div>
        </div>
    </div>

    <script>
        function inspectSource(fileName) {
            const modal = document.getElementById('sourceModal');
            const title = document.getElementById('modalTitle');
            const codeBlock = document.getElementById('sourceCode');

            title.textContent = fileName;
            codeBlock.textContent = 'Fetching ' + fileName + '...';
            modal.style.display = 'flex';

            fetch('index.php?view_source=' + encodeURIComponent(fileName))
                .then(res => {
                    if (!res.ok) throw new Error('Failed to load file');
                    return res.text();
                })
                .then(text => {
                    codeBlock.textContent = text;
                })
                .catch(err => {
                    codeBlock.textContent = 'Error loading source: ' + err.message;
                });
        }

        function closeModal() {
            document.getElementById('sourceModal').style.display = 'none';
        }

        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape') closeModal();
        });
    </script>
</body>
</html>
