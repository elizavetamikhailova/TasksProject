package model

import "github.com/elizavetamikhailova/TasksProject/entity"

type Task struct {
	entity.Task
}

func (Task) TableName() string {
	return "tasks.staff_task"
}

func (Task) StateChangesName() string {
	return "tasks.task_state_change"
}

func (Task) AwaitingTasksName() string {
	return "tasks.awaiting_tasks"
}
