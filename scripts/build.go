package main

import (
	"bytes"
	"context"
	"encoding/json"
	"flag"
	"fmt"
	"io/fs"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"sort"
	"strings"
	"sync"
	"time"
)

// Status represents the build result status.
type Status string

const (
	StatusPassed  Status = "PASSED"
	StatusFailed  Status = "FAILED"
	StatusSkipped Status = "SKIPPED"
)

// Project represents a discovered buildable project.
type Project struct {
	Name        string   `json:"name"`
	Path        string   `json:"path"`        // relative to repo root
	Language    string   `json:"language"`    // e.g. rust, go, csharp, fsharp, zig, lean, etc.
	Tool        string   `json:"tool"`        // compiler or build tool executable
	CheckArgs   []string `json:"check_args"`  // fast verification args
	BuildArgs   []string `json:"build_args"`  // full build args
	SkipReason  string   `json:"skip_reason,omitempty"`
}

// Result holds the outcome of building a project.
type Result struct {
	Project  Project       `json:"project"`
	Status   Status        `json:"status"`
	Duration time.Duration `json:"duration"`
	Output   string        `json:"output,omitempty"`
	Error    string        `json:"error,omitempty"`
}

// Colors for terminal output
var (
	colorReset  = "\033[0m"
	colorRed    = "\033[31m"
	colorGreen  = "\033[32m"
	colorYellow = "\033[33m"
	colorBlue   = "\033[34m"
	colorPurple = "\033[35m"
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
	colorPurple = ""
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
	// Fallback to current working directory
	return os.Getwd()
}

// hasTool checks if an executable exists in PATH.
func hasTool(name string) bool {
	_, err := exec.LookPath(name)
	return err == nil
}

// discoverProjects scans the repository for buildable projects across languages.
func discoverProjects(root string) ([]Project, error) {
	var projects []Project
	seenPaths := make(map[string]bool)

	// Directories to ignore during walk
	ignoredDirs := map[string]bool{
		".git":          true,
		".jj":           true,
		".venv":         true,
		".pixi":         true,
		"node_modules":  true,
		"target":        true,
		"dist":          true,
		"dist-newstyle": true,
		".stack-work":   true,
		".lake":         true,
		"_build":        true,
		"build":         true,
		"zig-out":       true,
		".zig-cache":    true,
		"zig-pkg":       true,
		"bin":           true,
		"obj":           true,
		".spago":        true,
		".scala-build":  true,
	}

	err := filepath.WalkDir(root, func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return nil
		}

		relPath, relErr := filepath.Rel(root, path)
		if relErr != nil {
			relPath = path
		}

		if d.IsDir() {
			base := d.Name()
			if ignoredDirs[base] || strings.HasPrefix(base, ".") && base != "." {
				return filepath.SkipDir
			}
			return nil
		}

		dir := filepath.Dir(relPath)
		fileName := d.Name()

		// 1. Rust: Cargo.toml
		if fileName == "Cargo.toml" {
			// Avoid duplicates if workspace members are discovered
			fullPath := filepath.Join(root, relPath)
			content, readErr := os.ReadFile(fullPath)
			isWorkspace := readErr == nil && strings.Contains(string(content), "[workspace]")

			// Check if this Cargo.toml is an unconfigured subproject inside a parent workspace
			parentDir := filepath.Dir(dir)
			parentCargo := filepath.Join(root, parentDir, "Cargo.toml")
			hasParentWorkspace := false
			if parentCargoContent, err := os.ReadFile(parentCargo); err == nil {
				if strings.Contains(string(parentCargoContent), "[workspace]") {
					hasParentWorkspace = true
				}
			}

			// If parent is a workspace and this is not a separate workspace, let the parent workspace handle it
			if hasParentWorkspace && !isWorkspace {
				return nil
			}

			if !seenPaths[dir] {
				seenPaths[dir] = true
				projects = append(projects, Project{
					Name:      filepath.Base(dir),
					Path:      dir,
					Language:  "rust",
					Tool:      "cargo",
					CheckArgs: []string{"check"},
					BuildArgs: []string{"build"},
				})
			}
		}

		// 2. Go: go.mod
		if fileName == "go.mod" {
			// Verify go.mod is valid and non-empty
			fullModPath := filepath.Join(root, relPath)
			content, readErr := os.ReadFile(fullModPath)
			if readErr == nil && len(strings.TrimSpace(string(content))) > 0 && strings.Contains(string(content), "module ") {
				if !seenPaths[dir] {
					seenPaths[dir] = true
					projects = append(projects, Project{
						Name:      filepath.Base(dir),
						Path:      dir,
						Language:  "go",
						Tool:      "go",
						CheckArgs: []string{"vet", "./..."},
						BuildArgs: []string{"build", "./..."},
					})
				}
			}
		}

		// 3. .NET C#: *.csproj
		if strings.HasSuffix(fileName, ".csproj") {
			if !seenPaths[relPath] {
				seenPaths[relPath] = true
				projects = append(projects, Project{
					Name:      strings.TrimSuffix(fileName, ".csproj"),
					Path:      dir,
					Language:  "csharp",
					Tool:      "dotnet",
					CheckArgs: []string{"build", fileName, "-c", "Debug", "--nologo"},
					BuildArgs: []string{"build", fileName, "-c", "Release", "--nologo"},
				})
			}
		}

		// 4. .NET F#: *.fsproj
		if strings.HasSuffix(fileName, ".fsproj") {
			if !seenPaths[relPath] {
				seenPaths[relPath] = true
				projects = append(projects, Project{
					Name:      strings.TrimSuffix(fileName, ".fsproj"),
					Path:      dir,
					Language:  "fsharp",
					Tool:      "dotnet",
					CheckArgs: []string{"build", fileName, "-c", "Debug", "--nologo"},
					BuildArgs: []string{"build", fileName, "-c", "Release", "--nologo"},
				})
			}
		}

		// 5. Zig: build.zig
		if fileName == "build.zig" {
			if !seenPaths[dir] {
				seenPaths[dir] = true
				projects = append(projects, Project{
					Name:      filepath.Base(dir),
					Path:      dir,
					Language:  "zig",
					Tool:      "zig",
					CheckArgs: []string{"build"},
					BuildArgs: []string{"build", "-Doptimize=ReleaseFast"},
				})
			}
		}

		// 6. Lean 4: lakefile.toml or lakefile.lean
		if fileName == "lakefile.toml" || fileName == "lakefile.lean" {
			if !seenPaths[dir] {
				seenPaths[dir] = true
				projects = append(projects, Project{
					Name:      filepath.Base(dir),
					Path:      dir,
					Language:  "lean",
					Tool:      "lake",
					CheckArgs: []string{"build"},
					BuildArgs: []string{"build"},
				})
			}
		}

		// 7. Gleam: gleam.toml
		if fileName == "gleam.toml" {
			if !seenPaths[dir] {
				seenPaths[dir] = true
				projects = append(projects, Project{
					Name:      filepath.Base(dir),
					Path:      dir,
					Language:  "gleam",
					Tool:      "gleam",
					CheckArgs: []string{"check"},
					BuildArgs: []string{"build"},
				})
			}
		}

		// 8. OCaml: dune-project
		if fileName == "dune-project" {
			if !seenPaths[dir] {
				seenPaths[dir] = true
				projects = append(projects, Project{
					Name:      filepath.Base(dir),
					Path:      dir,
					Language:  "ocaml",
					Tool:      "dune",
					CheckArgs: []string{"build"},
					BuildArgs: []string{"build", "@all"},
				})
			}
		}

		// 9. Java Maven: pom.xml
		if fileName == "pom.xml" {
			if !seenPaths[dir] {
				seenPaths[dir] = true
				projects = append(projects, Project{
					Name:      filepath.Base(dir),
					Path:      dir,
					Language:  "java",
					Tool:      "mvn",
					CheckArgs: []string{"test-compile", "-q"},
					BuildArgs: []string{"package", "-DskipTests", "-q"},
				})
			}
		}

		// 10. Kotlin / Gradle: build.gradle.kts or build.gradle
		if fileName == "build.gradle.kts" || fileName == "build.gradle" {
			// Prefer project root gradle file
			if !seenPaths[dir] {
				seenPaths[dir] = true
				projects = append(projects, Project{
					Name:      filepath.Base(dir),
					Path:      dir,
					Language:  "kotlin",
					Tool:      "gradle",
					CheckArgs: []string{"classes", "-q"},
					BuildArgs: []string{"build", "-x", "test", "-q"},
				})
			}
		}

		// 11. Haskell Cabal
		if strings.HasSuffix(fileName, ".cabal") {
			if !seenPaths[dir] {
				seenPaths[dir] = true
				projects = append(projects, Project{
					Name:      strings.TrimSuffix(fileName, ".cabal"),
					Path:      dir,
					Language:  "haskell",
					Tool:      "cabal",
					CheckArgs: []string{"build", "--dry-run"},
					BuildArgs: []string{"build"},
				})
			}
		}

		return nil
	})

	if err != nil {
		return nil, err
	}

	// Add special standalone verifications if files exist
	// Typst document
	typstDoc := filepath.Join("typst", "HariPath.typ")
	if _, err := os.Stat(filepath.Join(root, typstDoc)); err == nil {
		projects = append(projects, Project{
			Name:      "HariPath",
			Path:      "typst",
			Language:  "typst",
			Tool:      "typst",
			CheckArgs: []string{"compile", "HariPath.typ", "-f", "pdf", "/dev/null"},
			BuildArgs: []string{"compile", "HariPath.typ", "HariPath.pdf"},
		})
	}

	// Odin check
	odinFile := filepath.Join("odin", "fib.odin")
	if _, err := os.Stat(filepath.Join(root, odinFile)); err == nil {
		projects = append(projects, Project{
			Name:      "odin-samples",
			Path:      "odin",
			Language:  "odin",
			Tool:      "odin",
			CheckArgs: []string{"check", "fib.odin", "-file"},
			BuildArgs: []string{"build", "fib.odin", "-file", "-out:/dev/null"},
		})
	}

	// Sort projects by Language, then Path
	sort.Slice(projects, func(i, j int) bool {
		if projects[i].Language == projects[j].Language {
			return projects[i].Path < projects[j].Path
		}
		return projects[i].Language < projects[j].Language
	})

	return projects, nil
}

// buildProject executes the build/check command for a project.
func buildProject(ctx context.Context, root string, p Project, fullBuild bool, verbose bool) Result {
	start := time.Now()
	res := Result{Project: p}

	// 1. Check if required toolchain is available
	if !hasTool(p.Tool) {
		res.Status = StatusSkipped
		res.Duration = time.Since(start)
		res.Error = fmt.Sprintf("tool '%s' not found in PATH", p.Tool)
		return res
	}

	// 2. Select args based on fast vs full build
	args := p.CheckArgs
	if fullBuild && len(p.BuildArgs) > 0 {
		args = p.BuildArgs
	}

	// 3. Prepare command
	workDir := filepath.Join(root, p.Path)
	cmd := exec.CommandContext(ctx, p.Tool, args...)
	cmd.Dir = workDir

	var outputBuf bytes.Buffer
	cmd.Stdout = &outputBuf
	cmd.Stderr = &outputBuf

	err := cmd.Run()
	res.Duration = time.Since(start)
	res.Output = strings.TrimSpace(outputBuf.String())

	if err != nil {
		res.Status = StatusFailed
		if ctx.Err() == context.DeadlineExceeded {
			res.Error = "build timed out"
		} else {
			res.Error = err.Error()
		}
	} else {
		res.Status = StatusPassed
	}

	return res
}

func main() {
	var (
		flagLang        = flag.String("lang", "", "Filter projects by language (e.g. rust, go, csharp, fsharp, zig, lean, gleam, ocaml, etc.)")
		flagProject     = flag.String("project", "", "Filter projects matching name or path substring")
		flagBuild       = flag.Bool("build", false, "Run full build instead of fast verification check")
		flagConcurrency = flag.Int("j", 4, "Number of concurrent builds")
		flagTimeout     = flag.Duration("timeout", 4*time.Minute, "Timeout per project build")
		flagVerbose     = flag.Bool("v", false, "Verbose output, showing compiler outputs even on success")
		flagList        = flag.Bool("list", false, "List discovered projects and exit without building")
		flagJSON        = flag.Bool("json", false, "Output results in JSON format")
		flagNoColor     = flag.Bool("no-color", false, "Disable color output")
	)
	flag.Parse()

	if *flagNoColor || os.Getenv("NO_COLOR") != "" {
		disableColors()
	}

	root, err := findRepoRoot()
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error locating repository root: %v\n", err)
		os.Exit(1)
	}

	allProjects, err := discoverProjects(root)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error discovering projects: %v\n", err)
		os.Exit(1)
	}

	// Filter projects
	var targets []Project
	filterLang := strings.ToLower(strings.TrimSpace(*flagLang))
	filterProject := strings.ToLower(strings.TrimSpace(*flagProject))

	for _, p := range allProjects {
		if filterLang != "" {
			// Allow "dotnet" to match both csharp and fsharp
			if filterLang == "dotnet" && (p.Language == "csharp" || p.Language == "fsharp") {
				// match
			} else if strings.ToLower(p.Language) != filterLang {
				continue
			}
		}
		if filterProject != "" {
			nameLower := strings.ToLower(p.Name)
			pathLower := strings.ToLower(p.Path)
			if !strings.Contains(nameLower, filterProject) && !strings.Contains(pathLower, filterProject) {
				continue
			}
		}
		targets = append(targets, p)
	}

	// If -list flag is passed, print discovered projects
	if *flagList {
		fmt.Printf("%sDiscovered %d buildable projects in %s:%s\n\n", colorBold, len(targets), root, colorReset)
		fmt.Printf("%-12s %-22s %-10s %s\n", "LANGUAGE", "PROJECT", "TOOL", "PATH")
		fmt.Println(strings.Repeat("-", 75))
		for _, p := range targets {
			fmt.Printf("%-12s %-22s %-10s %s\n", p.Language, p.Name, p.Tool, p.Path)
		}
		return
	}

	if len(targets) == 0 {
		fmt.Println("No matching projects found.")
		return
	}

	if !*flagJSON {
		modeStr := "Fast Check"
		if *flagBuild {
			modeStr = "Full Build"
		}
		fmt.Printf("\n%s======================================================================%s\n", colorBold, colorReset)
		fmt.Printf("%s  Polyglot Project Build Runner%s\n", colorBold, colorReset)
		fmt.Printf("  Workspace : %s%s%s\n", colorCyan, root, colorReset)
		fmt.Printf("  Projects  : %s%d%s\n", colorCyan, len(targets), colorReset)
		fmt.Printf("  Mode      : %s%s%s\n", colorCyan, modeStr, colorReset)
		fmt.Printf("  Threads   : %s%d%s\n", colorCyan, *flagConcurrency, colorReset)
		fmt.Printf("%s======================================================================%s\n\n", colorBold, colorReset)
	}

	// Setup worker pool
	concurrency := *flagConcurrency
	if concurrency <= 0 {
		concurrency = runtime.NumCPU()
	}
	if concurrency > len(targets) {
		concurrency = len(targets)
	}

	type task struct {
		project Project
	}

	taskChan := make(chan task, len(targets))
	resultChan := make(chan Result, len(targets))

	var wg sync.WaitGroup
	overallStart := time.Now()

	for i := 0; i < concurrency; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			for t := range taskChan {
				ctx, cancel := context.WithTimeout(context.Background(), *flagTimeout)
				res := buildProject(ctx, root, t.project, *flagBuild, *flagVerbose)
				cancel()
				resultChan <- res
			}
		}()
	}

	for _, p := range targets {
		taskChan <- task{project: p}
	}
	close(taskChan)

	// Close resultChan when all workers finish
	go func() {
		wg.Wait()
		close(resultChan)
	}()

	var results []Result
	var (
		passedCount  = 0
		failedCount  = 0
		skippedCount = 0
	)

	// Live progress output
	for res := range resultChan {
		results = append(results, res)
		switch res.Status {
		case StatusPassed:
			passedCount++
			if !*flagJSON {
				fmt.Printf("[%sPASS%s] [%-8s] %-35s %s(%s)%s\n",
					colorGreen, colorReset, res.Project.Language, res.Project.Path, colorGray, res.Duration.Round(time.Millisecond), colorReset)
				if *flagVerbose && res.Output != "" {
					fmt.Printf("%s%s%s\n", colorGray, indent(res.Output, "    "), colorReset)
				}
			}
		case StatusFailed:
			failedCount++
			if !*flagJSON {
				fmt.Printf("[%sFAIL%s] [%-8s] %-35s %s(%s)%s\n",
					colorRed, colorReset, res.Project.Language, res.Project.Path, colorGray, res.Duration.Round(time.Millisecond), colorReset)
			}
		case StatusSkipped:
			skippedCount++
			if !*flagJSON {
				fmt.Printf("[%sSKIP%s] [%-8s] %-35s %s(%s)%s\n",
					colorYellow, colorReset, res.Project.Language, res.Project.Path, colorGray, res.Error, colorReset)
			}
		}
	}

	// Sort results for consistent summary report
	sort.Slice(results, func(i, j int) bool {
		if results[i].Project.Language == results[j].Project.Language {
			return results[i].Project.Path < results[j].Project.Path
		}
		return results[i].Project.Language < results[j].Project.Language
	})

	totalDuration := time.Since(overallStart)

	if *flagJSON {
		type Summary struct {
			Total    int           `json:"total"`
			Passed   int           `json:"passed"`
			Failed   int           `json:"failed"`
			Skipped  int           `json:"skipped"`
			Duration time.Duration `json:"duration"`
			Results  []Result      `json:"results"`
		}
		summary := Summary{
			Total:    len(targets),
			Passed:   passedCount,
			Failed:   failedCount,
			Skipped:  skippedCount,
			Duration: totalDuration,
			Results:  results,
		}
		enc := json.NewEncoder(os.Stdout)
		enc.SetIndent("", "  ")
		_ = enc.Encode(summary)
		if failedCount > 0 {
			os.Exit(1)
		}
		return
	}

	// Print failure details if any failed
	if failedCount > 0 {
		fmt.Printf("\n%s----------------------------------------------------------------------%s\n", colorRed, colorReset)
		fmt.Printf("%s  BUILD FAILURE DETAILS (%d project(s) failed):%s\n", colorBold+colorRed, failedCount, colorReset)
		fmt.Printf("%s----------------------------------------------------------------------%s\n", colorRed, colorReset)
		for _, res := range results {
			if res.Status == StatusFailed {
				fmt.Printf("\n%s● [%s] %s%s (tool: %s %s)\n",
					colorBold+colorRed, res.Project.Language, res.Project.Path, colorReset,
					res.Project.Tool, strings.Join(res.Project.CheckArgs, " "))
				if res.Error != "" {
					fmt.Printf("  %sError:%s %s\n", colorBold, colorReset, res.Error)
				}
				if res.Output != "" {
					fmt.Printf("  %sOutput:%s\n%s\n", colorBold, colorReset, indent(res.Output, "    "))
				}
			}
		}
	}

	// Final summary banner
	fmt.Printf("\n%s======================================================================%s\n", colorBold, colorReset)
	fmt.Printf("  BUILD SUMMARY:\n")
	fmt.Printf("  Total Projects : %d\n", len(targets))
	fmt.Printf("  %sPassed%s         : %s%d%s\n", colorGreen, colorReset, colorGreen, passedCount, colorReset)
	if failedCount > 0 {
		fmt.Printf("  %sFailed%s         : %s%d%s\n", colorRed, colorReset, colorRed, failedCount, colorReset)
	} else {
		fmt.Printf("  Failed         : 0\n")
	}
	if skippedCount > 0 {
		fmt.Printf("  %sSkipped%s        : %s%d%s\n", colorYellow, colorReset, colorYellow, skippedCount, colorReset)
	}
	fmt.Printf("  Total Duration : %s\n", totalDuration.Round(time.Millisecond))
	fmt.Printf("%s======================================================================%s\n\n", colorBold, colorReset)

	if failedCount > 0 {
		os.Exit(1)
	}
}

func indent(text, prefix string) string {
	lines := strings.Split(text, "\n")
	for i, line := range lines {
		lines[i] = prefix + line
	}
	return strings.Join(lines, "\n")
}
