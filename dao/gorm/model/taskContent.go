package model

import "github.com/elizavetamikhailova/TasksProject/entity"

type TaskContent struct {
	entity.TaskContent
}

func (TaskContent) TableName() string {
	return "tasks.task_content"
}
