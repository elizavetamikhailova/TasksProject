package forms

import (
	"encoding/json"
	"github.com/asaskevich/govalidator"
	"github.com/elizavetamikhailova/TasksProject/api/errorcode"
	"github.com/elizavetamikhailova/TasksProject/app/forms"
	"github.com/julienschmidt/httprouter"
	"io"
	"io/ioutil"
	"net/http"
)

func validationInsertAnswers(bodyIN io.ReadCloser) (forms.ArgInsertAnswers, error) {
	post := forms.ArgInsertAnswers{}
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

func (f *Form) InsertAnswers(w http.ResponseWriter, r *http.Request, ps httprouter.Params) {
	post, err := validationInsertAnswers(r.Body)
	if err != nil {
		errorcode.WriteError(errorcode.CodeDataInvalid, err.Error(), w)
		return
	}

	if err = f.op.Insert(post); err != nil {
		errorcode.WriteError(errorcode.CodeUnexpected, err.Error(), w)
		return
	}

}
