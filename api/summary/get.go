package summary

import (
	"encoding/json"
	"github.com/elizavetamikhailova/TasksProject/api/errorcode"
	"github.com/julienschmidt/httprouter"
	"net/http"
)

func (s *Summary) GetMostProductiveStaff(w http.ResponseWriter, r *http.Request, ps httprouter.Params) {
	task1, err := s.op.MostProductiveStaff()
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
