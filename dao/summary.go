package dao

import "github.com/elizavetamikhailova/TasksProject/dao/gorm/model"

type Summary interface {
	GetMostProductiveStaff() ([]model.MostProductiveStaff, error)
}
