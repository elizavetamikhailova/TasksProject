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

func ValidationGetChanges(bodyIN io.ReadCloser) (changes.ArgGetChanges, error) {
	post := changes.ArgGetChanges{}
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

func ValidationGetChangesForBoss(bodyIN io.ReadCloser) (changes.ArgGetChangesForBoss, error) {
	post := changes.ArgGetChangesForBoss{}
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

func (c *Changes) GetChanges(w http.ResponseWriter, r *http.Request, ps httprouter.Params) {
	post, err := ValidationGetChanges(r.Body)
	if err != nil {
		errorcode.WriteError(errorcode.CodeDataInvalid, err.Error(), w)
		return
	}

	changes1, err := c.op.GetChanges(post)
	if err != nil {
		errorcode.WriteError(errorcode.CodeUnexpected, err.Error(), w)
		return
	}
	jData, err := json.Marshal(changes1)
	if err != nil {
		errorcode.WriteError(errorcode.CodeUnexpected, err.Error(), w)
		return
	}
	w.Write(jData)
}

func (c *Changes) GetChangesForBoss(w http.ResponseWriter, r *http.Request, ps httprouter.Params) {
	post, err := ValidationGetChangesForBoss(r.Body)
	if err != nil {
		errorcode.WriteError(errorcode.CodeDataInvalid, err.Error(), w)
		return
	}

	changes1, err := c.op.GetChangesForBoss(post)
	if err != nil {
		errorcode.WriteError(errorcode.CodeUnexpected, err.Error(), w)
		return
	}
	jData, err := json.Marshal(changes1)
	if err != nil {
		errorcode.WriteError(errorcode.CodeUnexpected, err.Error(), w)
		return
	}
	w.Write(jData)
}
