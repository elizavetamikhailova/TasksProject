package model

type StaffToBoss struct {
	Id      int
	StaffId int
	BossId  int
}

func (StaffToBoss) TableName() string {
	return "tasks.staff_to_boss"
}
