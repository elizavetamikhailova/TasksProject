package api

import (
	changesApi "github.com/elizavetamikhailova/TasksProject/api/changes"
	formApi "github.com/elizavetamikhailova/TasksProject/api/forms"
	staffApi "github.com/elizavetamikhailova/TasksProject/api/staff"
	taskApi "github.com/elizavetamikhailova/TasksProject/api/task"
	"github.com/elizavetamikhailova/TasksProject/app/changes"
	"github.com/elizavetamikhailova/TasksProject/app/forms"
	"github.com/elizavetamikhailova/TasksProject/app/staff"
	"github.com/elizavetamikhailova/TasksProject/app/task"
	"github.com/julienschmidt/httprouter"
	"go.uber.org/dig"
)

type Router struct {
}

func (r *Router) Get(dig *dig.Container) *httprouter.Router {
	router := httprouter.New()

	staffApi1 := staffApi.Staff{}
	if err := dig.Invoke(func(op staff.Staff) {
		staffApi1 = staffApi.NewApiStaff(op)
	}); err != nil {
		panic(err)
	}

	taskApi1 := taskApi.Task{}
	if err := dig.Invoke(func(op task.Task) {
		taskApi1 = taskApi.NewApiTask(op)
	}); err != nil {
		panic(err)
	}

	formApi1 := formApi.Form{}
	if err := dig.Invoke(func(op forms.Form) {
		formApi1 = formApi.NewApiForm(op)
	}); err != nil {
		panic(err)
	}

	changesApi1 := changesApi.Changes{}
	if err := dig.Invoke(func(op changes.Changes) {
		changesApi1 = changesApi.NewApiChanges(op)
	}); err != nil {
		panic(err)
	}

	router.POST("/staff/add", staffApi1.Add)

	router.POST("/task/addTask", taskApi1.AddTask)
	router.POST("/task/getTasks", taskApi1.GetTaskById)

	router.POST("/changes/get", changesApi1.GetChanges)

	router.POST("/task/updateLeadTime", changesApi1.UpdateTaskLeadTime)
	router.POST("/task/AddTaskForStaff", changesApi1.AddTaskForStaff)

	router.POST("/task/UpdateTaskStatusByStaff", changesApi1.UpdateTaskStatus)

	router.POST("/task/AddTaskWithAutomaticStaffSelection", changesApi1.AddTaskWithAutomaticStaffSelection)

	router.POST("/task/UpdateAwaitingTaskToActive", changesApi1.UpdateAwaitingTaskToActive)

	router.POST("/form/InsertAnswers", formApi1.InsertAnswers)

	return router
}
