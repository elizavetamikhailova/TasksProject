package entity

import "time"

type AwaitingTask struct {
	Id        int
	TaskId    int
	StaffId   int
	StateId   int
	CreatedAt time.Time
	UpdatedAt time.Time
	DeletedAt *time.Time
}
