package gorm

import (
	"fmt"
	"github.com/elizavetamikhailova/TasksProject/dao"
	"github.com/elizavetamikhailova/TasksProject/dao/gorm/model"
	"github.com/elizavetamikhailova/TasksProject/entity"
	"github.com/jinzhu/gorm"
	"time"
)

type Task struct {
	db *gorm.DB
}

func (t Task) GetTasksByStaffId(
	staffId int,
) ([]entity.Task, error) {
	var tasks []entity.Task

	tasksFromDb, err := t.db.
		Table(fmt.Sprintf(`%s t`, new(model.Task).TableName())).
		Where(`t.staff_id = ?`, staffId).
		Rows()

	if err != nil {
		return nil, err
	}

	for tasksFromDb.Next() {
		var task entity.Task
		err := tasksFromDb.Scan(&task.Id, &task.TypeId, &task.StaffId, &task.StateId, &task.ParentId, &task.StartedAt, &task.FinishedAt, &task.CreatedAt, &task.UpdatedAt, &task.DeletedAt)
		if err != nil {
			return nil, err
		}
		tasks = append(tasks, task)
	}

	return tasks, nil
}

func (t Task) AddSubTask(
	typeId int,
	staffId int,
	parentId int,
) error {
	task := model.Task{Task: entity.Task{
		TypeId:    typeId,
		StaffId:   staffId,
		StateId:   1,
		ParentId:  parentId,
		CreatedAt: time.Time{},
	}}
	return t.db.Create(&task).Error
}

func (t Task) AddTask(typeId int, staffId int) error {
	task := model.Task{Task: entity.Task{
		TypeId:    typeId,
		StaffId:   staffId,
		StateId:   1,
		CreatedAt: time.Time{},
	}}

	return t.db.Create(&task).Error
}

func NewDaoTask(db *gorm.DB) dao.Task {
	return &Task{
		db: db,
	}
}
