package dao

import (
	"github.com/elizavetamikhailova/TasksProject/dao/gorm/model"
)

type Boss interface {
	CheckToken(token string) error

	GetAuth(login string, password string, deviceCode string, pushToken string) (string, error)
	GetBossInfo(login string) (*model.Boss, error)
	UpdatePushToken(deviceId string, pushToken string) error
}
