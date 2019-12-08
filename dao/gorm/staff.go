package gorm

import (
	"github.com/elizavetamikhailova/TasksProject/dao"
	"github.com/elizavetamikhailova/TasksProject/dao/gorm/model"
	"github.com/elizavetamikhailova/TasksProject/entity"
	"github.com/jinzhu/gorm"
	"time"
)

type Staff struct {
	db *gorm.DB
}

func (s Staff) Add(login string, phone string, passMd5 string) error {

	staff := model.Staff{Staff: entity.Staff{
		Login:     login,
		Phone:     phone,
		PassMd5:   passMd5,
		CreatedAt: time.Time{},
	}}

	return s.db.Create(&staff).Error
}

func NewDaoStaff(db *gorm.DB) dao.Staff {
	return &Staff{
		db: db,
	}
}
