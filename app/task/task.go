package task

import (
	"github.com/elizavetamikhailova/TasksProject/dao"
	"github.com/elizavetamikhailova/TasksProject/entity"
)

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

type ArgGet struct {
	Id int `valid:"required"`
}

type Data struct {
	entity.GetTasksResponse
}

func (t *Task) AddTask(arg ArgAddTask) error {
	return t.taskDAO.AddTask(arg.TypeId, arg.StaffId)
}

func (t *Task) AddSubTask(arg ArgAddSubTask) error {
	return t.taskDAO.AddSubTask(arg.TypeId, arg.StaffId, arg.ParentId)
}

func (t *Task) GetTask(arg ArgGet) ([]Data, error) {
	tasks, err := t.taskDAO.GetTasksByStaffId(arg.Id)
	if err != nil {
		return nil, err
	}
	ud := make([]Data, len(tasks))

	for k, v := range tasks {
		ud[k].GetTasksResponse = v
	}

	return ud, nil
}
