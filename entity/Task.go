package entity

import "time"

/*
id
type_id
staff_id
parent_id
started_at
finished_at
created_at
updated_at
deleted_at
*/

type Task struct {
	Id               int        `gorm:"column:id"`
	TypeId           int        `gorm:"column:type_id"`
	StaffId          int        `gorm:"column:staff_id"`
	StateId          int        `gorm:"column:state_id"`
	ParentId         int        `json:",omitempty"`
	StartedAt        time.Time  `gorm:"column:started_at"`
	FinishedAt       time.Time  `json:",omitempty"`
	CreatedAt        time.Time  `gorm:"column:created_at"`
	UpdatedAt        time.Time  `json:",omitempty"`
	DeletedAt        *time.Time `json:",omitempty"`
	ExpectedLeadTime float64    `json:",omitempty"`
	DifficultyLevel  int64      `json:",omitempty"`
}
