package model

import "github.com/elizavetamikhailova/TasksProject/entity"

type TaskForm struct {
	entity.TaskForm
}

func (TaskForm) TableName() string {
	return "tasks.staff_form"
}

func (TaskForm) QuestionsTableName() string {
	return "tasks.questions"
}

func (TaskForm) AnswersTableName() string {
	return "tasks.staff_answers"
}
