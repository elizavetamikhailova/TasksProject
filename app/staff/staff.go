package staff

import (
	"github.com/elizavetamikhailova/TasksProject/dao"
)

type Staff struct {
	staffDAO dao.Staff
}

func NewAppStaff(staffDAO dao.Staff) Staff {
	return Staff{
		staffDAO: staffDAO,
	}
}

type ArgAdd struct {
	Login   string `valid:"required"`
	Phone   string `valid:"required"`
	PassMd5 string `valid:"required"`
}

func (s *Staff) Add(arg ArgAdd) error {
	return s.staffDAO.Add(arg.Login, arg.Phone, arg.PassMd5)
}
