# Homework Public Release Audit & Publication Spec

## 1. Executive Summary
This document records the security audit, privacy verification, path sanitization, licensing, and public mirror synchronization performed to safely publish the `homework` polyglot programming laboratory to GitHub (`git@github.com:satyaprakashere/homework.git`).

---

## 2. Completed Remediation Steps

### A. Privacy & Secrets Audit
- **Zero Secrets Verified**: Scanned for cloud API tokens, OpenAI/Gemini/Anthropic keys, SSH private keys, and hardcoded secrets. All demo keys (e.g. in `system-design-ai`) are strictly mock educational values.
- **No Tracked Databases**: Ensured local SQLite caches (`.dexter.db`) are ignored in `.gitignore` and untracked. Removed `database/news.db` sample database.
- **Offline Fingerprint Snapshots**: Audited `web/html/downlaoded_webpages/` research files; confirmed they contain no personal session credentials.

### B. Filesystem & Path Sanitization
- Replaced 44 files containing hardcoded absolute macOS paths (`file:///Users/prakash/Documents/homework/...` and `/Users/prakash/Documents/projects/homework/...`) with clean, portable relative Markdown links (`./...`).
- Cleaned local module replacement paths from `go/wails/helloworld/go.mod`.
- Sanitized local output path in `swift/metal/Raymarching_SDF.swift`.

### C. Open Source Licensing
- Added top-level [`homework/LICENSE`](file:///Users/prakash/Documents/projects/homework/LICENSE) under the permissive MIT License (Copyright (c) 2026 Satya Prakash).

### D. Build & Clean Automation Tooling
- Implemented zero-dependency Go automation:
  - [`scripts/build.go`](file:///Users/prakash/Documents/projects/homework/scripts/build.go) (symlinked to [`build.go`](file:///Users/prakash/Documents/projects/homework/build.go)): Discovers and runs fast/full builds across 40+ language projects with concurrency, timeout limits, and diagnostic reports.
  - [`scripts/clean.go`](file:///Users/prakash/Documents/projects/homework/scripts/clean.go) (symlinked to [`clean.go`](file:///Users/prakash/Documents/projects/homework/clean.go)): Safely purges build artifacts (`target/`, `bin/`, `obj/`, `zig-out/`, `.lake/`, `dist-newstyle/`, `__pycache__/`, etc.) with git-aware safety protection.
  - [`scripts/README.md`](file:///Users/prakash/Documents/projects/homework/scripts/README.md): Complete technical manual and CLI flag reference.

### E. GitHub Synchronization
- Executed monorepo subtree extraction and mirror synchronization via `go run scripts/mirror.go homework`.
- Branch `master` successfully force-updated on `git@github.com:satyaprakashere/homework.git`.

---

## 3. Ongoing Maintenance Protocol
Whenever updates are made in `homework/`:
1. Verify builds: `go run build.go`
2. Clean artifacts: `go run clean.go`
3. Commit changes to monorepo: `git commit -m "feat(homework): ..."`
4. Publish to GitHub mirror: `go run scripts/mirror.go homework` (from monorepo root)
