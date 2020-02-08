package entity

type TaskForm struct {
	Id            int
	TaskId        int
	GroupId       int
	GroupCode     string
	GroupTitle    string
	FormQuestions []FormQuestions
	FormAnswer    FormAnswer `json:",omitempty"`
}
