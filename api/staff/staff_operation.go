package staff

import (
	"encoding/json"
	"github.com/asaskevich/govalidator"
	"github.com/elizavetamikhailova/TasksProject/api/errorcode"
	error2 "github.com/elizavetamikhailova/TasksProject/api/errorcode"
	"github.com/elizavetamikhailova/TasksProject/app/staff"
	"github.com/julienschmidt/httprouter"
	"io"
	"io/ioutil"
	"net/http"
)

func validationAdd(bodyIN io.ReadCloser) (staff.ArgAdd, error) {
	post := staff.ArgAdd{}
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

func (s *Staff) Add(w http.ResponseWriter, r *http.Request, ps httprouter.Params) {
	post, err := validationAdd(r.Body)
	if err != nil {
		errorcode.WriteError(errorcode.CodeDataInvalid, err.Error(), w)
		return
	}

	if err = s.op.Add(post); err != nil {
		errorcode.WriteError(errorcode.CodeUnexpected, err.Error(), w)
		return
	}
}

func validationAuth(bodyIN io.ReadCloser) (staff.ArgAuth, error) {
	post := staff.ArgAuth{}
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

type Token struct {
	Token string
}

func (s *Staff) Auth(w http.ResponseWriter, r *http.Request, ps httprouter.Params) {
	post, err := validationAuth(r.Body)
	if err != nil {
		errorcode.WriteError(errorcode.CodeDataInvalid, err.Error(), w)
		return
	}

	token, err := s.op.Auth(post)
	tokenStruct := Token{Token: token}

	if err != nil {
		errorcode.WriteError(errorcode.CodeUnexpected, err.Error(), w)
		return
	}
	jData, err := json.Marshal(tokenStruct)
	if err != nil {
		errorcode.WriteError(errorcode.CodeUnexpected, err.Error(), w)
		return
	}
	w.Write(jData)
}

var bearerPrefix = "Bearer "

func (s *Staff) CheckToken(next httprouter.Handle) httprouter.Handle {
	return func(w http.ResponseWriter, r *http.Request, p httprouter.Params) {
		authorizationHeader := r.Header.Get("authorization")
		if authorizationHeader == "" {
			error2.WriteError(error2.CodeUnauthorized, error2.MessageUnauthorized, w)
			return
		} else {
			n := len(bearerPrefix)
			err := s.op.CheckToken(authorizationHeader[n:])
			if err != nil {
				error2.WriteError(error2.CodeUnauthorized, err.Error(), w)
				return
			}
		}
		w.Header().Set("Content-Type", "application/json")
		next(w, r, p)
	}
}

func validationGetUserInfo(bodyIN io.ReadCloser) (staff.ArgGetUserInfo, error) {
	post := staff.ArgGetUserInfo{}
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

func (s *Staff) GetUserInfo(w http.ResponseWriter, r *http.Request, ps httprouter.Params) {
	post, err := validationGetUserInfo(r.Body)
	if err != nil {
		errorcode.WriteError(errorcode.CodeDataInvalid, err.Error(), w)
		return
	}

	staff, err := s.op.GetUserInfo(post)

	if err != nil {
		errorcode.WriteError(errorcode.CodeUnexpected, err.Error(), w)
		return
	}
	jData, err := json.Marshal(staff)
	if err != nil {
		errorcode.WriteError(errorcode.CodeUnexpected, err.Error(), w)
		return
	}
	w.Write(jData)
}
