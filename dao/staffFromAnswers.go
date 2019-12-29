package dao

type StaffAnswers interface {
	InsertStaffAnswers(formId int, questionCode []string) error
}
