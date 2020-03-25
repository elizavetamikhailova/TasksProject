package staff

import (
	"github.com/elizavetamikhailova/TasksProject/dao"
	"github.com/elizavetamikhailova/TasksProject/entity"
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

type ArgAuth struct {
	Login      string `valid:"required"`
	PassMd5    string `valid:"required"`
	DeviceCode string `valid:"required"`
	PushToken  string `valid:"required"`
}

type ArgUpdatePushToken struct {
	DeviceId  string `valid:"required"`
	PushToken string `valid:"required"`
}

type ArgGetUserInfo struct {
	Login string `valid:"required"`
}

func (s *Staff) Add(arg ArgAdd) error {
	return s.staffDAO.Add(arg.Login, arg.Phone, arg.PassMd5)
}

func (s *Staff) Auth(arg ArgAuth) (string, error) {
	return s.staffDAO.GetAuth(arg.Login, arg.PassMd5, arg.DeviceCode, arg.PushToken)
}

func (s *Staff) CheckToken(token string) error {
	return s.staffDAO.CheckToken(token)
}

func (s *Staff) GetUserInfo(arg ArgGetUserInfo) (*entity.Staff, error) {
	return s.staffDAO.GetUserInfo(arg.Login)
}

func (s *Staff) UpdatePushToken(arg ArgUpdatePushToken) error {
	return s.staffDAO.UpdatePushToken(arg.DeviceId, arg.PushToken)
}
