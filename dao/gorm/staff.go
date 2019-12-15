package gorm

import (
	"fmt"
	"github.com/elizavetamikhailova/TasksProject/dao"
	"github.com/elizavetamikhailova/TasksProject/dao/gorm/model"
	"github.com/elizavetamikhailova/TasksProject/entity"
	"github.com/jinzhu/gorm"
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
) (*entity.Staff, error) {
	var staff entity.Staff

	staffFromDb := s.db.
		Table(fmt.Sprintf(`%s s`, new(model.Staff).TableName())).
		Where(`s.updated_at > ?`, updateTime).
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

func (s Staff) Add(login string, phone string, passMd5 string) error {

	staff := model.Staff{Staff: entity.Staff{
		Login:     login,
		Phone:     phone,
		PassMd5:   passMd5,
		CreatedAt: time.Time{},
	}}

	return s.db.Create(&staff).Error
}

func NewDaoStaff(db *gorm.DB) dao.Staff {
	return &Staff{
		db: db,
	}
}
