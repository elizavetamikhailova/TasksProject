package api

import (
	bossApi "github.com/elizavetamikhailova/TasksProject/api/boss"
	changesApi "github.com/elizavetamikhailova/TasksProject/api/changes"
	staffApi "github.com/elizavetamikhailova/TasksProject/api/staff"
	summaryApi "github.com/elizavetamikhailova/TasksProject/api/summary"
	taskApi "github.com/elizavetamikhailova/TasksProject/api/task"
	"github.com/elizavetamikhailova/TasksProject/app/boss"
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

	bossApi1 := bossApi.Boss{}
	if err := dig.Invoke(func(op boss.Boss) {
		bossApi1 = bossApi.NewApiBoss(op)
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

	router.POST("/staff/auth", staffApi1.Auth)

	router.POST("/boss/auth", bossApi1.Auth)

	router.POST("/staff/add", bossApi1.CheckToken(changesApi1.AddStaff))

	router.POST("/staff/getUserInfo", staffApi1.CheckToken(staffApi1.GetUserInfo))

	router.POST("/boss/getUserInfo", bossApi1.CheckToken(bossApi1.GetUserInfo))

	router.POST("/task/addTask", staffApi1.CheckToken(taskApi1.AddTask))

	router.POST("/task/boss/addTask", bossApi1.CheckToken(taskApi1.AddTask))

	router.POST("/task/getTasks", staffApi1.CheckToken(taskApi1.GetTaskById))

	router.POST("/changes/get", staffApi1.CheckToken(changesApi1.GetChanges))

	router.POST("/changes/boss/get", bossApi1.CheckToken(changesApi1.GetChangesForBoss))

	router.POST("/task/updateLeadTime", staffApi1.CheckToken(changesApi1.UpdateTaskLeadTime))

	router.POST("/task/boss/updateLeadTime", bossApi1.CheckToken(changesApi1.UpdateTaskLeadTimeForBoss))

	router.POST("/task/AddTaskForStaff", staffApi1.CheckToken(changesApi1.AddTaskForStaff))

	router.POST("/task/AddTaskWithContent", staffApi1.CheckToken(changesApi1.AddTaskWithContent))

	router.POST("/task/boss/AddTaskWithContent", bossApi1.CheckToken(changesApi1.AddTaskWithContent))

	router.POST("/task/UpdateTaskStatusByStaff", staffApi1.CheckToken(changesApi1.UpdateTaskStatus))

	router.POST("/task/UpdateTaskStatusByBoss", bossApi1.CheckToken(changesApi1.UpdateTaskStatusByBoss))

	router.POST("/task/AddTaskWithAutomaticStaffSelection", bossApi1.CheckToken(changesApi1.AddTaskWithAutomaticStaffSelection))

	router.POST("/task/UpdateAwaitingTaskToActive", staffApi1.CheckToken(changesApi1.UpdateAwaitingTaskToActive))

	router.POST("/form/InsertAnswers", staffApi1.CheckToken(changesApi1.InsertAnswers))

	router.POST("/task/AddCommentForBoss", bossApi1.CheckToken(changesApi1.AddCommentForBoss))

	router.POST("/task/AddCommentForStaff", staffApi1.CheckToken(changesApi1.AddCommentForStaff))

	router.GET("/summary/GetMostProductiveStaff", bossApi1.CheckToken(summaryApi1.GetMostProductiveStaff))

	router.GET("/summary/GetMostActiveStaff", bossApi1.CheckToken(summaryApi1.GetMostActiveStaff))

	router.GET("/summary/GetMostLatenessStaff", bossApi1.CheckToken(summaryApi1.GetMostLatenessStaff))

	router.GET("/summary/GetMostProcrastinatingStaff", bossApi1.CheckToken(summaryApi1.GetMostProcratinatingStaff))

	router.GET("/summary/GetMostCancelStaff", bossApi1.CheckToken(summaryApi1.GetMostCancelStaff))

	router.POST("/staff/UpdatePushToken", staffApi1.CheckToken(staffApi1.UpdatePushToken))

	router.POST("/boss/UpdatePushToken", bossApi1.CheckToken(bossApi1.UpdatePushToken))

	router.POST("/staff/changePass", staffApi1.CheckToken(staffApi1.ChangePassword))

	router.POST("/staff/changeLogin", staffApi1.CheckToken(staffApi1.ChangeLogin))

	router.POST("/staff/changePhone", staffApi1.CheckToken(staffApi1.ChangePhone))

	router.POST("/boss/changePass", bossApi1.CheckToken(bossApi1.ChangePassword))

	router.POST("/boss/changeLogin", staffApi1.CheckToken(bossApi1.ChangeLogin))

	return router
}
