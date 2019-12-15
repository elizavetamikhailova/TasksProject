package entity

type Workload struct {
	StaffId int `gorm:"column:id"`
	Aggr    int `gorm:"column:aggr"`
}
