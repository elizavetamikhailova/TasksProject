package entity

import (
	"time"
)

type GetTasksResponse struct {
	Id               int       `gorm:"column:id"`
	StaffId          int64     `json:",omitempty"`
	ParentId         int       `json:",omitempty"`
	TypeCode         string    `gorm:"column:code"`
	StateCode        string    `gorm:"column:code"`
	ExpectedLeadTime float64   `json:",omitempty"`
	DifficultyLevel  int64     `json:",omitempty"`
	StartedAt        time.Time `gorm:"column:started_at"`
	FinishedAt       time.Time `gorm:"column:finished_at"`
}
