package model

type TaskContent struct {
	Text     string
	Title    string
	Address  string
	TaskId   int       `json:",omitempty"`
	Comments []Comment `json:",omitempty"`
}

func (TaskContent) TableName() string {
	return "tasks.task_content"
}
