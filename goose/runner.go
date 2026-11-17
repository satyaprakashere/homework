package main

import (
	"flag"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"sort"
	"strings"
	"time"
)

const samplesSource = "/opt/homebrew/Cellar/goose-lang/2026.4/share/goose-lang/samples"

func copyFile(src, dst string) error {
	in, err := os.Open(src)
	if err != nil {
		return err
	}
	defer in.Close()

	out, err := os.Create(dst)
	if err != nil {
		return err
	}
	defer out.Close()

	_, err = io.Copy(out, in)
	return err
}

func copyDir(src, dst string) error {
	entries, err := os.ReadDir(src)
	if err != nil {
		return err
	}
	if err := os.MkdirAll(dst, 0755); err != nil {
		return err
	}
	for _, entry := range entries {
		s := filepath.Join(src, entry.Name())
		d := filepath.Join(dst, entry.Name())
		if entry.IsDir() {
			if err := copyDir(s, d); err != nil {
				return err
			}
		} else {
			if err := copyFile(s, d); err != nil {
				return err
			}
		}
	}
	return nil
}

func syncExamples() error {
	numPrefixRegex := regexp.MustCompile(`^\d+_`)
	entries, err := os.ReadDir(samplesSource)
	if err != nil {
		return fmt.Errorf("failed to read samples source: %w", err)
	}

	// First copy data directory
	dataSrc := filepath.Join(samplesSource, "data")
	if info, err := os.Stat(dataSrc); err == nil && info.IsDir() {
		if err := copyDir(dataSrc, "data"); err != nil {
			return fmt.Errorf("failed to copy data dir: %w", err)
		}
		fmt.Println("Copied data directory.")
	}

	// Copy call_c.h if present
	cHeaderSrc := filepath.Join(samplesSource, "call_c.h")
	if _, err := os.Stat(cHeaderSrc); err == nil {
		if err := copyFile(cHeaderSrc, "call_c.h"); err != nil {
			return fmt.Errorf("failed to copy call_c.h: %w", err)
		}
		fmt.Println("Copied call_c.h.")
	}

	// Copy and rename .goose files
	for _, entry := range entries {
		name := entry.Name()
		if !strings.HasSuffix(name, ".goose") {
			continue
		}

		targetName := numPrefixRegex.ReplaceAllString(name, "")
		srcPath := filepath.Join(samplesSource, name)
		contentBytes, err := os.ReadFile(srcPath)
		if err != nil {
			return fmt.Errorf("error reading %s: %w", name, err)
		}

		content := string(contentBytes)
		// Clean up comments like '01_tour.goose' to 'tour.goose'
		cleanContent := regexp.MustCompile(`\b\d\d_([a-zA-Z0-9_]+)\.goose\b`).ReplaceAllString(content, "$1.goose")
		cleanContent = regexp.MustCompile(`\b\d\d_([a-zA-Z0-9_]+)\b`).ReplaceAllString(cleanContent, "$1")

		if err := os.WriteFile(targetName, []byte(cleanContent), 0644); err != nil {
			return fmt.Errorf("error writing %s: %w", targetName, err)
		}
		fmt.Printf("Prepared %s (from %s)\n", targetName, name)
	}

	return nil
}

func listExamples() ([]string, error) {
	files, err := filepath.Glob("*.goose")
	if err != nil {
		return nil, err
	}
	sort.Strings(files)
	return files, nil
}

func runExample(file string) error {
	fmt.Printf("\n=== Running: %s ===\n", file)
	start := time.Now()

	// Threaded examples require native build via C compiler rather than in-process JIT
	if file == "mandelbrot_threads.goose" || file == "pool_worker_snapshots.goose" {
		binName := strings.TrimSuffix(file, ".goose")
		buildCmd := exec.Command("goose", "build", file)
		buildCmd.Stdout = os.Stdout
		buildCmd.Stderr = os.Stderr
		if err := buildCmd.Run(); err != nil {
			fmt.Printf("--- Build Failed [%s]: %v\n", file, err)
			return err
		}
		defer os.Remove(binName)

		runCmd := exec.Command("./" + binName)
		runCmd.Stdout = os.Stdout
		runCmd.Stderr = os.Stderr
		err := runCmd.Run()
		elapsed := time.Since(start)
		if err != nil {
			fmt.Printf("--- Failed [%s] after %v: %v\n", file, elapsed, err)
			return err
		}
		fmt.Printf("--- Success [%s] (%v)\n", file, elapsed)
		return nil
	}

	cmd := exec.Command("goose", file)
	// Some examples read from data or need args
	if file == "calc.goose" {
		if f, err := os.Open("data/calc.stdin"); err == nil {
			cmd.Stdin = f
			defer f.Close()
		}
	} else if file == "call_c.goose" {
		cmd = exec.Command("goose", "--include", "call_c.h", file)
	}

	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	err := cmd.Run()
	elapsed := time.Since(start)
	if err != nil {
		fmt.Printf("--- Failed [%s] after %v: %v\n", file, elapsed, err)
		return err
	}
	fmt.Printf("--- Success [%s] (%v)\n", file, elapsed)
	return nil
}

func main() {
	syncCmd := flag.Bool("sync", false, "Sync and clean example files from installed Goose samples")
	runAllCmd := flag.Bool("all", false, "Run all non-interactive console examples")
	flag.Parse()

	if *syncCmd {
		if err := syncExamples(); err != nil {
			fmt.Fprintf(os.Stderr, "Sync error: %v\n", err)
			os.Exit(1)
		}
		return
	}

	args := flag.Args()
	if len(args) > 0 {
		target := args[0]
		if !strings.HasSuffix(target, ".goose") {
			target += ".goose"
		}
		if err := runExample(target); err != nil {
			os.Exit(1)
		}
		return
	}

	if *runAllCmd {
		examples, err := listExamples()
		if err != nil {
			fmt.Fprintf(os.Stderr, "Error listing examples: %v\n", err)
			os.Exit(1)
		}

		// GUI / heavy graphic samples that might open windows or need specific input:
		skipList := map[string]bool{
			"gfx_cube.goose":            true,
			"physics_boxes.goose":       true,
			"ui_todo.goose":             true,
			"mini_minecraft.goose":      true,
			"mini_doom.goose":           true,
			"mandelbrot_threads.goose":  false, // run
			"raytrace.goose":            false, // run
		}

		passed := 0
		failed := 0
		for _, ex := range examples {
			if skipList[ex] {
				fmt.Printf("\n=== Skipping interactive/GUI example: %s ===\n", ex)
				continue
			}
			if err := runExample(ex); err != nil {
				failed++
			} else {
				passed++
			}
		}
		fmt.Printf("\n=========================================\n")
		fmt.Printf("Summary: %d passed, %d failed\n", passed, failed)
		fmt.Printf("=========================================\n")
		return
	}

	examples, _ := listExamples()
	fmt.Println("Available Goose Language Examples (without numbered prefixes):")
	for _, ex := range examples {
		fmt.Printf("  • %s\n", ex)
	}
	fmt.Println("\nUsage:")
	fmt.Println("  go run runner.go <example-name>    # Run a single example (e.g., go run runner.go tour)")
	fmt.Println("  go run runner.go -all              # Run all standard examples")
	fmt.Println("  go run runner.go -sync             # Sync examples from system Goose distribution")
}
