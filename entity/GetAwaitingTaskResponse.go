package entity

import "time"

type GetAwaitingTaskResponse struct {
	Id               int `json:",omitempty"`
	TaskId           int
	StateCode        string
	TypeCode         string
	StaffId          int     `json:",omitempty"`
	ExpectedLeadTime float64 `json:",omitempty"`
	DifficultyLevel  int     `json:",omitempty"`
	CreatedAt        time.Time
}
