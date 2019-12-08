package gorm

import (
	"awesomeProject1/dao"
	"awesomeProject1/dao/gorm/model"
	"awesomeProject1/entity"
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
	panic("implement me")
}

func (t Task) AddTask(typeId int, staffId int) error{
	task := model.Task{Task : entity.Task{
		TypeId:     typeId,
		StaffId:    staffId,
		StateId:    1,
		CreatedAt:  time.Time{},
	}}

	return t.db.Create(&task).Error
}

func NewDaoTask(db *gorm.DB) dao.Task{
	return &Task{
		db: db,
	}
}

