package gorm

import (
	"database/sql"
	"fmt"
	"github.com/dgrijalva/jwt-go"
	"github.com/elizavetamikhailova/TasksProject/dao"
	"github.com/elizavetamikhailova/TasksProject/dao/gorm/model"
	"github.com/jinzhu/gorm"
	"golang.org/x/crypto/bcrypt"
	"os"
)

type Boss struct {
	db *gorm.DB
}

func NewDaoBoss(db *gorm.DB) dao.Boss {
	return &Boss{
		db: db,
	}
}

func (b Boss) GetBossInfo(login string) (*model.Boss, error) {
	var boss model.Boss

	bossFromDb := b.db.
		Table(fmt.Sprintf(`%s b`, new(model.Boss).TableName())).
		Where(`b.login = ?`, login).
		Row()

	err := bossFromDb.Scan(&boss.Id, &boss.Login, &boss.Pass)
	if err != nil {
		//if err == sql.ErrNoRows {
		//	return nil, nil
		//}
		return nil, err
	}

	return &boss, nil
}

func (b Boss) CheckToken(token string) error {
	var bossSession model.BossSession
	bossFromDb := b.db.Table("tasks.boss_session").
		Where(`boss_session.auth_token = ?`, token).
		Row()

	err := bossFromDb.Scan(&bossSession.Id, &bossSession.DeviceCode,
		&bossSession.AuthToken, &bossSession.OriginalPass, &bossSession.ExpiresAt,
		&bossSession.PushToken, &bossSession.BossId)

	if err != nil {
		return err
	}

	return nil
}

func (b Boss) GetAuth(login string, password string, deviceCode string, pushToken string) (string, error) {
	var boss model.Boss

	staffFromDb := b.db.
		Table(fmt.Sprintf(`%s b`, new(model.Boss).TableName())).
		Where(`b.login = ?`, login).
		Row()

	err := staffFromDb.Scan(&boss.Id, &boss.Login, &boss.Pass)
	if err != nil {
		return "", err
	}

	err = bcrypt.CompareHashAndPassword([]byte(boss.Pass), []byte(password))
	if err != nil && err == bcrypt.ErrMismatchedHashAndPassword { //Пароль не совпадает!!
		return "", err
	}

	tk := &Token{UserId: boss.Id}
	token := jwt.NewWithClaims(jwt.GetSigningMethod("HS256"), tk)
	tokenString, _ := token.SignedString([]byte(os.Getenv("token_password")))
	//проверять наличие девайсИд и если есть, то обновлять токен, если нет, то добавлять

	var deviceCodeFromDb string
	bossSessionFromDb := b.db.Table("tasks.boss_session").
		Select(`boss_session.device_code`).
		Where(`boss_session.auth_token = ? and boss_session.device_code = ?`, tokenString, deviceCode).
		Row()

	err = bossSessionFromDb.Scan(&deviceCodeFromDb)
	if err != nil {
		if err == sql.ErrNoRows {
			bossSession := model.BossSession{
				DeviceCode:   deviceCode,
				AuthToken:    tokenString,
				OriginalPass: boss.Pass,
				ExpiresAt:    "2020-10-25T10:16:23.000Z",
				PushToken:    pushToken,
				BossId:       boss.Id,
			}

			d := b.db.Create(&bossSession).Scan(&bossSession)
			if d.Error != nil {
				return "", err
			}

			return tokenString, nil
		} else {
			return "", err
		}
	}

	err = b.db.
		Table(fmt.Sprintf(`%s ss`, new(model.BossSession).TableName())).
		//поменяла пароль на ид
		Where(`ss.boss_id = ? and ss.device_code = ?`, boss.Id, deviceCode).
		Updates(map[string]interface{}{"auth_token": tokenString, "device_code": deviceCode}).Error

	if err != nil {
		return "", err
	}

	return tokenString, nil
}

func (b Boss) UpdatePushToken(deviceId string, pushToken string) error {
	err := b.db.
		Table(fmt.Sprintf(`%s ss`, new(model.BossSession).TableName())).
		Where(`ss.device_code = ?`, deviceId).
		Updates(map[string]interface{}{"push_token": pushToken}).Error

	if err != nil {
		return err
	}
	return nil
}
