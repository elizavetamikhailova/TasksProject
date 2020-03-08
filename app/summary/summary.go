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
