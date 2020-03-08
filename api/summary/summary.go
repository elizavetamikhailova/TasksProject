package summary

import "github.com/elizavetamikhailova/TasksProject/app/summary"

type Summary struct {
	op summary.Summary
}

func NewApiSummary(op summary.Summary) Summary {
	return Summary{op: op}
}
