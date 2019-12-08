package task

import (
	"awesomeProject1/api/errorcode"
	"awesomeProject1/app/task"
	"encoding/json"
	"github.com/asaskevich/govalidator"
	"github.com/julienschmidt/httprouter"
	"io"
	"io/ioutil"
	"net/http"
)

func validationAddTask(bodyIN io.ReadCloser) (task.ArgAddTask, error) {
	post := task.ArgAddTask{}
	body, err := ioutil.ReadAll(bodyIN)
	if err != nil {
		return post, err
	}
	if err = json.Unmarshal(body, &post); err != nil {
		return post, err
	}
	if _, err = govalidator.ValidateStruct(post); err != nil {
		return post, err
	}
	return post, nil
}

func (t *Task) AddTask(w http.ResponseWriter, r *http.Request, ps httprouter.Params) {
	post, err := validationAddTask(r.Body)
	if err != nil {
		errorcode.WriteError(errorcode.CodeDataInvalid, err.Error(), w)
		return
	}

	if err = t.op.AddTask(post); err != nil {
		errorcode.WriteError(errorcode.CodeUnexpected, err.Error(), w)
		return
	}
}
