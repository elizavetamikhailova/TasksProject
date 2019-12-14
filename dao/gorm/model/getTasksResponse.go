package model

import (
	"database/sql"
	"time"
)

type GetTasksResponse struct {
	Id               int
	ParentId         int `json:",omitempty"`
	TypeCode         string
	StateCode        string
	ExpectedLeadTime sql.NullFloat64 `json:",omitempty"`
	DifficultyLevel  sql.NullInt64   `json:",omitempty"`
	StartedAt        time.Time
	FinishedAt       time.Time
}
