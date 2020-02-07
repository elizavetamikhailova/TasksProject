package changes

import (
	"database/sql"
	"encoding/json"
	"github.com/asaskevich/govalidator"
	"github.com/elizavetamikhailova/TasksProject/api/errorcode"
	"github.com/elizavetamikhailova/TasksProject/app/changes"
	"github.com/julienschmidt/httprouter"
	"io"
	"io/ioutil"
	"net/http"
)

func ValidationUpdateLeadTime(bodyIN io.ReadCloser) (changes.ArgUpdateTaskLeadTime, error) {
	post := changes.ArgUpdateTaskLeadTime{}
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

func ValidationUpdateTaskStatus(bodyIN io.ReadCloser) (changes.ArgUpdateTaskStatus, error) {
	post := changes.ArgUpdateTaskStatus{}
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

func ValidationUpdateAwaitingTaskToActive(bodyIN io.ReadCloser) (changes.ArgUpdateAwaitingTaskToActive, error) {
	post := changes.ArgUpdateAwaitingTaskToActive{}
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

func (c *Changes) UpdateTaskLeadTime(w http.ResponseWriter, r *http.Request, ps httprouter.Params) {
	post, err := ValidationUpdateLeadTime(r.Body)
	if err != nil {
		errorcode.WriteError(errorcode.CodeDataInvalid, err.Error(), w)
		return
	}

	if err = c.op.UpdateTaskExpectedLeadTime(post); err != nil {
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

func (c *Changes) UpdateTaskLeadTimeForBoss(w http.ResponseWriter, r *http.Request, ps httprouter.Params) {
	post, err := ValidationUpdateLeadTime(r.Body)
	if err != nil {
		errorcode.WriteError(errorcode.CodeDataInvalid, err.Error(), w)
		return
	}

	if err = c.op.UpdateTaskExpectedLeadTime(post); err != nil {
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

func (c *Changes) UpdateTaskStatus(w http.ResponseWriter, r *http.Request, ps httprouter.Params) {
	post, err := ValidationUpdateTaskStatus(r.Body)
	if err != nil {
		errorcode.WriteError(errorcode.CodeDataInvalid, err.Error(), w)
		return
	}

	if err = c.op.UpdateTaskStatusByStaff(post); err != nil {
		if err == sql.ErrNoRows {
			errorcode.WriteError(errorcode.CodeTaskDoesNotExist, err.Error(), w)
		} else {
			errorcode.WriteError(errorcode.CodeUnableToChangeTaskStatus, err.Error(), w)
		}
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

func (c *Changes) UpdateTaskStatusByBoss(w http.ResponseWriter, r *http.Request, ps httprouter.Params) {
	post, err := ValidationUpdateTaskStatus(r.Body)
	if err != nil {
		errorcode.WriteError(errorcode.CodeDataInvalid, err.Error(), w)
		return
	}

	if err = c.op.UpdateTaskStatusByBoss(post); err != nil {
		if err == sql.ErrNoRows {
			errorcode.WriteError(errorcode.CodeTaskDoesNotExist, err.Error(), w)
		} else {
			errorcode.WriteError(errorcode.CodeUnableToChangeTaskStatus, err.Error(), w)
		}
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

func (c *Changes) UpdateAwaitingTaskToActive(w http.ResponseWriter, r *http.Request, ps httprouter.Params) {
	post, err := ValidationUpdateAwaitingTaskToActive(r.Body)
	if err != nil {
		errorcode.WriteError(errorcode.CodeDataInvalid, err.Error(), w)
		return
	}

	if err = c.op.UpdateAwaitingTaskToActive(post); err != nil {
		if err == sql.ErrNoRows {
			errorcode.WriteError(errorcode.CodeTaskDoesNotExist, err.Error(), w)
		} else {
			errorcode.WriteError(errorcode.CodeUnableToChangeTaskStatus, err.Error(), w)
		}
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
