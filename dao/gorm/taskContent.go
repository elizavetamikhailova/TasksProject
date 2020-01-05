package gorm

import (
	"database/sql"
	"fmt"
	"github.com/elizavetamikhailova/TasksProject/dao/gorm/model"
	"github.com/elizavetamikhailova/TasksProject/entity"
	"github.com/jinzhu/gorm"
)

type TaskContent struct {
	db *gorm.DB
}

func (t Task) GetTaskContent(taskId int) (*entity.TaskContent, error) {
	var taskContent entity.TaskContent
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

	return &taskContent, nil
}

func (t Task) AddTaskContent(taskId int, text string, title string, address string) error {
	content := model.TaskContent{
		TaskContent: entity.TaskContent{
			Text:    text,
			Title:   title,
			Address: address,
			TaskId:  taskId,
		}}
	return t.db.Create(&content).Scan(&content).Error
}
