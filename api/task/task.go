package task

import "awesomeProject1/app/task"

type Task struct {
	op task.Task
}

func NewApiTask(op task.Task) Task{
	return Task{op: op}
}
