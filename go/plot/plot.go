	// main.go
package main

import (
	"log"

	"gonum.org/v1/plot"
	"gonum.org/v1/plot/plotter"
	"gonum.org/v1/plot/plotutil"
	"gonum.org/v1/plot/vg"
)

func main() {
	// Create a new plot
	p := plot.New()
	//if err != nil {
	//log.Fatalf("failed to create plot: %v", err)
	//}
	p.Title.Text = "Line Plot Example"
	p.X.Label.Text = "X"
	p.Y.Label.Text = "Y"

	// Sample data
	xs := []float64{1, 2, 3, 4, 5}
	ys := []float64{2, 4, 6, 8, 10}

	// Create plotter.XYs
	pts := make(plotter.XYs, len(xs))
	for i := range xs {
		pts[i].X = xs[i]
		pts[i].Y = ys[i]
	}

	// Add a line plot
	err := plotutil.AddLinePoints(p, "y = 2x", pts)
	if err != nil {
		log.Fatalf("failed to add line: %v", err)
	}

	// Save to PNG
	if err := p.Save(4*vg.Inch, 4*vg.Inch, "line_plot.png"); err != nil {
		log.Fatalf("failed to save plot: %v", err)
	}
}
