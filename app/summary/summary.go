package summary

import (
	"github.com/elizavetamikhailova/TasksProject/dao"
	"github.com/elizavetamikhailova/TasksProject/dao/gorm/model"
)

type Summary struct {
	summaryDao dao.Summary
}

func NewAppSummary(summaryDao dao.Summary) Summary {
	return Summary{summaryDao: summaryDao}
}

type MostProductiveStaff struct {
	model.MostProductiveStaff
}

type MostActiveStaff struct {
	model.MostActiveStaff
}

type MostLatenessStaff struct {
	model.MostLatenessStaff
}

type MostProcratinatingStaff struct {
	model.MostProcratinatingStaff
}

type MostCancelStaff struct {
	model.MostCancelStaff
}

func (s *Summary) MostProductiveStaff() ([]MostProductiveStaff, error) {
	mostProductiveStaff, err := s.summaryDao.GetMostProductiveStaff()
	if err != nil {
		return nil, err
	}
	ud := make([]MostProductiveStaff, len(mostProductiveStaff))

	for k, v := range mostProductiveStaff {
		ud[k].MostProductiveStaff = v
	}

	return ud, nil
}

func (s *Summary) MostActiveStaff() ([]MostActiveStaff, error) {
	mostActiveStaff, err := s.summaryDao.GetMostActiveStaff()
	if err != nil {
		return nil, err
	}
	ud := make([]MostActiveStaff, len(mostActiveStaff))

	for k, v := range mostActiveStaff {
		ud[k].MostActiveStaff = v
	}

	return ud, nil
}

func (s *Summary) MostLatenessStaff() ([]MostLatenessStaff, error) {
	mostLatenessStaff, err := s.summaryDao.GetMostLatenessStaff()
	if err != nil {
		return nil, err
	}
	ud := make([]MostLatenessStaff, len(mostLatenessStaff))

	for k, v := range mostLatenessStaff {
		ud[k].MostLatenessStaff = v
	}

	return ud, nil
}

func (s *Summary) MostProcratinatingStaff() ([]MostProcratinatingStaff, error) {
	mostProcratinatingStaff, err := s.summaryDao.GetMostProcrastinatingStaff()
	if err != nil {
		return nil, err
	}
	ud := make([]MostProcratinatingStaff, len(mostProcratinatingStaff))

	for k, v := range mostProcratinatingStaff {
		ud[k].MostProcratinatingStaff = v
	}

	return ud, nil
}

func (s *Summary) MostCancelStaff() ([]MostCancelStaff, error) {
	mostCancelStaff, err := s.summaryDao.GetMostCancelStaff()
	if err != nil {
		return nil, err
	}
	ud := make([]MostCancelStaff, len(mostCancelStaff))

	for k, v := range mostCancelStaff {
		ud[k].MostCancelStaff = v
	}

	return ud, nil
}
