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

func validationAddComment(bodyIN io.ReadCloser) (changes.ArgAddComment, error) {
	post := changes.ArgAddComment{}
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

func (c *Changes) AddCommentForBoss(w http.ResponseWriter, r *http.Request, ps httprouter.Params) {
	post, err := validationAddComment(r.Body)
	if err != nil {
		errorcode.WriteError(errorcode.CodeDataInvalid, err.Error(), w)
		return
	}

	if err = c.op.AddComment(post); err != nil {
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

func (c *Changes) AddCommentForStaff(w http.ResponseWriter, r *http.Request, ps httprouter.Params) {
	post, err := validationAddComment(r.Body)
	if err != nil {
		errorcode.WriteError(errorcode.CodeDataInvalid, err.Error(), w)
		return
	}

	if err = c.op.AddComment(post); err != nil {
		errorcode.WriteError(errorcode.CodeUnexpected, err.Error(), w)
		return
	}

	changes1, err := c.op.GetChanges(changes.ArgGetChanges{
		UpdateTime: post.UpdateTime,
	})

	jData, err := json.Marshal(changes1)
	if err != nil {
		errorcode.WriteError(errorcode.CodeUnexpected, err.Error(), w)
		return
	}
	w.Write(jData)
}
