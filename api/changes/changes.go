package changes

import "github.com/elizavetamikhailova/TasksProject/app/changes"

type Changes struct {
	op changes.Changes
}

func NewApiChanges(op changes.Changes) Changes {
	return Changes{op: op}
}
