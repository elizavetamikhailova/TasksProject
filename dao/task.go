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
		flags []string,
	) error

	AddTaskWithContent(typeId int,
		staffId int,
		parentId int,
		expectedLeadTime float64,
		difficultyLevel int64,
		flags []string,
		content interface{}) error

	GetTasksByStaffId(
		staffId int,
	) ([]entity.GetTasksResponse, error)

	GetTasksLastUpdate(
		staffId int,
		updateTime time.Time,
	) ([]entity.GetTasksResponse, error)

	UpdateTaskExpectedLeadTime(taskId int, newLeadTime float64) error

	UpdateTaskStatus(taskId int, stateTo int) error

	GetStaffWorkLoad(bossId int) ([]entity.Workload, error)

	AddTaskWithAutomaticStaffSelection(bossId int, typeId int, expectedLeadTime float64, difficultyLevel int64, flags []string, content interface{}) error

	GetTasksLastUpdateForBoss(
		updateTime time.Time,
	) ([]entity.GetTasksResponse, error)

	UpdateAwaitingTaskToActive(taskId int, staffId int) error

	UpdateTaskStatusByBoss(taskId int, stateTo int) error

	AddComment(staffId int, taskId int, text string) error

	GetAwaitingTask(staffId int,
		updateTime time.Time) ([]entity.GetAwaitingTaskResponse, error)
}
