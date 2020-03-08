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

type Data struct {
	model.MostProductiveStaff
}

func (s *Summary) MostProductiveStaff() ([]Data, error) {
	mostProductiveStaff, err := s.summaryDao.GetMostProductiveStaff()
	if err != nil {
		return nil, err
	}
	ud := make([]Data, len(mostProductiveStaff))

	for k, v := range mostProductiveStaff {
		ud[k].MostProductiveStaff = v
	}

	return ud, nil
}
