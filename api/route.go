package api

import (
	changesApi "github.com/elizavetamikhailova/TasksProject/api/changes"
	staffApi "github.com/elizavetamikhailova/TasksProject/api/staff"
	summaryApi "github.com/elizavetamikhailova/TasksProject/api/summary"
	taskApi "github.com/elizavetamikhailova/TasksProject/api/task"
	"github.com/elizavetamikhailova/TasksProject/app/changes"
	"github.com/elizavetamikhailova/TasksProject/app/staff"
	"github.com/elizavetamikhailova/TasksProject/app/summary"
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

	changesApi1 := changesApi.Changes{}
	if err := dig.Invoke(func(op changes.Changes) {
		changesApi1 = changesApi.NewApiChanges(op)
	}); err != nil {
		panic(err)
	}

	summaryApi1 := summaryApi.Summary{}
	if err := dig.Invoke(func(op summary.Summary) {
		summaryApi1 = summaryApi.NewApiSummary(op)
	}); err != nil {
		panic(err)
	}

	router.POST("/staff/add", changesApi1.AddStaff)

	router.POST("/task/addTask", taskApi1.AddTask)
	router.POST("/task/getTasks", taskApi1.GetTaskById)

	router.POST("/changes/get", changesApi1.GetChanges)

	router.POST("/changes/boss/get", changesApi1.GetChangesForBoss)

	router.POST("/task/updateLeadTime", changesApi1.UpdateTaskLeadTime)

	router.POST("/task/boss/updateLeadTime", changesApi1.UpdateTaskLeadTimeForBoss)

	router.POST("/task/AddTaskForStaff", changesApi1.AddTaskForStaff)

	router.POST("/task/AddTaskWithContent", changesApi1.AddTaskWithContent)

	router.POST("/task/UpdateTaskStatusByStaff", changesApi1.UpdateTaskStatus)

	router.POST("/task/UpdateTaskStatusByBoss", changesApi1.UpdateTaskStatusByBoss)

	router.POST("/task/AddTaskWithAutomaticStaffSelection", changesApi1.AddTaskWithAutomaticStaffSelection)

	router.POST("/task/UpdateAwaitingTaskToActive", changesApi1.UpdateAwaitingTaskToActive)

	router.POST("/form/InsertAnswers", changesApi1.InsertAnswers)

	router.POST("/task/AddCommentForBoss", changesApi1.AddCommentForBoss)

	router.POST("/task/AddCommentForStaff", changesApi1.AddCommentForStaff)

	router.GET("/summary/GetMostProductiveStaff", summaryApi1.GetMostProductiveStaff)

	return router
}
