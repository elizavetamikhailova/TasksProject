package dao

import "github.com/elizavetamikhailova/TasksProject/dao/gorm/model"

type Summary interface {
	GetMostProductiveStaff() ([]model.MostProductiveStaff, error)
	GetMostActiveStaff() ([]model.MostActiveStaff, error)
	GetMostLatenessStaff() ([]model.MostLatenessStaff, error)
	GetMostProcrastinatingStaff() ([]model.MostProcratinatingStaff, error)
	GetMostCancelStaff() ([]model.MostCancelStaff, error)
}
