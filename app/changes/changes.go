package changes

import (
	"github.com/elizavetamikhailova/TasksProject/dao"
	"github.com/elizavetamikhailova/TasksProject/entity"
	"time"
)

type Changes struct {
	staffDAO dao.Staff
	taskDAO  dao.Task
}

func NewAppChanges(staffDAO dao.Staff, taskDAO dao.Task) Changes {
	return Changes{
		staffDAO: staffDAO,
		taskDAO:  taskDAO,
	}
}

type ArgGetChanges struct {
	StaffId    int       `valid:"required"`
	UpdateTime time.Time `valid:"required"`
}

type Data struct {
	entity.Changes
}

type TaskData struct {
	entity.GetTasksResponse
}

type StaffData struct {
	*entity.Staff
}

func (c *Changes) GetChanges(arg ArgGetChanges) (*Data, error) {

	staff, err := c.staffDAO.GetStaffLastUpdated(arg.StaffId, arg.UpdateTime)
	if err != nil {
		return nil, err
	}

	//sud := StaffData{staff}

	tasks, err := c.taskDAO.GetTasksLastUpdate(arg.StaffId, arg.UpdateTime)
	if err != nil {
		return nil, err
	}
	tud := make([]entity.GetTasksResponse, len(tasks))

	for k, v := range tasks {
		tud[k] = v
	}

	data := &Data{
		entity.Changes{
			Staff: staff,
			Tasks: tud,
		},
	}

	return data, nil
}

//updateTaskLeadTime

type ArgUpdateTaskLeadTime struct {
	StaffId     int       `valid:"required"`
	TaskId      int       `valid:"required"`
	NewLeadTime int       `valid:"required"`
	UpdateTime  time.Time `valid:"required"`
}

func (c *Changes) UpdateTaskExpectedLeadTime(arg ArgUpdateTaskLeadTime) error {
	return c.taskDAO.UpdateTaskExpectedLeadTime(arg.TaskId, arg.NewLeadTime)
}
