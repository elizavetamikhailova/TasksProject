package dao

import (
	"github.com/elizavetamikhailova/TasksProject/entity"
	"time"
)

type Task interface {
	AddTask(typeId int,
		staffId int,
	) error

	AddSubTask(
		typeId int,
		staffId int,
		parentId int,
	) error

	GetTasksByStaffId(
		staffId int,
	) ([]entity.GetTasksResponse, error)

	GetTasksLastUpdate(
		staffId int,
		updateTime time.Time,
	) ([]entity.GetTasksResponse, error)
}
