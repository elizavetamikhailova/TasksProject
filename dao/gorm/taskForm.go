package gorm

import (
	"fmt"
	"github.com/elizavetamikhailova/TasksProject/dao/gorm/model"
	"github.com/elizavetamikhailova/TasksProject/entity"
)

func (t Task) GetTasksForms(taskId int) (*entity.TaskForm, error) {
	var taskForm entity.TaskForm
	taskFormFromDb := t.db.
		Table(fmt.Sprintf(`%s sf`, new(model.TaskForm).TableName())).
		Select(`sf.task_id, qg.code, qg.title, sf.id, qg.id`).
		Joins("join tasks.question_group qg on (sf.group_id = qg.id)").
		Where(`sf.task_id = ?`, taskId).
		Row()

	err := taskFormFromDb.Scan(&taskForm.TaskId, &taskForm.GroupCode, &taskForm.GroupTitle, &taskForm.Id, &taskForm.GroupId)

	if err != nil {
		return nil, err
	}

	var questions []entity.FormQuestions
	questionsFromDb, err := t.db.
		Table(fmt.Sprintf(`%s q`, new(model.TaskForm).QuestionsTableName())).
		Select(`q.code, q.title`).
		Where(`q.group_id = ?`, taskForm.GroupId).Rows()

	if err != nil {
		return nil, err
	}

	for questionsFromDb.Next() {
		var question entity.FormQuestions
		err := questionsFromDb.Scan(&question.Code, &question.Title)
		if err != nil {
			return nil, err
		}
		questions = append(questions, question)
	}

	taskForm.FormQuestions = questions

	return &taskForm, nil
}
