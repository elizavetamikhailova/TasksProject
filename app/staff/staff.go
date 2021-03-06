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
	BossId  int    `valid:"required"`
	Login   string `valid:"required"`
	Phone   string `valid:"required"`
	PassMd5 string `valid:"required"`
}

type ArgAuth struct {
	Login     string `valid:"required"`
	PassMd5   string `valid:"required"`
	DeviceId  string `valid:"required"`
	PushToken string `valid:"required"`
}

type ArgUpdatePushToken struct {
	DeviceId  string `valid:"required"`
	PushToken string `valid:"required"`
}

type ArgGetUserInfo struct {
	Login string `valid:"required"`
}

type ArgChangePassword struct {
	StaffId int    `valid:"required"`
	Pass    string `valid:"required"`
	OldPass string `valid:"required"`
}

type ArgChangeLogin struct {
	StaffId int    `valid:"required"`
	Login   string `valid:"required"`
}

type ArgChangePhone struct {
	StaffId int    `valid:"required"`
	Phone   string `valid:"required"`
}

func (s *Staff) Add(arg ArgAdd) error {
	return s.staffDAO.Add(arg.BossId, arg.Login, arg.Phone, arg.PassMd5)
}

func (s *Staff) Auth(arg ArgAuth) (string, error) {
	return s.staffDAO.GetAuth(arg.Login, arg.PassMd5, arg.DeviceId, arg.PushToken)
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

func (s *Staff) ChangePassword(arg ArgChangePassword) error {
	return s.staffDAO.ChangePassword(arg.StaffId, arg.Pass, arg.OldPass)
}

func (s *Staff) ChangeLogin(arg ArgChangeLogin) error {
	return s.staffDAO.ChangeLogin(arg.StaffId, arg.Login)
}

func (s *Staff) ChangePhone(arg ArgChangePhone) error {
	return s.staffDAO.ChangePhone(arg.StaffId, arg.Phone)
}
