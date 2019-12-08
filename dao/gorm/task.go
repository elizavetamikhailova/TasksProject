package gorm

import (
	"github.com/elizavetamikhailova/TasksProject/dao"
	"github.com/elizavetamikhailova/TasksProject/dao/gorm/model"
	"github.com/elizavetamikhailova/TasksProject/entity"
	"github.com/jinzhu/gorm"
	"time"
)

type Task struct {
	db *gorm.DB
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
