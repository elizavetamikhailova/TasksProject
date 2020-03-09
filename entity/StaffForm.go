package entity

import "time"

type StaffForm struct {
	StaffId   int
	GroupId   int
	CreatedAt time.Time
	UpdatedAt time.Time
	TaskId    int
}
