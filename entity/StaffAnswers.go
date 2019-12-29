package entity

import "time"

type StaffAnswers struct {
	Id           int
	FormId       int
	QuestionCode string
	CreatedAt    time.Time `gorm:"column:created_at"`
	UpdatedAt    time.Time `gorm:"column:updated_at"`
}
