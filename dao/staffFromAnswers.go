package dao

type StaffAnswers interface {
	InsertStaffAnswers(formId int, questionCode []string, taskId int) error
}
