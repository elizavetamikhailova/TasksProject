package model

import (
	"database/sql"
	"github.com/go-sql-driver/mysql"
)

type GetTasksResponse struct {
	Id               int
	StaffId          sql.NullInt64 `json:",omitempty"`
	ParentId         int           `json:",omitempty"`
	TypeCode         string
	StateCode        string
	ExpectedLeadTime sql.NullFloat64 `json:",omitempty"`
	DifficultyLevel  sql.NullInt64   `json:",omitempty"`
	StartedAt        mysql.NullTime  `json:",omitempty"`
	FinishedAt       mysql.NullTime  `json:",omitempty"`
}
