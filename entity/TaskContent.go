package entity

type TaskContent struct {
	//Id int
	Text    string
	Title   string
	Address string
	TaskId  int       `json:",omitempty"`
	Comment []Comment `json:",omitempty"`
}
