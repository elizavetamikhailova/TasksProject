package task

import "github.com/elizavetamikhailova/TasksProject/app/task"

type Task struct {
	op task.Task
}

func NewApiTask(op task.Task) Task {
	return Task{op: op}
}
