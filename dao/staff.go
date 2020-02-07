package dao

import (
	"github.com/elizavetamikhailova/TasksProject/entity"
	"time"
)

type Staff interface {
	Add(login string,
		phone string,
		passMd5 string) error

	GetStaffLastUpdated(
		staffId int,
		updateTime time.Time,
	) (*entity.Staff, error)

	GetStaffLastUpdatedForBoss(
		updateTime time.Time,
	) ([]entity.Staff, error)
}
