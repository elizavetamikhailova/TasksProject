package changes

import (
	"github.com/elizavetamikhailova/TasksProject/dao"
	"github.com/elizavetamikhailova/TasksProject/dao/gorm/model"
	"github.com/elizavetamikhailova/TasksProject/entity"
	"time"
)

type Changes struct {
	staffDAO   dao.Staff
	taskDAO    dao.Task
	AnswersDAO dao.StaffAnswers
}

func NewAppChanges(staffDAO dao.Staff, taskDAO dao.Task, answersDAO dao.StaffAnswers) Changes {
	return Changes{
		staffDAO:   staffDAO,
		taskDAO:    taskDAO,
		AnswersDAO: answersDAO,
	}
}

type ArgGetChanges struct {
	StaffId    int       `valid:"required"`
	UpdateTime time.Time `valid:"required"`
}

type ArgGetChangesForBoss struct {
	BossId     int       `valid:"required"`
	UpdateTime time.Time `valid:"required"`
}

type Data struct {
	entity.Changes
}

type DataForBoss struct {
	entity.ChangesForBoss
}

type TaskData struct {
	entity.GetTasksResponse
}

type StaffData struct {
	*entity.Staff
}

func (c *Changes) GetChanges(arg ArgGetChanges) (*Data, error) {

	staff, err := c.staffDAO.GetStaffLastUpdated(arg.StaffId, arg.UpdateTime)
	if err != nil {
		return nil, err
	}

	//sud := StaffData{staff}

	tasks, err := c.taskDAO.GetTasksLastUpdate(arg.StaffId, arg.UpdateTime)
	if err != nil {
		return nil, err
	}
	tud := make([]entity.GetTasksResponse, len(tasks))

	for k, v := range tasks {
		tud[k] = v
	}

	awaitingTasks, err := c.taskDAO.GetAwaitingTask(arg.StaffId, arg.UpdateTime)
	if err != nil {
		return nil, err
	}
	tud1 := make([]entity.GetAwaitingTaskResponse, len(awaitingTasks))

	for k, v := range awaitingTasks {
		tud1[k] = v
	}

	data := &Data{
		entity.Changes{
			Staff:         staff,
			Tasks:         tud,
			AwaitingTasks: tud1,
			UpdateTime:    time.Now(),
		},
	}

	return data, nil
}

func (c *Changes) GetChangesForBoss(arg ArgGetChangesForBoss) (*DataForBoss, error) {

	staff, err := c.staffDAO.GetStaffLastUpdatedForBoss(arg.BossId, arg.UpdateTime)
	if err != nil {
		return nil, err
	}

	//sud := StaffData{staff}

	tasks, err := c.taskDAO.GetTasksLastUpdateForBoss(arg.UpdateTime)
	if err != nil {
		return nil, err
	}
	tud := make([]entity.GetTasksResponse, len(tasks))

	for k, v := range tasks {
		tud[k] = v
	}

	data := &DataForBoss{
		entity.ChangesForBoss{
			Staff:      staff,
			Tasks:      tud,
			UpdateTime: time.Now(),
		},
	}

	return data, nil
}

//updateTaskLeadTime

type ArgUpdateTaskLeadTime struct {
	StaffId     int       `valid:"required"`
	TaskId      int       `valid:"required"`
	NewLeadTime float64   `valid:"required"`
	UpdateTime  time.Time `valid:"required"`
}

type ArgAddTaskForStaff struct {
	TypeId           int `valid:"required"`
	StaffId          int `valid:"required"`
	ParentId         int `json:",omitempty"`
	ExpectedLeadTime float64
	DifficultyLevel  int64
	Flags            []string
	UpdateTime       time.Time `valid:"required"`
}

type ArgAddTaskWithContent struct {
	TypeId           int `valid:"required"`
	StaffId          int `valid:"required"`
	ParentId         int `json:",omitempty"`
	ExpectedLeadTime float64
	DifficultyLevel  int64
	Flags            []string
	UpdateTime       time.Time `valid:"required"`
	Content          interface{}
}

type ArgUpdateTaskStatus struct {
	StaffId    int       `valid:"required"`
	TaskId     int       `valid:"required"`
	StateTo    int       `valid:"required"`
	UpdateTime time.Time `valid:"required"`
}

type ArgAddTaskWithAutomaticStaffSelection struct {
	BossId           int
	TypeId           int `valid:"required"`
	ExpectedLeadTime float64
	DifficultyLevel  int64
	Flags            []string
	UpdateTime       time.Time   `valid:"required"`
	Content          interface{} `json:",omitempty"`
}

type ArgUpdateAwaitingTaskToActive struct {
	StaffId    int       `valid:"required"`
	TaskId     int       `valid:"required"`
	UpdateTime time.Time `valid:"required"`
}

func (c *Changes) UpdateTaskExpectedLeadTime(arg ArgUpdateTaskLeadTime) error {
	return c.taskDAO.UpdateTaskExpectedLeadTime(arg.TaskId, arg.NewLeadTime)
}

func (c *Changes) AddTaskForStaff(arg ArgAddTaskForStaff) error {
	return c.taskDAO.AddTask(arg.TypeId, arg.StaffId, arg.ParentId, arg.ExpectedLeadTime, arg.DifficultyLevel, arg.Flags)
}

func (c *Changes) AddTaskWithContent(arg ArgAddTaskWithContent) error {
	var content interface{}
	switch arg.TypeId {
	case 6:
		{
			var jsonContent = arg.Content.(map[string]interface{})
			newContent := entity.TaskContent{
				Text:    jsonContent["Text"].(string),
				Title:   jsonContent["Title"].(string),
				Address: jsonContent["Address"].(string),
			}
			content = newContent
		}
	case 5:
		{
			var jsonContent = arg.Content.(map[string]interface{})
			newContent := model.AddStaffForm{
				GroupId: int(jsonContent["GroupId"].(float64)),
			}
			content = newContent
		}
	case 2:
		{
			var jsonContent = arg.Content.(map[string]interface{})
			newContent := model.ConfirmLeadTime{
				Creater: jsonContent["Creater"].(string),
			}
			content = newContent
		}

	}
	return c.taskDAO.AddTaskWithContent(arg.TypeId, arg.StaffId, arg.ParentId, arg.ExpectedLeadTime, arg.DifficultyLevel, arg.Flags, content)
}

func (c *Changes) UpdateTaskStatusByStaff(arg ArgUpdateTaskStatus) error {
	return c.taskDAO.UpdateTaskStatus(arg.TaskId, arg.StateTo)
}

func (c *Changes) UpdateTaskStatusByBoss(arg ArgUpdateTaskStatus) error {
	return c.taskDAO.UpdateTaskStatusByBoss(arg.TaskId, arg.StateTo)
}

func (c *Changes) AddTaskWithAutomaticStaffSelection(arg ArgAddTaskWithAutomaticStaffSelection) error {
	var content interface{}
	switch arg.TypeId {
	case 6:
		{
			var jsonContent = arg.Content.(map[string]interface{})
			newContent := entity.TaskContent{
				Text:    jsonContent["Text"].(string),
				Title:   jsonContent["Title"].(string),
				Address: jsonContent["Address"].(string),
			}
			content = newContent
		}
	}
	return c.taskDAO.AddTaskWithAutomaticStaffSelection(arg.BossId, arg.TypeId, arg.ExpectedLeadTime, arg.DifficultyLevel, arg.Flags, content)
}

func (c *Changes) UpdateAwaitingTaskToActive(arg ArgUpdateAwaitingTaskToActive) error {
	return c.taskDAO.UpdateAwaitingTaskToActive(arg.TaskId, arg.StaffId)
}

type ArgInsertAnswers struct {
	FormId       int       `valid:"required"`
	QuestionCode []string  `valid:"required"`
	StaffId      int       `valid:"required"`
	TaskId       int       `valid:"required"`
	UpdateTime   time.Time `valid:"required"`
}

func (c *Changes) Insert(arg ArgInsertAnswers) error {
	return c.AnswersDAO.InsertStaffAnswers(arg.FormId, arg.QuestionCode, arg.TaskId)
}

type ArgAddStaff struct {
	BossId     int       `valid:"required"`
	Login      string    `valid:"required"`
	Phone      string    `valid:"required"`
	PassMd5    string    `valid:"required"`
	UpdateTime time.Time `valid:"required"`
}

func (c *Changes) AddStaff(arg ArgAddStaff) error {
	return c.staffDAO.Add(arg.BossId, arg.Login, arg.Phone, arg.PassMd5)
}

type ArgAddComment struct {
	StaffId    int       `valid:"required"`
	TaskId     int       `valid:"required"`
	Text       string    `valid:"required"`
	UpdateTime time.Time `valid:"required"`
}

func (c *Changes) AddComment(arg ArgAddComment) error {
	return c.taskDAO.AddComment(arg.StaffId, arg.TaskId, arg.Text)
}
