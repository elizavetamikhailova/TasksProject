package model

type ConfirmLeadTime struct {
	Creater string
}

func (ConfirmLeadTime) TableName() string {
	return "tasks.who_create_confirm_lead_time"
}
