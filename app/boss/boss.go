package boss

import (
	"github.com/elizavetamikhailova/TasksProject/dao"
	"github.com/elizavetamikhailova/TasksProject/dao/gorm/model"
)

type Boss struct {
	bossDAO dao.Boss
}

func NewAppBoss(bossDAO dao.Boss) Boss {
	return Boss{
		bossDAO: bossDAO,
	}
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
	BossId  int    `valid:"required"`
	Pass    string `valid:"required"`
	OldPass string `valid:"required"`
}

type ArgChangeLogin struct {
	BossId int    `valid:"required"`
	Login  string `valid:"required"`
}

func (b *Boss) Auth(arg ArgAuth) (string, error) {
	return b.bossDAO.GetAuth(arg.Login, arg.PassMd5, arg.DeviceId, arg.PushToken)
}

func (b *Boss) CheckToken(token string) error {
	return b.bossDAO.CheckToken(token)
}

func (b *Boss) GetUserInfo(arg ArgGetUserInfo) (*model.Boss, error) {
	return b.bossDAO.GetBossInfo(arg.Login)
}

func (b *Boss) UpdatePushToken(arg ArgUpdatePushToken) error {
	return b.bossDAO.UpdatePushToken(arg.DeviceId, arg.PushToken)
}

func (b *Boss) ChangePassword(arg ArgChangePassword) error {
	return b.bossDAO.ChangePassword(arg.BossId, arg.Pass, arg.OldPass)
}

func (b *Boss) ChangeLogin(arg ArgChangeLogin) error {
	return b.bossDAO.ChangeLogin(arg.BossId, arg.Login)
}
