package gorm

import (
	"fmt"
	"github.com/elizavetamikhailova/TasksProject/dao"
	"github.com/elizavetamikhailova/TasksProject/dao/gorm/model"
	"github.com/elizavetamikhailova/TasksProject/entity"
	"github.com/jinzhu/gorm"
	"time"
)

type Task struct {
	db *gorm.DB
}

/*
SELECT staff_task.id, staff_task.parent_id, task_type.code, tasks_state.code, staff_task.started_at, staff_task.finished_at
FROM tasks.staff_task staff_task
join tasks.task_type task_type on (staff_task.type_id = task_type.id)
join tasks.tasks_state tasks_state on(staff_task.state_id = tasks_state.id)
WHERE (staff_task.staff_id = 1)
*/
func (t Task) GetTasksByStaffId(
	staffId int,
) ([]entity.GetTasksResponse, error) {
	var tasks []entity.GetTasksResponse

	tasksFromDb, err := t.db.
		Table(fmt.Sprintf(`%s staff_task`, new(model.Task).TableName())).
		Select(`staff_task.id, staff_task.parent_id, task_type.code, tasks_state.code, staff_task.started_at, staff_task.finished_at`).
		Joins("join tasks.task_type task_type on (staff_task.type_id = task_type.id)").
		Joins("join tasks.tasks_state tasks_state on(staff_task.state_id = tasks_state.id)").
		Where(`staff_task.staff_id = ?`, staffId).
		Rows()

	if err != nil {
		return nil, err
	}

	for tasksFromDb.Next() {
		var task entity.GetTasksResponse
		err := tasksFromDb.Scan(&task.Id, &task.ParentId, &task.TypeCode, &task.StateCode, &task.StartedAt, &task.FinishedAt)
		if err != nil {
			return nil, err
		}
		tasks = append(tasks, task)
	}

	return tasks, nil
}

func (t Task) GetTasksLastUpdate(
	staffId int,
	updateTime time.Time,
) ([]entity.GetTasksResponse, error) {
	var tasks []entity.GetTasksResponse

	tasksFromDb, err := t.db.
		Table(fmt.Sprintf(`%s staff_task`, new(model.Task).TableName())).
		Select(`staff_task.id, staff_task.parent_id, task_type.code, tasks_state.code, staff_task.expected_lead_time, 
				staff_task.difficulty_level, staff_task.started_at, staff_task.finished_at`).
		Joins("join tasks.task_type task_type on (staff_task.type_id = task_type.id)").
		Joins("join tasks.tasks_state tasks_state on(staff_task.state_id = tasks_state.id)").
		Where(`staff_task.staff_id = ? and staff_task.updated_at > ?`, staffId, updateTime).
		Rows()

	if err != nil {
		return nil, err
	}

	for tasksFromDb.Next() {
		var task model.GetTasksResponse
		err := tasksFromDb.Scan(&task.Id, &task.ParentId, &task.TypeCode, &task.StateCode, &task.ExpectedLeadTime,
			&task.DifficultyLevel, &task.StartedAt, &task.FinishedAt)
		if err != nil {
			return nil, err
		}

		var taskEntity = entity.GetTasksResponse{
			Id:               task.Id,
			ParentId:         task.ParentId,
			TypeCode:         task.TypeCode,
			StateCode:        task.StateCode,
			ExpectedLeadTime: task.ExpectedLeadTime.Float64,
			DifficultyLevel:  task.DifficultyLevel.Int64,
			StartedAt:        task.StartedAt,
			FinishedAt:       task.FinishedAt,
		}

		tasks = append(tasks, taskEntity)
	}

	return tasks, nil
}

func (t Task) AddSubTask(
	typeId int,
	staffId int,
	parentId int,
) error {
	task := model.Task{Task: entity.Task{
		TypeId:    typeId,
		StaffId:   staffId,
		StateId:   1,
		ParentId:  parentId,
		CreatedAt: time.Time{},
	}}
	return t.db.Create(&task).Error
} //staff_task.id, staff_task.parent_id, task_type.code, tasks_state.code, staff_task.started_at, staff_task.finished_at

func (t Task) AddTask(typeId int, staffId int) error {
	task := model.Task{Task: entity.Task{
		TypeId:    typeId,
		StaffId:   staffId,
		StateId:   1,
		CreatedAt: time.Time{},
	}}

	return t.db.Create(&task).Error
}

func (t Task) UpdateTaskExpectedLeadTime(taskId int, newLeadTime int) error {
	return t.db.
		Table(fmt.Sprintf(`%s staff_task`, new(model.Task).TableName())).
		Where(`staff_task.id = ?`, taskId).
		Updates(map[string]interface{}{"updated_at": time.Now(), "expected_lead_time": newLeadTime}).Error
}

func NewDaoTask(db *gorm.DB) dao.Task {
	return &Task{
		db: db,
	}
}
