package gorm

import (
	"database/sql"
	"fmt"
	"github.com/elizavetamikhailova/TasksProject/dao/gorm/model"
	"github.com/elizavetamikhailova/TasksProject/entity"
	"github.com/jinzhu/gorm"
	"time"
)

type TaskContent struct {
	db *gorm.DB
}

func (t Task) GetTaskContent(taskId int) (*model.TaskContent, error) {
	var taskContent model.TaskContent
	taskContentFromDb := t.db.
		Table(fmt.Sprintf(`%s tc`, new(model.TaskContent).TableName())).
		Select(`tc.text, tc.title, tc.address`).
		Where(`tc.task_id = ?`, taskId).
		Row()

	err := taskContentFromDb.Scan(&taskContent.Text, &taskContent.Title, &taskContent.Address)

	if err != nil {
		if err == sql.ErrNoRows {
			return nil, nil
		}
		return nil, err
	}

	comments, err := t.GetCommentsByTask(taskId)
	if err != nil {
		return nil, err
	}
	taskContent.Comments = comments

	return &taskContent, nil
}

func (t Task) AddTaskContent(taskId int, text string, title string, address string) error {
	content := entity.TaskContent{
		Text:    text,
		Title:   title,
		Address: address,
		TaskId:  taskId,
	}
	return t.db.Create(&content).Scan(&content).Error
}

func (t Task) AddFillTaskForm(taskId int, staffId int, groupId int) error {
	staffForm := entity.StaffForm{
		StaffId:   staffId,
		GroupId:   groupId,
		CreatedAt: time.Time{},
		UpdatedAt: time.Time{},
		TaskId:    taskId,
	}
	return t.db.Table("tasks.staff_form").Create(&staffForm).Scan(&staffForm).Error
}
