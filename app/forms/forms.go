package forms

import "github.com/elizavetamikhailova/TasksProject/dao"

type Form struct {
	AnswersDAO dao.StaffAnswers
}

func NewAppStaffAnswers(answersDao dao.StaffAnswers) Form {
	return Form{
		AnswersDAO: answersDao,
	}
}

type ArgInsertAnswers struct {
	FormId       int      `valid:"required"`
	QuestionCode []string `valid:"required"`
}

func (f *Form) Insert(arg ArgInsertAnswers) error {
	return f.AnswersDAO.InsertStaffAnswers(arg.FormId, arg.QuestionCode)
}
