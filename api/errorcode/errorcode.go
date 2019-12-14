package errorcode

import (
	"encoding/json"
	"net/http"
)

const (
	CodeUnauthorized             = "unauthorized"
	CodeDataInvalid              = "data_invalid"
	CodeUnexpected               = "unexpected_error"
	CodeUnableToChangeTaskStatus = "unable_to_change_task_status"
	CodeTaskDoesNotExist         = "task_does_not_exist"

	MessageUnauthorized = "authorization required "
)

type CommonError struct {
	Message, Code string
}

func WriteError(code, message string, w http.ResponseWriter) {
	errJSON := CommonError{
		Message: message,
		Code:    code,
	}
	jData, err := json.Marshal(errJSON)
	if err != nil {
		return
	}
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusUnauthorized)
	w.Write(jData)
}
