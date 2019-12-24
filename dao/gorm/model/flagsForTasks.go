package model

import "github.com/elizavetamikhailova/TasksProject/entity"

type FlagsForTasks struct {
	entity.Flag
}

func (FlagsForTasks) TableName() string {
	return "tasks.tasks_flags"
}
