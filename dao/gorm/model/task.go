package model

import "awesomeProject1/entity"

type Task struct {
	entity.Task
}

func (Task) TableName() string {
	return "tasks.staff_task"
}