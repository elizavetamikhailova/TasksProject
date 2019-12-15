package entity

import "time"

type Staff struct {
	Id        int       `gorm:"column:id"`
	Login     string    `gorm:"column:login"`
	Phone     string    `gorm:"column:phone"`
	PassMd5   string    `gorm:"column:pass_md5"`
	CreatedAt time.Time `gorm:"column:created_at"`
	UpdatedAt time.Time `gorm:"column:updated_at"`
	DeletedAt time.Time `gorm:"column:deleted_at"`
	Practice  *int      `json:",omitempty"`
}
