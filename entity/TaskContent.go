package entity

type TaskContent struct {
	//Id int
	Text    string
	Title   string
	Address string
	TaskId  int `json:",omitempty"`
}

func (TaskContent) TableName() string {
	return "tasks.task_content"
}
