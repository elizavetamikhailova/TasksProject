package gorm

import (
	"database/sql"
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
		if err == sql.ErrNoRows {
			return nil, nil
		}
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

	var answer entity.FormAnswer
	answersFromDb := t.db.
		Table(fmt.Sprintf(`%s sa`, new(model.TaskForm).AnswersTableName())).
		Select(`sa.question_code, t.title`).
		Joins("join tasks.questions t on (sa.question_code = t.code)").
		Where(`sa.form_id = ?`, taskForm.Id).
		Row()

	err = answersFromDb.Scan(&answer.Code, &answer.Title)

	if err != nil {
		if err == sql.ErrNoRows {
			return nil, nil
		}
		return nil, err
	}

	taskForm.FormAnswer = answer

	return &taskForm, nil
}

func (t TaskForm) InsertStaffAnswers(formId int, questionCode []string, taskId int) error {
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

	return t.db.
		Table(fmt.Sprintf(`%s staff_task`, new(model.Task).TableName())).
		Where(`staff_task.id = ?`, taskId).
		Updates(map[string]interface{}{"updated_at": time.Now(), "state_id": 3}).Error

}

func NewDaoForm(db *gorm.DB) dao.StaffAnswers {
	return &TaskForm{
		db: db,
	}
}
