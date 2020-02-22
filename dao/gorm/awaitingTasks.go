package gorm

import (
	"fmt"
	"github.com/elizavetamikhailova/TasksProject/dao/gorm/model"
	"github.com/elizavetamikhailova/TasksProject/entity"
	"time"
)

//select awt.task_id, ats.code, tt.code, awt.created_at, st.expected_lead_time, st.difficulty_level
//from tasks.awaiting_tasks awt
//left join tasks.staff_task st on (awt.task_id = st.id)
//join tasks.awaiting_task_state ats on (awt.state_id = ats.id)
//join tasks.task_type tt on (st.type_id = tt.id)

func (t Task) GetAwaitingTask(staffId int,
	updateTime time.Time) ([]entity.GetAwaitingTaskResponse, error) {
	var tasks []entity.GetAwaitingTaskResponse
	tasksFromDb, err := t.db.
		Table(fmt.Sprintf(`%s awt`, new(model.AwaitingTask).TableName())).
		Select(`awt.task_id, ats.code, tt.code, awt.created_at, st.expected_lead_time, st.difficulty_level`).
		Joins("left join tasks.staff_task st on (awt.task_id = st.id)").
		Joins("join tasks.awaiting_task_state ats on (awt.state_id = ats.id)").
		Joins("join tasks.task_type tt on (st.type_id = tt.id)").
		Where(`awt.updated_at > ? and awt.staff_id = ?`, updateTime, staffId).
		Rows()

	if err != nil {
		return nil, err
	}

	for tasksFromDb.Next() {
		var task entity.GetAwaitingTaskResponse
		err := tasksFromDb.Scan(&task.TaskId, &task.StateCode, &task.TypeCode, &task.CreatedAt, &task.ExpectedLeadTime, &task.DifficultyLevel)
		if err != nil {
			return nil, err
		}

		switch task.TypeCode {
		case "TASK":
			task.Content, err = t.GetTaskContent(task.TaskId)
		}

		if err != nil {
			return nil, err
		}

		tasks = append(tasks, task)
	}

	return tasks, nil
}

func (t Task) GetAwaitingTaskForBoss(
	updateTime time.Time,
) ([]entity.GetTasksResponse, error) {
	var tasks []entity.GetTasksResponse

	tasksFromDb, err := t.db.
		Table(fmt.Sprintf(`%s staff_task`, new(model.Task).TableName())).
		Select(`staff_task.id, staff_task.staff_id, staff_task.parent_id, task_type.code, tasks_state.code, staff_task.expected_lead_time, 
				staff_task.difficulty_level, staff_task.started_at, staff_task.finished_at`).
		Joins("join tasks.task_type task_type on (staff_task.type_id = task_type.id)").
		Joins("join tasks.tasks_state tasks_state on(staff_task.state_id = tasks_state.id)").
		Where(`staff_task.updated_at > ? and tasks_state.code = 'AWAITING'`, updateTime).
		Rows()

	if err != nil {
		return nil, err
	}

	for tasksFromDb.Next() {
		var task model.GetTasksResponse
		err := tasksFromDb.Scan(&task.Id, &task.StaffId, &task.ParentId, &task.TypeCode, &task.StateCode, &task.ExpectedLeadTime,
			&task.DifficultyLevel, &task.StartedAt, &task.FinishedAt)
		if err != nil {
			return nil, err
		}

		flags, err := t.GetFlagsByTask(task.Id)
		if err != nil {
			return nil, err
		}

		var taskEntity = entity.GetTasksResponse{
			Id:               task.Id,
			StaffLogin:       task.StaffLogin,
			StaffId:          0,
			ParentId:         task.ParentId,
			TypeCode:         task.TypeCode,
			StateCode:        task.StateCode,
			ExpectedLeadTime: task.ExpectedLeadTime.Float64,
			DifficultyLevel:  task.DifficultyLevel.Int64,
			StartedAt:        task.StartedAt.Time,
			FinishedAt:       task.FinishedAt.Time,
			Flags:            flags,
		}

		switch taskEntity.TypeCode {
		case "FILL_TASK_FORM":
			taskEntity.Content, err = t.GetTasksForms(taskEntity.Id)
		case "TASK":
			taskEntity.Content, err = t.GetTaskContent(task.Id)
		}

		if err != nil {
			return nil, err
		}

		tasks = append(tasks, taskEntity)
	}

	return tasks, nil
}
