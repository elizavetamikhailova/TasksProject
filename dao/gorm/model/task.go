package model

import "github.com/elizavetamikhailova/TasksProject/entity"

type Task struct {
	entity.Task
}

//type Task struct {
//	Id	int	`gorm:"column:id"`
//	TypeId	int	 `gorm:"column:type_id"`
//	StaffId int `gorm:"column:staff_id"`
//	StateId int `gorm:"column:state_id"`
//	ParentId int `json:",omitempty"`
//	ExpectedLeadTime sql.NullFloat64 `json:",omitempty"`
//	DifficultyLevel  sql.NullInt64   `json:",omitempty"`
//	StartedAt time.Time `gorm:"column:started_at"`
//	FinishedAt time.Time  `json:",omitempty"`
//	CreatedAt time.Time `gorm:"column:created_at"`
//	UpdatedAt time.Time `json:",omitempty"`
//	DeletedAt time.Time `json:",omitempty"`
//}

func (Task) TableName() string {
	return "tasks.staff_task"
}
