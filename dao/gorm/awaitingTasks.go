package gorm

import (
	"fmt"
	"github.com/elizavetamikhailova/TasksProject/dao"
	"github.com/elizavetamikhailova/TasksProject/dao/gorm/model"
	"github.com/elizavetamikhailova/TasksProject/entity"
	"github.com/jinzhu/gorm"
	"time"
)

type AwaitingTask struct {
	db *gorm.DB
}

//select awt.task_id, ats.code, tt.code, awt.created_at, st.expected_lead_time, st.difficulty_level
//from tasks.awaiting_tasks awt
//left join tasks.staff_task st on (awt.task_id = st.id)
//join tasks.awaiting_task_state ats on (awt.state_id = ats.id)
//join tasks.task_type tt on (st.type_id = tt.id)

func (a AwaitingTask) GetAwaitingTask(staffId int,
	updateTime time.Time) ([]entity.GetAwaitingTaskResponse, error) {
	var tasks []entity.GetAwaitingTaskResponse
	tasksFromDb, err := a.db.
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
		tasks = append(tasks, task)
	}

	return tasks, nil
}

func NewDaoAwaitingTask(db *gorm.DB) dao.AwaitingTask {
	return &AwaitingTask{
		db: db,
	}
}
