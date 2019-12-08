package model

import "github.com/elizavetamikhailova/TasksProject/entity"

type Staff struct {
	entity.Staff
}

func (Staff) TableName() string {
	return "tasks.staff"
}
