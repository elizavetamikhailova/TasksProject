package gorm

import (
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
	updateTime time.Time,
) ([]entity.Staff, error) {
	var staffList []entity.Staff

	staffFromDb, err := s.db.
		Table(fmt.Sprintf(`%s s`, new(model.Staff).TableName())).
		Where(`s.updated_at > ?`, updateTime).
		Rows()

	if err != nil {
		return nil, err
	}

	for staffFromDb.Next() {

		var staff entity.Staff

		err := staffFromDb.Scan(&staff.Id, &staff.Login, &staff.Phone,
			&staff.PassMd5, &staff.CreatedAt, &staff.UpdatedAt, &staff.DeletedAt, &staff.Practice)

		if err != nil {
			//if err == sql.ErrNoRows {
			//	return nil, nil
			//}
			return nil, err
		}

		staffList = append(staffList, staff)
	}

	return staffList, nil
}

func (s Staff) Add(login string, phone string, passMd5 string) error {

	staff := model.Staff{Staff: entity.Staff{
		Login:     login,
		Phone:     phone,
		CreatedAt: time.Time{},
	}}

	//err := s.db.Create(&staff).Error
	//
	//if err != nil {
	//	return err
	//}

	return s.CreateAccount(staff, passMd5, "", "")
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

	err = s.db.
		Table(fmt.Sprintf(`%s ss`, new(model.StaffSession).TableName())).
		Where(`ss.original_pass = ?`, staff.PassMd5).
		Updates(map[string]interface{}{"auth_token": tokenString}).Error

	if err != nil {
		return "", err
	}

	return tokenString, nil
}

func (s Staff) CreateAccount(staff model.Staff, password string, deviceCode string, pushToken string) error {
	hashedPassword, _ := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	staff.PassMd5 = string(hashedPassword)
	d := s.db.Create(&staff).Scan(&staff)

	if d.Error != nil {
		return d.Error
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

func NewDaoStaff(db *gorm.DB) dao.Staff {
	return &Staff{
		db: db,
	}
}
