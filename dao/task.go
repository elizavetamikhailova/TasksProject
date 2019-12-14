package dao

import (
	"github.com/elizavetamikhailova/TasksProject/entity"
	"time"
)

type Task interface {
	AddTask(typeId int,
		staffId int,
		parentId int,
		expectedLeadTime float64,
		difficultyLevel int64,
	) error

	GetTasksByStaffId(
		staffId int,
	) ([]entity.GetTasksResponse, error)

	GetTasksLastUpdate(
		staffId int,
		updateTime time.Time,
	) ([]entity.GetTasksResponse, error)

	UpdateTaskExpectedLeadTime(taskId int, newLeadTime int) error
}
