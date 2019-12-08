package model

import "awesomeProject1/entity"

type Staff struct {
	entity.Staff
}

func (Staff) TableName() string {
	return "tasks.staff"
}

