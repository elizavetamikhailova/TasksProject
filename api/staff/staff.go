package staff

import "awesomeProject1/app/staff"

type Staff struct {
	op staff.Staff
}

func NewApiStaff(op staff.Staff) Staff{
	return Staff{op: op}
}
