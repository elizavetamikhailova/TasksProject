package model

type Boss struct {
	Id    int
	Login string
	Pass  string
}

func (Boss) TableName() string {
	return "tasks.boss"
}
