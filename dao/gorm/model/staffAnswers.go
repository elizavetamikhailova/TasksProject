package model

import "github.com/elizavetamikhailova/TasksProject/entity"

type StaffAnswers struct {
	entity.StaffAnswers
}

func (StaffAnswers) TableName() string {
	return "tasks.staff_answers"
}
