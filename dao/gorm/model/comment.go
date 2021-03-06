package model

import "time"

type Comment struct {
	Id         int
	StaffId    int
	StaffLogin string
	TaskId     int
	Text       string
	CreatedAt  time.Time  `gorm:"column:created_at"`
	DeletedAt  *time.Time `json:",omitempty"`
}
