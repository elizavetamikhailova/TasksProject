package model

import "github.com/elizavetamikhailova/TasksProject/entity"

type Task struct {
	entity.Task
}

func (Task) TableName() string {
	return "tasks.staff_task"
}

func (Task) StateChangesTableName() string {
	return "tasks.task_state_change"
}

func (Task) AwaitingTasksTableName() string {
	return "tasks.awaiting_tasks"
}

func (Task) TasksFlagsTableName() string {
	return "tasks.tasks_flags"
}

func (Task) FlagTableName() string {
	return "tasks.flags"
}
