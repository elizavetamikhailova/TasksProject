package entity

type Changes struct {
	Staff *Staff             `json:",omitempty"`
	Tasks []GetTasksResponse `json:",omitempty"`
}
