<?php

declare(strict_types=1);

/**
 * Modern PHP Full-HTML Example: Component Architecture & Server-Rendered UI Elements
 * Run with built-in server: php -S localhost:8000
 * Direct URL: http://localhost:8000/components.php
 */

// --- 1. Component Rendering Engine in Native PHP ---

/**
 * Escapes string safely for HTML output
 */
function e(string $str): string {
    return htmlspecialchars($str, ENT_QUOTES | ENT_HTML5, 'UTF-8');
}

/**
 * Render a styled card component with title, badge, and slot content
 */
function renderCard(string $title, string $badgeText, string $content, string $icon = '⚡'): string {
    return <<<HTML
    <div class="card-component">
        <div class="card-header">
            <div class="card-title-group">
                <span class="card-icon">{$icon}</span>
                <h3>{$title}</h3>
            </div>
            <span class="pill-badge">{$badgeText}</span>
        </div>
        <div class="card-body">
            {$content}
        </div>
    </div>
    HTML;
}

/**
 * Render an SVG Sparkline Chart completely on the server via PHP math
 * @param int[] $points
 */
function renderSparkline(array $points, string $strokeColor = '#6366f1'): string {
    $min = min($points);
    $max = max($points);
    $range = max(($max - $min), 1);
    
    $width = 240;
    $height = 48;
    $padding = 4;
    $step = ($width - ($padding * 2)) / (count($points) - 1);
    
    $coords = [];
    foreach ($points as $i => $val) {
        $x = round($padding + ($i * $step), 1);
        $y = round($height - $padding - ((($val - $min) / $range) * ($height - ($padding * 2))), 1);
        $coords[] = "$x,$y";
    }
    $pointsString = implode(' ', $coords);
    
    return <<<HTML
    <div class="sparkline-container">
        <svg width="{$width}" height="{$height}" viewBox="0 0 {$width} {$height}" class="sparkline-svg">
            <polyline 
                fill="none" 
                stroke="{$strokeColor}" 
                stroke-width="2.5" 
                stroke-linecap="round" 
                stroke-linejoin="round" 
                points="{$pointsString}"
            />
        </svg>
    </div>
    HTML;
}

/**
 * Render Alert Notification Component
 */
function renderAlert(string $type, string $title, string $message): string {
    $colors = match ($type) {
        'success' => ['bg' => 'rgba(16, 185, 129, 0.12)', 'border' => 'rgba(16, 185, 129, 0.3)', 'text' => '#34d399', 'icon' => '✓'],
        'warning' => ['bg' => 'rgba(245, 158, 11, 0.12)', 'border' => 'rgba(245, 158, 11, 0.3)', 'text' => '#fbbf24', 'icon' => '⚠'],
        'info'    => ['bg' => 'rgba(14, 165, 233, 0.12)', 'border' => 'rgba(14, 165, 233, 0.3)', 'text' => '#38bdf8', 'icon' => 'ℹ'],
        default   => ['bg' => 'rgba(99, 102, 241, 0.12)', 'border' => 'rgba(99, 102, 241, 0.3)', 'text' => '#818cf8', 'icon' => '✦'],
    };

    return <<<HTML
    <div class="alert-box" style="background: {$colors['bg']}; border-color: {$colors['border']}; color: {$colors['text']};">
        <span class="alert-icon">{$colors['icon']}</span>
        <div class="alert-body">
            <strong>{$title}</strong>: {$message}
        </div>
    </div>
    HTML;
}

// Sample telemetry datasets
$qpsTelemetry = [120, 140, 135, 180, 220, 210, 290, 310, 305, 380, 420];
$latencyTelemetry = [45, 42, 40, 55, 38, 32, 28, 25, 29, 22, 19];
$cacheHitTelemetry = [78, 81, 84, 83, 89, 92, 94, 95, 96, 98, 99];

?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Server-Rendered UI Components - PHP 8.5 Full HTML Example</title>
    <meta name="description" content="A reusable component design system and SVG sparklines rendered entirely in pure PHP without external dependencies.">
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@400;500;600;700&family=Inter:wght@400;500;600&display=swap" rel="stylesheet">
    <style>
        :root {
            --bg-primary: #080c14;
            --bg-card: rgba(20, 28, 46, 0.7);
            --border: rgba(255, 255, 255, 0.08);
            --border-hover: rgba(255, 255, 255, 0.16);
            --text-main: #f8fafc;
            --text-muted: #94a3b8;
            --accent: #6366f1;
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
                radial-gradient(circle at 80% 10%, rgba(99, 102, 241, 0.15) 0%, transparent 40%),
                radial-gradient(circle at 20% 90%, rgba(16, 185, 129, 0.1) 0%, transparent 45%);
            background-attachment: fixed;
            padding: 2.5rem 1rem;
        }

        .container {
            max-width: 1100px;
            margin: 0 auto;
        }

        /* Nav */
        .header-nav {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 2.5rem;
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

        .hero {
            margin-bottom: 3rem;
            text-align: center;
        }

        .hero h1 {
            font-family: 'Outfit', sans-serif;
            font-size: 2.3rem;
            font-weight: 700;
            background: linear-gradient(to right, #ffffff, #94a3b8);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
        }

        .hero p {
            color: var(--text-muted);
            font-size: 1rem;
            margin-top: 0.4rem;
        }

        /* Section Headings */
        .section-title {
            font-family: 'Outfit', sans-serif;
            font-size: 1.3rem;
            font-weight: 600;
            margin: 2.5rem 0 1.25rem;
            display: flex;
            align-items: center;
            gap: 0.5rem;
        }

        /* Component Grid */
        .grid-3 {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 1.5rem;
            margin-bottom: 2rem;
        }

        /* Card Component Styling */
        .card-component {
            background: var(--bg-card);
            backdrop-filter: blur(16px);
            border: 1px solid var(--border);
            border-radius: var(--radius-lg);
            padding: 1.5rem;
            transition: all 0.25s ease;
            box-shadow: 0 8px 24px rgba(0, 0, 0, 0.2);
        }

        .card-component:hover {
            transform: translateY(-2px);
            border-color: var(--border-hover);
        }

        .card-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 1.2rem;
        }

        .card-title-group {
            display: flex;
            align-items: center;
            gap: 0.6rem;
        }

        .card-icon {
            font-size: 1.2rem;
        }

        .card-header h3 {
            font-family: 'Outfit', sans-serif;
            font-size: 1.1rem;
            font-weight: 600;
        }

        .pill-badge {
            background: rgba(255, 255, 255, 0.07);
            border: 1px solid var(--border);
            color: #cbd5e1;
            padding: 0.2rem 0.6rem;
            border-radius: 9999px;
            font-size: 0.75rem;
            font-weight: 500;
        }

        .card-body {
            color: var(--text-muted);
            font-size: 0.9rem;
        }

        .metric-value {
            font-family: 'Outfit', sans-serif;
            font-size: 2rem;
            font-weight: 700;
            color: #ffffff;
            margin-bottom: 0.5rem;
        }

        /* Sparklines */
        .sparkline-container {
            margin-top: 1rem;
            padding-top: 0.75rem;
            border-top: 1px solid rgba(255, 255, 255, 0.05);
            display: flex;
            justify-content: center;
        }

        .sparkline-svg {
            overflow: visible;
        }

        /* Alert Boxes */
        .alerts-stack {
            display: flex;
            flex-direction: column;
            gap: 1rem;
            margin-bottom: 2rem;
        }

        .alert-box {
            display: flex;
            align-items: center;
            gap: 0.9rem;
            padding: 1rem 1.25rem;
            border-radius: var(--radius-md);
            border: 1px solid;
            font-size: 0.9rem;
        }

        .alert-icon {
            font-size: 1.1rem;
            flex-shrink: 0;
        }
    </style>
</head>
<body>
    <div class="container">
        <nav class="header-nav">
            <a href="index.php" class="nav-link">← Return to Showcase Hub</a>
            <div style="display: flex; gap: 1.2rem;">
                <a href="dashboard.php" class="nav-link">Analytics Dashboard</a>
                <a href="form_handling.php" class="nav-link">Secure Form</a>
                <a href="todos.php" class="nav-link">Todo Manager</a>
            </div>
        </nav>

        <header class="hero">
            <h1>Component Architecture in Native PHP</h1>
            <p>Demonstrating modular template rendering, dynamic SVG sparklines, and design system primitives without external dependencies.</p>
        </header>

        <!-- Metric Cards with Server-Rendered SVG Sparklines -->
        <h2 class="section-title">📊 Dynamic Telemetry Cards (SVG Sparklines)</h2>
        <div class="grid-3">
            <?= renderCard(
                title: 'Throughput (QPS)',
                badgeText: 'Live Stream',
                content: '<div class="metric-value">420.8 req/s</div>'
                    . '<div>Peak performance recorded across 4 regions.</div>'
                    . renderSparkline($qpsTelemetry, '#6366f1'),
                icon: '🚀'
            ) ?>

            <?= renderCard(
                title: 'Median Latency',
                badgeText: 'P99 Target Met',
                content: '<div class="metric-value">19.4 ms</div>'
                    . '<div>Down from 45ms following OPcache optimization.</div>'
                    . renderSparkline($latencyTelemetry, '#10b981'),
                icon: '⚡'
            ) ?>

            <?= renderCard(
                title: 'Cache Hit Ratio',
                badgeText: 'Memory Tier',
                content: '<div class="metric-value">99.1%</div>'
                    . '<div>In-memory key/value hits served under 1ms.</div>'
                    . renderSparkline($cacheHitTelemetry, '#38bdf8'),
                icon: '🎯'
            ) ?>
        </div>

        <!-- Alert Components -->
        <h2 class="section-title">🔔 Server-Rendered Feedback Notifications</h2>
        <div class="alerts-stack">
            <?= renderAlert(
                type: 'success',
                title: 'PHP 8.5 JIT Compiler',
                message: 'JIT tracing engine is fully active with Zend OPcache enabled.'
            ) ?>

            <?= renderAlert(
                type: 'info',
                title: 'Cooperative Multitasking',
                message: 'Fibers are ready to coordinate async IO workflows natively in PHP 8.1+.'
            ) ?>

            <?= renderAlert(
                type: 'warning',
                title: 'High Concurrency Threshold',
                message: 'Traffic volume approaching 85% of standard worker allocation.'
            ) ?>
        </div>
    </div>
</body>
</html>
