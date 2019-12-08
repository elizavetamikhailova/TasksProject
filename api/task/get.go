package task

import (
	"encoding/json"
	"github.com/asaskevich/govalidator"
	"github.com/elizavetamikhailova/TasksProject/api/errorcode"
	"github.com/elizavetamikhailova/TasksProject/app/task"
	"github.com/julienschmidt/httprouter"
	"io"
	"io/ioutil"
	"net/http"
)

func ValidationGetTaskById(bodyIN io.ReadCloser) (task.ArgGet, error) {
	post := task.ArgGet{}
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

func (t *Task) GetTaskById(w http.ResponseWriter, r *http.Request, ps httprouter.Params) {
	post, err := ValidationGetTaskById(r.Body)
	if err != nil {
		errorcode.WriteError(errorcode.CodeDataInvalid, err.Error(), w)
		return
	}

	task1, err := t.op.GetTask(post)
	if err != nil {
		errorcode.WriteError(errorcode.CodeUnexpected, err.Error(), w)
		return
	}
	jData, err := json.Marshal(task1)
	if err != nil {
		errorcode.WriteError(errorcode.CodeUnexpected, err.Error(), w)
		return
	}
	w.Write(jData)
}
