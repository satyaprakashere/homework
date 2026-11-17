package main

import (
	"fmt"
	"math"

	engineapi "example.com/go-engine/example/calculator/engine-api"
	"example.com/go-engine/example/calculator/types"
	"go.bytecodealliance.org/cm"
)

func init() {
	engineapi.Exports.Calculate 	= calculate
	engineapi.Exports.ComputeStats 	= computeStats
	engineapi.Exports.FormatReport 	= formatReport
}

func calculate(req types.ComputeRequest) cm.Result[string, float64, string] {
	switch req.Op {
	case types.OperationAdd:
		return cm.OK[cm.Result[string, float64, string]](req.A + req.B)
	case types.OperationSubtract:
		return cm.OK[cm.Result[string, float64, string]](req.A - req.B)
	case types.OperationMultiply:
		return cm.OK[cm.Result[string, float64, string]](req.A * req.B)
	case types.OperationDivide:
		if req.B == 0 {
			return cm.Err[cm.Result[string, float64, string]]("Division by zero in Go Engine")
		}
		return cm.OK[cm.Result[string, float64, string]](req.A / req.B)
	default:
		return cm.Err[cm.Result[string, float64, string]]("Unknown operation")
	}
}

func computeStats(numbers cm.List[float64]) cm.Result[engineapi.StatsShape, types.Stats, string] {
	slice := numbers.Slice()
	if len(slice) == 0 {
		return cm.Err[cm.Result[engineapi.StatsShape, types.Stats, string]]("Empty slice provided")
	}

	minVal := math.MaxFloat64
	maxVal := -math.MaxFloat64
	sum := 0.0

	for _, n := range slice {
		if n < minVal {
			minVal = n
		}
		if n > maxVal {
			maxVal = n
		}
		sum += n
	}

	count := uint32(len(slice))
	mean := sum / float64(count)

	stats := types.Stats{
		Count: count,
		Min:   minVal,
		Max:   maxVal,
		Mean:  mean,
		Sum:   sum,
	}

	return cm.OK[cm.Result[engineapi.StatsShape, types.Stats, string]](stats)
}

func formatReport(title string, data types.Stats) string {
	return fmt.Sprintf(
		"=== [Go Engine] %s ===\n"+
			"• Count:   %d\n"+
			"• Minimum: %.2f\n"+
			"• Maximum: %.2f\n"+
			"• Sum:     %.2f\n"+
			"• Mean:    %.2f",
		title, data.Count, data.Min, data.Max, data.Sum, data.Mean,
	)
}

func main() {}
