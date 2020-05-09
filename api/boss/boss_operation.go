package boss

import (
	"encoding/json"
	"github.com/asaskevich/govalidator"
	"github.com/elizavetamikhailova/TasksProject/api/errorcode"
	error2 "github.com/elizavetamikhailova/TasksProject/api/errorcode"
	"github.com/elizavetamikhailova/TasksProject/app/boss"
	"github.com/julienschmidt/httprouter"
	"io"
	"io/ioutil"
	"net/http"
)

type Boss struct {
	op boss.Boss
}

func NewApiBoss(op boss.Boss) Boss {
	return Boss{op: op}
}

func validationAuth(bodyIN io.ReadCloser) (boss.ArgAuth, error) {
	post := boss.ArgAuth{}
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

func (b *Boss) Auth(w http.ResponseWriter, r *http.Request, ps httprouter.Params) {
	post, err := validationAuth(r.Body)
	if err != nil {
		errorcode.WriteError(errorcode.CodeDataInvalid, err.Error(), w)
		return
	}

	token, err := b.op.Auth(post)
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

func (b *Boss) CheckToken(next httprouter.Handle) httprouter.Handle {
	return func(w http.ResponseWriter, r *http.Request, p httprouter.Params) {
		authorizationHeader := r.Header.Get("authorization")
		if authorizationHeader == "" {
			error2.WriteError(error2.CodeUnauthorized, error2.MessageUnauthorized, w)
			return
		} else {
			n := len(bearerPrefix)
			err := b.op.CheckToken(authorizationHeader[n:])
			if err != nil {
				error2.WriteError(error2.CodeUnauthorized, err.Error(), w)
				return
			}
		}
		w.Header().Set("Content-Type", "application/json")
		next(w, r, p)
	}
}

func validationGetUserInfo(bodyIN io.ReadCloser) (boss.ArgGetUserInfo, error) {
	post := boss.ArgGetUserInfo{}
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

func (b *Boss) GetUserInfo(w http.ResponseWriter, r *http.Request, ps httprouter.Params) {
	post, err := validationGetUserInfo(r.Body)
	if err != nil {
		errorcode.WriteError(errorcode.CodeDataInvalid, err.Error(), w)
		return
	}

	boss, err := b.op.GetUserInfo(post)

	if err != nil {
		errorcode.WriteError(errorcode.CodeUnexpected, err.Error(), w)
		return
	}
	jData, err := json.Marshal(boss)
	if err != nil {
		errorcode.WriteError(errorcode.CodeUnexpected, err.Error(), w)
		return
	}
	w.Write(jData)
}

func validationUpdatePushToken(bodyIN io.ReadCloser) (boss.ArgUpdatePushToken, error) {
	post := boss.ArgUpdatePushToken{}
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

func (b *Boss) UpdatePushToken(w http.ResponseWriter, r *http.Request, ps httprouter.Params) {
	post, err := validationUpdatePushToken(r.Body)
	if err != nil {
		errorcode.WriteError(errorcode.CodeDataInvalid, err.Error(), w)
		return
	}
	err = b.op.UpdatePushToken(post)

	if err != nil {
		errorcode.WriteError(errorcode.CodeUnexpected, err.Error(), w)
		return
	}
}

func validationChangePassword(bodyIN io.ReadCloser) (boss.ArgChangePassword, error) {
	post := boss.ArgChangePassword{}
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

func validationChangeLogin(bodyIN io.ReadCloser) (boss.ArgChangeLogin, error) {
	post := boss.ArgChangeLogin{}
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

func (b *Boss) ChangePassword(w http.ResponseWriter, r *http.Request, ps httprouter.Params) {
	post, err := validationChangePassword(r.Body)
	if err != nil {
		errorcode.WriteError(errorcode.CodeDataInvalid, err.Error(), w)
		return
	}
	err = b.op.ChangePassword(post)

	if err != nil {
		errorcode.WriteError(errorcode.CodeUnexpected, err.Error(), w)
		return
	}
}

func (b *Boss) ChangeLogin(w http.ResponseWriter, r *http.Request, ps httprouter.Params) {
	post, err := validationChangeLogin(r.Body)
	if err != nil {
		errorcode.WriteError(errorcode.CodeDataInvalid, err.Error(), w)
		return
	}
	err = b.op.ChangeLogin(post)

	if err != nil {
		errorcode.WriteError(errorcode.CodeUnexpected, err.Error(), w)
		return
	}
}
