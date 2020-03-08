package gorm

import (
	"github.com/elizavetamikhailova/TasksProject/dao"
	"github.com/elizavetamikhailova/TasksProject/dao/gorm/model"
	"github.com/jinzhu/gorm"
)

type Summary struct {
	db *gorm.DB
}

func NewDaoSummary(db *gorm.DB) dao.Summary {
	return &Summary{
		db: db,
	}
}

func (s Summary) GetMostProductiveStaff() ([]model.MostProductiveStaff, error) {
	var mostProductiveStaffList []model.MostProductiveStaff

	mostProductiveStaffListFromDB, err := s.db.Raw(
		"select s.id, s.login, " +
			"count(EXTRACT(epoch FROM (st.finished_at - st.started_at))/st.difficulty_level) as weight " +
			"from tasks.staff s join tasks.staff_task st on (s.id = st.staff_id) " +
			"where (st.finished_at - st.started_at) > '0 hour' " +
			"and st.difficulty_level > 0 group by s.login, s.id order by weight").Rows()

	if err != nil {
		return nil, err
	}

	for mostProductiveStaffListFromDB.Next() {
		var mostProductiveStaff model.MostProductiveStaff
		err := mostProductiveStaffListFromDB.Scan(&mostProductiveStaff.StaffId,
			&mostProductiveStaff.StaffLogin, &mostProductiveStaff.Weight)
		if err != nil {
			return nil, err
		}
		mostProductiveStaffList = append(mostProductiveStaffList, mostProductiveStaff)
	}
	return mostProductiveStaffList, nil
}

func (s Summary) GetMostActiveStaff() ([]model.MostActiveStaff, error) {
	var mostActiveStaffList []model.MostActiveStaff

	mostActiveStaffListFromDB, err := s.db.Raw(
		"select s.id, s.login, count(*) as amount " +
			"from tasks.awaiting_tasks awt join tasks.staff_task st " +
			"on (awt.task_id = st.id and awt.staff_id = st.staff_id) " +
			"join tasks.staff s on (st.staff_id = s.id) " +
			"group by s.login, s.id order by amount desc").Rows()

	if err != nil {
		return nil, err
	}

	for mostActiveStaffListFromDB.Next() {
		var mostActiveStaff model.MostActiveStaff
		err := mostActiveStaffListFromDB.Scan(&mostActiveStaff.StaffId,
			&mostActiveStaff.StaffLogin, &mostActiveStaff.Amount)
		if err != nil {
			return nil, err
		}
		mostActiveStaffList = append(mostActiveStaffList, mostActiveStaff)
	}
	return mostActiveStaffList, nil
}

func (s Summary) GetMostLatenessStaff() ([]model.MostLatenessStaff, error) {
	var mostLatenessStaffList []model.MostLatenessStaff

	mostLatenessStaffListFromDB, err := s.db.Raw(
		"select s.id, s.login, count(*) as amount " +
			"from tasks.staff_task st join tasks.staff s " +
			"on (st.staff_id = s.id) join tasks.staff_form sf " +
			"on (st.id = sf.task_id) where st.type_id = 5 and " +
			"sf.group_id = 1 group by s.login, s.id order by amount desc").Rows()

	if err != nil {
		return nil, err
	}

	for mostLatenessStaffListFromDB.Next() {
		var mostLatenessStaff model.MostLatenessStaff
		err := mostLatenessStaffListFromDB.Scan(&mostLatenessStaff.StaffId,
			&mostLatenessStaff.StaffLogin, &mostLatenessStaff.Amount)
		if err != nil {
			return nil, err
		}
		mostLatenessStaffList = append(mostLatenessStaffList, mostLatenessStaff)
	}
	return mostLatenessStaffList, nil
}

func (s Summary) GetMostProcrastinatingStaff() ([]model.MostProcratinatingStaff, error) {
	var mostProcrastinatingStaffList []model.MostProcratinatingStaff

	mostProcrastinatingStaffListFromDB, err := s.db.Raw(
		" select s.id, s.login, count(*) as amount " +
			"from tasks.staff_task st join tasks.staff s on " +
			"(st.staff_id = s.id) join tasks.staff_form sf on " +
			"(st.id = sf.task_id) where  st.type_id = 5 and sf.group_id = 2 " +
			"group by s.login, s.id order by amount desc").Rows()

	if err != nil {
		return nil, err
	}

	for mostProcrastinatingStaffListFromDB.Next() {
		var mostProcrastinatingStaff model.MostProcratinatingStaff
		err := mostProcrastinatingStaffListFromDB.Scan(&mostProcrastinatingStaff.StaffId,
			&mostProcrastinatingStaff.StaffLogin, &mostProcrastinatingStaff.Amount)
		if err != nil {
			return nil, err
		}
		mostProcrastinatingStaffList = append(mostProcrastinatingStaffList, mostProcrastinatingStaff)
	}
	return mostProcrastinatingStaffList, nil
}

func (s Summary) GetMostCancelStaff() ([]model.MostCancelStaff, error) {
	var mostCancelStaffList []model.MostCancelStaff

	mostCancelStaffListFromDB, err := s.db.Raw(
		" select s.id, s.login, count(*) as amount " +
			"from tasks.staff_task st join tasks.staff s " +
			"on (st.staff_id = s.id) where  st.state_id = 5 " +
			"or st.state_id = 6 group by s.login, s.id " +
			"order by amount desc").Rows()

	if err != nil {
		return nil, err
	}

	for mostCancelStaffListFromDB.Next() {
		var mostCancelStaff model.MostCancelStaff
		err := mostCancelStaffListFromDB.Scan(&mostCancelStaff.StaffId,
			&mostCancelStaff.StaffLogin, &mostCancelStaff.Amount)
		if err != nil {
			return nil, err
		}
		mostCancelStaffList = append(mostCancelStaffList, mostCancelStaff)
	}
	return mostCancelStaffList, nil
}
