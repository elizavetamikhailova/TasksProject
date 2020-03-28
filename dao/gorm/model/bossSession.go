package model

type BossSession struct {
	Id           int
	DeviceCode   string
	AuthToken    string
	OriginalPass string
	ExpiresAt    string
	PushToken    string
	BossId       int
}

func (BossSession) TableName() string {
	return "tasks.boss_session"
}
