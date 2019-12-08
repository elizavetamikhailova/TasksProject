package entity

type Changes struct {
	Staff *Staff             `gorm:"column:staff"`
	Tasks []GetTasksResponse `gorm:"column:tasks"`
}
