package gorm

import (
	"fmt"
	"github.com/elizavetamikhailova/TasksProject/dao"
	"github.com/elizavetamikhailova/TasksProject/dao/gorm/model"
	"github.com/elizavetamikhailova/TasksProject/entity"
	"github.com/jinzhu/gorm"
	"time"
)

type TaskForm struct {
	db *gorm.DB
}

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

func (t TaskForm) InsertStaffAnswers(formId int, questionCode []string) error {
	for _, v := range questionCode {
		staffAnswer := model.StaffAnswers{StaffAnswers: entity.StaffAnswers{
			FormId:       formId,
			QuestionCode: v,
			CreatedAt:    time.Time{},
			UpdatedAt:    time.Time{},
		}}

		err := t.db.Create(&staffAnswer).Scan(&staffAnswer).Error
		if err != nil {
			return err
		}
	}

	return nil
}

func NewDaoForm(db *gorm.DB) dao.StaffAnswers {
	return &TaskForm{
		db: db,
	}
}
