package dao

import (
	"github.com/elizavetamikhailova/TasksProject/entity"
	"time"
)

type AwaitingTask interface {
	GetAwaitingTask(staffId int,
		updateTime time.Time) ([]entity.GetAwaitingTaskResponse, error)
}
