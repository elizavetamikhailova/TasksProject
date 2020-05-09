package gorm

import (
	"database/sql"
	"fmt"
	"github.com/dgrijalva/jwt-go"
	"github.com/elizavetamikhailova/TasksProject/dao"
	"github.com/elizavetamikhailova/TasksProject/dao/gorm/model"
	"github.com/elizavetamikhailova/TasksProject/entity"
	"github.com/jinzhu/gorm"
	"golang.org/x/crypto/bcrypt"
	"os"
	"time"
)

type Staff struct {
	db *gorm.DB
}

func (s Staff) GetStaffLastUpdated(
	staffId int,
	updateTime time.Time,
) (*entity.Staff, error) {
	var staff entity.Staff

	staffFromDb := s.db.
		Table(fmt.Sprintf(`%s s`, new(model.Staff).TableName())).
		Where(`s.id = ? and s.updated_at > ?`, staffId, updateTime).
		Row()

	err := staffFromDb.Scan(&staff.Id, &staff.Login, &staff.Phone,
		&staff.PassMd5, &staff.CreatedAt, &staff.UpdatedAt, &staff.DeletedAt, &staff.Practice)
	if err != nil {
		//if err == sql.ErrNoRows {
		//	return nil, nil
		//}
		return nil, err
	}

	return &staff, nil
}

func (s Staff) GetStaffLastUpdatedForBoss(
	bossId int,
	updateTime time.Time,
) ([]entity.Staff, error) {

	var staffList []entity.Staff

	staffIdsFromDb, err := s.db.Table("tasks.staff_to_boss").
		Select(`staff_to_boss.staff_id`).
		Where(`staff_to_boss.boss_id = ?`, bossId).
		Rows()

	if err != nil {
		return nil, err
	}

	for staffIdsFromDb.Next() {
		var id int
		err = staffIdsFromDb.Scan(&id)

		if err != nil {
			return nil, err
		}

		staffFromDb, err := s.db.
			Table(fmt.Sprintf(`%s s`, new(model.Staff).TableName())).
			Where(`s.updated_at > ? and s.id = ?`, updateTime, id).
			Rows()

		if err != nil {
			return nil, err
		}

		for staffFromDb.Next() {

			var staff entity.Staff

			err := staffFromDb.Scan(&staff.Id, &staff.Login, &staff.Phone,
				&staff.PassMd5, &staff.CreatedAt, &staff.UpdatedAt, &staff.DeletedAt, &staff.Practice)

			if err != nil {
				return nil, err
			}

			staffList = append(staffList, staff)
		}

	}

	return staffList, nil
}

func (s Staff) GetUserInfo(login string) (*entity.Staff, error) {
	var staff entity.Staff

	staffFromDb := s.db.
		Table(fmt.Sprintf(`%s s`, new(model.Staff).TableName())).
		Where(`s.login = ?`, login).
		Row()

	err := staffFromDb.Scan(&staff.Id, &staff.Login, &staff.Phone,
		&staff.PassMd5, &staff.CreatedAt, &staff.UpdatedAt, &staff.DeletedAt, &staff.Practice)
	if err != nil {
		//if err == sql.ErrNoRows {
		//	return nil, nil
		//}
		return nil, err
	}

	return &staff, nil
}
func (s Staff) Add(bossId int, login string, phone string, passMd5 string) error {

	staff := model.Staff{Staff: entity.Staff{
		Login:     login,
		Phone:     phone,
		CreatedAt: time.Time{},
	}}

	return s.CreateAccount(bossId, staff, passMd5, "", "")
}

func (s Staff) ChangePassword(staffId int, pass string, oldPass string) error {

	var staff entity.Staff

	staffFromDb := s.db.
		Table(fmt.Sprintf(`%s s`, new(model.Staff).TableName())).
		Where(`s.id = ?`, staffId).
		Row()

	err := staffFromDb.Scan(&staff.Id, &staff.Login, &staff.Phone,
		&staff.PassMd5, &staff.CreatedAt, &staff.UpdatedAt, &staff.DeletedAt, &staff.Practice)

	if err != nil {
		return err
	}

	err = bcrypt.CompareHashAndPassword([]byte(staff.PassMd5), []byte(oldPass))
	if err != nil && err == bcrypt.ErrMismatchedHashAndPassword { //Пароль не совпадает!!
		return err
	}

	hashedPassword, _ := bcrypt.GenerateFromPassword([]byte(pass), bcrypt.DefaultCost)
	err = s.db.
		Table(fmt.Sprintf(`%s ss`, new(model.StaffSession).TableName())).
		Where(`ss.staff_id = ?`, staffId).
		Updates(map[string]interface{}{"original_pass": hashedPassword}).Error

	if err != nil {
		return err
	}

	err = s.db.
		Table(fmt.Sprintf(`%s ss`, new(model.Staff).TableName())).
		Where(`ss.id = ?`, staffId).
		Updates(map[string]interface{}{"pass_md5": hashedPassword}).Error

	if err != nil {
		return err
	}

	return nil
}

func (s Staff) ChangeLogin(staffId int, login string) error {

	err := s.db.
		Table(fmt.Sprintf(`%s ss`, new(model.Staff).TableName())).
		Where(`ss.id = ?`, staffId).
		Updates(map[string]interface{}{"login": login}).Error

	if err != nil {
		return err
	}

	return nil
}

func (s Staff) ChangePhone(staffId int, phone string) error {

	err := s.db.
		Table(fmt.Sprintf(`%s ss`, new(model.Staff).TableName())).
		Where(`ss.id = ?`, staffId).
		Updates(map[string]interface{}{"phone": phone}).Error

	if err != nil {
		return err
	}

	return nil
}

func (s Staff) CheckToken(token string) error {
	var staffSession model.StaffSession
	staffSessionFromDb := s.db.Table("tasks.staff_session").
		Where(`staff_session.auth_token = ?`, token).
		Row()

	err := staffSessionFromDb.Scan(&staffSession.Id, &staffSession.DeviceCode,
		&staffSession.AuthToken, &staffSession.OriginalPass, &staffSession.ExpiresAt,
		&staffSession.PushToken, &staffSession.StaffId)

	if err != nil {
		return err
	}

	return nil
}

type Token struct {
	UserId int
	jwt.StandardClaims
}

func (s Staff) GetAuth(login string, password string, deviceCode string, pushToken string) (string, error) {
	var staff entity.Staff

	staffFromDb := s.db.
		Table(fmt.Sprintf(`%s s`, new(model.Staff).TableName())).
		Where(`s.login = ?`, login).
		Row()

	err := staffFromDb.Scan(&staff.Id, &staff.Login, &staff.Phone,
		&staff.PassMd5, &staff.CreatedAt, &staff.UpdatedAt, &staff.DeletedAt, &staff.Practice)
	if err != nil {
		return "", err
	}

	err = bcrypt.CompareHashAndPassword([]byte(staff.PassMd5), []byte(password))
	if err != nil && err == bcrypt.ErrMismatchedHashAndPassword { //Пароль не совпадает!!
		return "", err
	}

	tk := &Token{UserId: staff.Id}
	token := jwt.NewWithClaims(jwt.GetSigningMethod("HS256"), tk)
	tokenString, _ := token.SignedString([]byte(os.Getenv("token_password")))
	//проверять наличие девайсИд и если есть, то обновлять токен, если нет, то добавлять

	var deviceCodeFromDb string
	staffSessionFromDb := s.db.Table("tasks.staff_session").
		Select(`staff_session.device_code`).
		Where(`staff_session.auth_token = ? and staff_session.device_code = ?`, tokenString, deviceCode).
		Row()

	err = staffSessionFromDb.Scan(&deviceCodeFromDb)
	if err != nil {
		if err == sql.ErrNoRows {
			staffSession := model.StaffSession{
				DeviceCode:   deviceCode,
				AuthToken:    tokenString,
				OriginalPass: staff.PassMd5,
				ExpiresAt:    "2020-10-25T10:16:23.000Z",
				PushToken:    pushToken,
				StaffId:      staff.Id,
			}

			d := s.db.Create(&staffSession).Scan(&staffSession)
			if d.Error != nil {
				return "", err
			}

			return tokenString, nil
		} else {
			return "", err
		}
	}

	//если не создаем новую запись, то обнавляем старую и едем дальше

	err = s.db.
		Table(fmt.Sprintf(`%s ss`, new(model.StaffSession).TableName())).
		//поменяла пароль на ид
		Where(`ss.staff_id = ? and ss.device_code = ?`, staff.Id, deviceCode).
		Updates(map[string]interface{}{"auth_token": tokenString, "device_code": deviceCode}).Error

	if err != nil {
		return "", err
	}

	return tokenString, nil
}

func (s Staff) CreateAccount(bossId int, staff model.Staff, password string, deviceCode string, pushToken string) error {
	hashedPassword, _ := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	staff.PassMd5 = string(hashedPassword)
	d := s.db.Create(&staff).Scan(&staff)

	if d.Error != nil {
		return d.Error
	}

	staffToBoss := model.StaffToBoss{
		StaffId: staff.Id,
		BossId:  bossId,
	}
	k := s.db.Create(&staffToBoss).Scan(&staffToBoss)

	if k.Error != nil {
		return k.Error
	}

	tk := &Token{UserId: staff.Id}
	token := jwt.NewWithClaims(jwt.GetSigningMethod("HS256"), tk)
	tokenString, _ := token.SignedString([]byte(os.Getenv("token_password")))

	staffSession := model.StaffSession{
		DeviceCode:   deviceCode,
		AuthToken:    tokenString,
		OriginalPass: staff.PassMd5,
		ExpiresAt:    "2020-10-25T10:16:23.000Z",
		PushToken:    pushToken,
		StaffId:      staff.Id,
	}

	err := s.db.Create(&staffSession).Error //TODO проверить

	if err != nil {
		return err
	}

	return nil
}

func (s Staff) UpdatePushToken(deviceId string, pushToken string) error {
	err := s.db.
		Table(fmt.Sprintf(`%s ss`, new(model.StaffSession).TableName())).
		Where(`ss.device_code = ?`, deviceId).
		Updates(map[string]interface{}{"push_token": pushToken}).Error

	if err != nil {
		return err
	}
	return nil
}

func NewDaoStaff(db *gorm.DB) dao.Staff {
	return &Staff{
		db: db,
	}
}
