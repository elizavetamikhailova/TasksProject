package dao

import (
	"github.com/elizavetamikhailova/TasksProject/entity"
	"time"
)

type Staff interface {
	Add(bossId int,
		login string,
		phone string,
		passMd5 string) error

	GetStaffLastUpdated(
		staffId int,
		updateTime time.Time,
	) (*entity.Staff, error)

	GetStaffLastUpdatedForBoss(
		bossId int,
		updateTime time.Time,
	) ([]entity.Staff, error)

	CheckToken(token string) error

	GetAuth(login string, password string, deviceCode string, pushToken string) (string, error)
	GetUserInfo(login string) (*entity.Staff, error)
	UpdatePushToken(deviceId string, pushToken string) error
	ChangePassword(staffId int, pass string, oldPass string) error
	ChangeLogin(staffId int, login string) error
	ChangePhone(staffId int, phone string) error
}
