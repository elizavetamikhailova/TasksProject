package task

import "github.com/elizavetamikhailova/TasksProject/dao"

type Task struct {
	taskDAO dao.Task
}

func NewAppTask(taskDAO dao.Task) Task {
	return Task{
		taskDAO: taskDAO,
	}
}

type ArgAddTask struct {
	TypeId  int `valid:"required" json:"TypeId"`
	StaffId int `valid:"required"`
}

func (t *Task) AddTask(arg ArgAddTask) error {
	return t.taskDAO.AddTask(arg.TypeId, arg.StaffId)
}
