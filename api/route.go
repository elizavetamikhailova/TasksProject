package api

import (
	staffApi "awesomeProject1/api/staff"
	taskApi "awesomeProject1/api/task"
	"awesomeProject1/app/staff"
	"awesomeProject1/app/task"
	"github.com/julienschmidt/httprouter"
	"go.uber.org/dig"
)

type Router struct {
}

func (r *Router) Get(dig *dig.Container) *httprouter.Router {
	router := httprouter.New()

	staffApi1 := staffApi.Staff{}
	if err := dig.Invoke(func(op staff.Staff){
		staffApi1 = staffApi.NewApiStaff(op)
	}); err != nil{
		panic(err)
	}

	taskApi1 := taskApi.Task{}
	if err := dig.Invoke(func(op task.Task) {
		taskApi1 = taskApi.NewApiTask(op)
	}); err != nil {
		panic(err)
	}

	router.POST("/staff/add", staffApi1.Add)
	router.POST("/task/add", taskApi1.AddTask)


	return router
}

//func  Get(w http.ResponseWriter, r *http.Request, ps httprouter.Params) {
//
//	jData, err := json.Marshal("{hello : it works!}")
//	if err != nil {
//		return
//	}
//	w.Write(jData)
//}