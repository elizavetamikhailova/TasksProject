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
	TypeId  int `valid:"required"`
	StaffId int `valid:"required"`
}

type ArgAddSubTask struct {
	TypeId   int `valid:"required"`
	StaffId  int `valid:"required"`
	ParentId int `valid:"required"`
}

func (t *Task) AddTask(arg ArgAddTask) error {
	return t.taskDAO.AddTask(arg.TypeId, arg.StaffId)
}

func (t *Task) AddSubTask(arg ArgAddSubTask) error {
	return t.taskDAO.AddSubTask(arg.TypeId, arg.StaffId, arg.ParentId)
}
