package model

type StaffSession struct {
	Id           int
	DeviceCode   string
	AuthToken    string
	OriginalPass string
	ExpiresAt    string
	PushToken    string
	StaffId      int
}

func (StaffSession) TableName() string {
	return "tasks.staff_session"
}
