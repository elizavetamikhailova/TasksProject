package staff

import "github.com/elizavetamikhailova/TasksProject/app/staff"

type Staff struct {
	op staff.Staff
}

func NewApiStaff(op staff.Staff) Staff {
	return Staff{op: op}
}
