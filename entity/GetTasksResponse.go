package entity

import "time"

//staff_task.id, staff_task.parent_id, task_type.code, tasks_state.code, staff_task.started_at, staff_task.finished_at

type GetTasksResponse struct {
	Id         int       `gorm:"column:id"`
	ParentId   int       `gorm:"column:parent_id"`
	TypeCode   string    `gorm:"column:code"`
	StateCode  string    `gorm:"column:code"`
	StartedAt  time.Time `gorm:"column:started_at"`
	FinishedAt time.Time `gorm:"column:finished_at"`
}
