package main

import (
	"bytes"
	"flag"
	"fmt"
	"io/fs"
	"os"
	"os/exec"
	"path/filepath"
	"sort"
	"strings"
)

// CleanTarget describes an item to be cleaned.
type CleanTarget struct {
	Path     string // relative to repo root
	IsDir    bool
	Language string
	Size     int64
	Reason   string
}

// Colors for terminal output
var (
	colorReset  = "\033[0m"
	colorRed    = "\033[31m"
	colorGreen  = "\033[32m"
	colorYellow = "\033[33m"
	colorBlue   = "\033[34m"
	colorCyan   = "\033[36m"
	colorBold   = "\033[1m"
	colorGray   = "\033[90m"
)

func disableColors() {
	colorReset = ""
	colorRed = ""
	colorGreen = ""
	colorYellow = ""
	colorBlue = ""
	colorCyan = ""
	colorBold = ""
	colorGray = ""
}

// findRepoRoot locates the root directory containing .git.
func findRepoRoot() (string, error) {
	dir, err := os.Getwd()
	if err != nil {
		return "", err
	}
	for {
		if _, err := os.Stat(filepath.Join(dir, ".git")); err == nil {
			return dir, nil
		}
		parent := filepath.Dir(dir)
		if parent == dir {
			break
		}
		dir = parent
	}
	return os.Getwd()
}

// loadTrackedFiles runs git ls-files to identify all tracked repository files.
func loadTrackedFiles(root string) (map[string]bool, error) {
	cmd := exec.Command("git", "ls-files")
	cmd.Dir = root
	var out bytes.Buffer
	cmd.Stdout = &out
	if err := cmd.Run(); err != nil {
		return nil, err
	}

	tracked := make(map[string]bool)
	lines := strings.Split(out.String(), "\n")
	for _, line := range lines {
		line = strings.TrimSpace(line)
		if line != "" {
			tracked[filepath.Clean(line)] = true
		}
	}
	return tracked, nil
}

// isTracked checks if a path or any file inside it is tracked by git.
func isTracked(relPath string, isDir bool, tracked map[string]bool) bool {
	cleaned := filepath.Clean(relPath)
	if !isDir {
		return tracked[cleaned]
	}
	// For directories, check if any tracked file starts with "dir/"
	prefix := cleaned + string(filepath.Separator)
	for t := range tracked {
		if strings.HasPrefix(t, prefix) {
			return true
		}
	}
	return false
}

// calcDirSize recursively computes the size of a directory in bytes.
func calcDirSize(path string) int64 {
	var total int64
	_ = filepath.WalkDir(path, func(_ string, d fs.DirEntry, err error) error {
		if err != nil {
			return nil
		}
		if !d.IsDir() {
			if info, err := d.Info(); err == nil {
				total += info.Size()
			}
		}
		return nil
	})
	return total
}

// formatBytes returns human-readable byte sizes (e.g. 1.25 MB).
func formatBytes(b int64) string {
	const unit = 1024
	if b < unit {
		return fmt.Sprintf("%d B", b)
	}
	div, exp := int64(unit), 0
	for n := b / unit; n >= unit; n /= unit {
		div *= unit
		exp++
	}
	return fmt.Sprintf("%.2f %cB", float64(b)/float64(div), "KMGTPE"[exp])
}

// inferLanguage guesses the language/ecosystem of a relative path.
func inferLanguage(relPath string) string {
	parts := strings.Split(filepath.ToSlash(relPath), "/")
	if len(parts) > 0 {
		top := parts[0]
		switch top {
		case "rust", "go", "csharp", "fsharp", "zig", "lean", "gleam", "ocaml", "java", "kotlin",
			"haskell", "typst", "odin", "swift", "elixir", "erlang", "python", "ruby", "scala", "c", "cpp", "web":
			return top
		}
	}
	return "general"
}

// scanTargets discovers build artifacts eligible for cleanup.
func scanTargets(root string, deep bool, tracked map[string]bool) ([]CleanTarget, error) {
	var targets []CleanTarget

	// Top-level protected directories that must NEVER be scanned or touched
	neverTouch := map[string]bool{
		".git":  true,
		".jj":   true,
		".venv": true,
		".pixi": true,
	}

	err := filepath.WalkDir(root, func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return nil
		}

		relPath, relErr := filepath.Rel(root, path)
		if relErr != nil {
			relPath = path
		}

		if relPath == "." {
			return nil
		}

		base := d.Name()

		// Never touch protected directories
		if neverTouch[base] {
			if d.IsDir() {
				return filepath.SkipDir
			}
			return nil
		}

		// Also avoid walking inside existing build artifact folders if they are already targeted
		if d.IsDir() {
			var reason string
			lang := inferLanguage(relPath)

			switch base {
			case "target":
				// Rust, Java Maven, Aloha build dirs
				reason = "Compiler target directory"
			case "zig-out":
				reason = "Zig build output directory"
			case ".zig-cache":
				reason = "Zig compiler cache directory"
			case "zig-pkg":
				reason = "Zig package cache directory"
			case ".lake":
				reason = "Lean 4 lake build directory"
			case "_build":
				reason = "Dune / Elixir / Gleam build directory"
			case "dist-newstyle":
				reason = "Cabal build directory"
			case ".stack-work":
				reason = "Haskell Stack build directory"
			case ".scala-build":
				reason = "Scala CLI build directory"
			case "bin", "obj":
				// .NET build output
				if lang == "csharp" || lang == "fsharp" || strings.Contains(relPath, "csharp") || strings.Contains(relPath, "fsharp") || strings.Contains(relPath, "crafting-interpreters") {
					reason = ".NET / binary build output directory"
				}
			case "build":
				// Gleam, Gradle, or JS build directory (exclude root build or source dirs)
				if lang == "gleam" || lang == "kotlin" || lang == "web" || strings.Contains(relPath, "gleam") {
					reason = "Project build output directory"
				}
			case "__pycache__":
				// Python bytecode cache
				if !strings.Contains(relPath, ".pixi") && !strings.Contains(relPath, ".venv") {
					reason = "Python bytecode cache directory"
				}
			case "node_modules", ".spago":
				// Cleaned only if deep mode is requested
				if deep {
					reason = "Dependency package cache (deep mode)"
				}
			}

			if reason != "" {
				// Safety check: ensure not tracked in git
				if !isTracked(relPath, true, tracked) {
					targets = append(targets, CleanTarget{
						Path:     relPath,
						IsDir:    true,
						Language: lang,
						Size:     calcDirSize(path),
						Reason:   reason,
					})
					return filepath.SkipDir
				}
			}

			return nil
		}

		// File checks
		fileName := d.Name()
		var fileReason string
		lang := inferLanguage(relPath)

		// 1. Temporary OS junk
		if fileName == ".DS_Store" {
			fileReason = "macOS metadata file"
		} else if strings.HasSuffix(fileName, ".hi") {
			fileReason = "Haskell interface file"
		} else if strings.HasSuffix(fileName, ".o") && !isTracked(relPath, false, tracked) {
			fileReason = "Compiled object file"
		} else if strings.HasSuffix(fileName, ".test") && lang == "go" {
			fileReason = "Go test binary"
		} else if strings.HasSuffix(fileName, ".prof") || fileName == "cpu.prof" || fileName == "mem.prof" {
			fileReason = "CPU/Memory profiling dump"
		} else if strings.HasSuffix(fileName, ".pyc") || strings.HasSuffix(fileName, ".pyo") {
			fileReason = "Compiled Python bytecode"
		} else if strings.HasSuffix(fileName, ".class") {
			fileReason = "Compiled Java class file"
		}

		// 2. Untracked standalone compiled binaries in Go folders
		if fileReason == "" && lang == "go" {
			// Check if file has no extension and is an executable
			if !strings.Contains(fileName, ".") {
				if info, err := d.Info(); err == nil && info.Mode()&0111 != 0 {
					// It is an executable binary without extension
					if !isTracked(relPath, false, tracked) {
						fileReason = "Compiled Go binary"
					}
				}
			}
		}

		if fileReason != "" {
			if !isTracked(relPath, false, tracked) {
				var size int64
				if info, err := d.Info(); err == nil {
					size = info.Size()
				}
				targets = append(targets, CleanTarget{
					Path:     relPath,
					IsDir:    false,
					Language: lang,
					Size:     size,
					Reason:   fileReason,
				})
			}
		}

		return nil
	})

	if err != nil {
		return nil, err
	}

	sort.Slice(targets, func(i, j int) bool {
		return targets[i].Path < targets[j].Path
	})

	return targets, nil
}

func main() {
	var (
		flagDryRun  = flag.Bool("dry-run", false, "Preview files/directories that would be removed without deleting")
		flagDeep    = flag.Bool("deep", false, "Deep clean: also clean dependency caches like node_modules and .spago")
		flagLang    = flag.String("lang", "", "Clean only artifacts for a specific language (e.g. rust, go, dotnet, zig, lean, etc.)")
		flagPath    = flag.String("path", "", "Clean only inside a specific subpath pattern")
		flagVerbose = flag.Bool("v", false, "Verbose output: print each cleaned item with details")
		flagNoColor = flag.Bool("no-color", false, "Disable color output")
	)
	flag.BoolVar(flagDryRun, "n", false, "Alias for -dry-run")
	flag.Parse()

	if *flagNoColor || os.Getenv("NO_COLOR") != "" {
		disableColors()
	}

	root, err := findRepoRoot()
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error locating repository root: %v\n", err)
		os.Exit(1)
	}

	tracked, err := loadTrackedFiles(root)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Warning: could not query git tracked files: %v (continuing with cautious checks)\n", err)
		tracked = make(map[string]bool)
	}

	allTargets, err := scanTargets(root, *flagDeep, tracked)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error scanning for clean targets: %v\n", err)
		os.Exit(1)
	}

	// Filter targets
	var filtered []CleanTarget
	filterLang := strings.ToLower(strings.TrimSpace(*flagLang))
	filterPath := strings.ToLower(strings.TrimSpace(*flagPath))

	for _, t := range allTargets {
		if filterLang != "" {
			if filterLang == "dotnet" && (t.Language == "csharp" || t.Language == "fsharp") {
				// match
			} else if strings.ToLower(t.Language) != filterLang {
				continue
			}
		}
		if filterPath != "" {
			if !strings.Contains(strings.ToLower(t.Path), filterPath) {
				continue
			}
		}
		filtered = append(filtered, t)
	}

	modeStr := "Cleanup Mode"
	if *flagDryRun {
		modeStr = "Dry-Run Preview (no files will be deleted)"
	}

	fmt.Printf("\n%s======================================================================%s\n", colorBold, colorReset)
	fmt.Printf("%s  Polyglot Repository Artifact Cleaner%s\n", colorBold, colorReset)
	fmt.Printf("  Workspace : %s%s%s\n", colorCyan, root, colorReset)
	fmt.Printf("  Mode      : %s%s%s\n", colorCyan, modeStr, colorReset)
	if *flagDeep {
		fmt.Printf("  Deep      : %strue (including dependency caches)%s\n", colorYellow, colorReset)
	}
	fmt.Printf("%s======================================================================%s\n\n", colorBold, colorReset)

	if len(filtered) == 0 {
		fmt.Println("No build artifacts found to clean. Workspace is already pristine!")
		return
	}

	var (
		totalDirs  = 0
		totalFiles = 0
		totalBytes int64
		failedList []string
	)

	for _, t := range filtered {
		totalBytes += t.Size
		itemType := "FILE"
		if t.IsDir {
			totalDirs++
			itemType = "DIR "
		} else {
			totalFiles++
		}

		if *flagDryRun {
			if *flagVerbose || len(filtered) <= 30 {
				fmt.Printf("[%sWOULD REMOVE%s] [%s] %-45s %s(%s - %s)%s\n",
					colorYellow, colorReset, itemType, t.Path, colorGray, formatBytes(t.Size), t.Reason, colorReset)
			}
		} else {
			// Actually perform removal
			fullPath := filepath.Join(root, t.Path)
			var removeErr error
			if t.IsDir {
				removeErr = os.RemoveAll(fullPath)
			} else {
				removeErr = os.Remove(fullPath)
			}

			if removeErr != nil {
				failedList = append(failedList, fmt.Sprintf("%s: %v", t.Path, removeErr))
				fmt.Printf("[%sFAIL%s] [%s] %-45s %s(%v)%s\n",
					colorRed, colorReset, itemType, t.Path, colorRed, removeErr, colorReset)
			} else if *flagVerbose || len(filtered) <= 30 {
				fmt.Printf("[%sREMOVED%s]      [%s] %-45s %s(%s)%s\n",
					colorGreen, colorReset, itemType, t.Path, colorGray, formatBytes(t.Size), colorReset)
			}
		}
	}

	// In non-verbose mode with many items, print summary message
	if !*flagVerbose && len(filtered) > 30 {
		fmt.Printf("Processed %d items (%d directories, %d files).\n",
			len(filtered), totalDirs, totalFiles)
	}

	// Summary banner
	actionWord := "Cleaned"
	if *flagDryRun {
		actionWord = "Estimated reclaimable"
	}

	fmt.Printf("\n%s======================================================================%s\n", colorBold, colorReset)
	fmt.Printf("  CLEAN SUMMARY:\n")
	fmt.Printf("  Directories    : %d\n", totalDirs)
	fmt.Printf("  Files          : %d\n", totalFiles)
	fmt.Printf("  Space Freed    : %s%s%s\n", colorBold+colorGreen, formatBytes(totalBytes), colorReset)
	if len(failedList) > 0 {
		fmt.Printf("  %sErrors%s         : %s%d items failed to delete%s\n", colorRed, colorReset, colorRed, len(failedList), colorReset)
	}
	fmt.Printf("  Status         : %s%s%s\n", colorGreen, actionWord, colorReset)
	fmt.Printf("%s======================================================================%s\n\n", colorBold, colorReset)
}
