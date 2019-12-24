package entity

type Flag struct {
	Id     int `gorm:"column:id"`
	TaskId int `gorm:"column:task_id"`
	FlagId int `gorm:"column:flag_id"`
}
