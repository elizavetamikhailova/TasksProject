package changes

import (
	"encoding/json"
	"github.com/asaskevich/govalidator"
	"github.com/elizavetamikhailova/TasksProject/api/errorcode"
	"github.com/elizavetamikhailova/TasksProject/app/changes"
	"github.com/julienschmidt/httprouter"
	"io"
	"io/ioutil"
	"net/http"
)

func validationAddTask(bodyIN io.ReadCloser) (changes.ArgAddTaskForStaff, error) {
	post := changes.ArgAddTaskForStaff{}
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

func validationAddTaskWithAutomaticStaffSelection(bodyIN io.ReadCloser) (changes.ArgAddTaskWithAutomaticStaffSelection, error) {
	post := changes.ArgAddTaskWithAutomaticStaffSelection{}
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

func validationAddTaskWithContent(bodyIN io.ReadCloser) (changes.ArgAddTaskWithContent, error) {
	post := changes.ArgAddTaskWithContent{}
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

func (c *Changes) AddTaskForStaff(w http.ResponseWriter, r *http.Request, ps httprouter.Params) {
	post, err := validationAddTask(r.Body)
	if err != nil {
		errorcode.WriteError(errorcode.CodeDataInvalid, err.Error(), w)
		return
	}

	if err = c.op.AddTaskForStaff(post); err != nil {
		errorcode.WriteError(errorcode.CodeUnexpected, err.Error(), w)
		return
	}

	changes1, err := c.op.GetChanges(changes.ArgGetChanges{
		StaffId:    post.StaffId,
		UpdateTime: post.UpdateTime,
	})

	jData, err := json.Marshal(changes1)
	if err != nil {
		errorcode.WriteError(errorcode.CodeUnexpected, err.Error(), w)
		return
	}
	w.Write(jData)
}

func (c *Changes) AddTaskWithAutomaticStaffSelection(w http.ResponseWriter, r *http.Request, ps httprouter.Params) {
	post, err := validationAddTaskWithAutomaticStaffSelection(r.Body)
	if err != nil {
		errorcode.WriteError(errorcode.CodeDataInvalid, err.Error(), w)
		return
	}

	if err = c.op.AddTaskWithAutomaticStaffSelection(post); err != nil {
		errorcode.WriteError(errorcode.CodeUnexpected, err.Error(), w)
		return
	}

	changes1, err := c.op.GetChangesForBoss(changes.ArgGetChangesForBoss{
		UpdateTime: post.UpdateTime,
	})

	jData, err := json.Marshal(changes1)
	if err != nil {
		errorcode.WriteError(errorcode.CodeUnexpected, err.Error(), w)
		return
	}
	w.Write(jData)
}

func (c *Changes) AddTaskWithContent(w http.ResponseWriter, r *http.Request, ps httprouter.Params) {
	post, err := validationAddTaskWithContent(r.Body)
	if err != nil {
		errorcode.WriteError(errorcode.CodeDataInvalid, err.Error(), w)
		return
	}

	if err = c.op.AddTaskWithContent(post); err != nil {
		errorcode.WriteError(errorcode.CodeUnexpected, err.Error(), w)
		return
	}

	changes1, err := c.op.GetChangesForBoss(changes.ArgGetChangesForBoss{
		UpdateTime: post.UpdateTime,
	})

	jData, err := json.Marshal(changes1)
	if err != nil {
		errorcode.WriteError(errorcode.CodeUnexpected, err.Error(), w)
		return
	}
	w.Write(jData)
}
