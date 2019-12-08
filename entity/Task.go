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
	Id	int	`gorm:"column:id"`
	TypeId	int	 `gorm:"column:type_id"`
	StaffId int `gorm:"column:staff_id"`
	StateId int `gorm:"column:state_id"`
	ParentId int `gorm:"column:parent_id"`
	StartedAt time.Time `gorm:"column:started_at"`
	FinishedAt time.Time  `gorm:"column:finished_at"`
	CreatedAt time.Time `gorm:"column:created_at"`
	UpdatedAt time.Time `gorm:"column:updated_at"`
	DeletedAt time.Time `gorm:"column:deleted_at"`
}