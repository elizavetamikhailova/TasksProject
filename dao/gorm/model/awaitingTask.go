package model

import (
	"github.com/elizavetamikhailova/TasksProject/entity"
)

type AwaitingTask struct {
	entity.AwaitingTask
}

func (AwaitingTask) TableName() string {
	return "tasks.awaiting_tasks"
}
