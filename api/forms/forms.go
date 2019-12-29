package forms

import "github.com/elizavetamikhailova/TasksProject/app/forms"

type Form struct {
	op forms.Form
}

func NewApiForm(op forms.Form) Form {
	return Form{op: op}
}
