package entity

type Workload struct {
	StaffId int     `gorm:"column:id"`
	Aggr    float64 `gorm:"column:aggr"`
}
