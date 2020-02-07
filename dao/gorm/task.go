package gorm

import (
	"fmt"
	"github.com/elizavetamikhailova/TasksProject/dao"
	"github.com/elizavetamikhailova/TasksProject/dao/gorm/model"
	"github.com/elizavetamikhailova/TasksProject/entity"
	"github.com/jinzhu/gorm"
	"time"
)

type Task struct {
	db *gorm.DB
}

/*
SELECT staff_task.id, staff_task.parent_id, task_type.code, tasks_state.code, staff_task.started_at, staff_task.finished_at
FROM tasks.staff_task staff_task
join tasks.task_type task_type on (staff_task.type_id = task_type.id)
join tasks.tasks_state tasks_state on(staff_task.state_id = tasks_state.id)
WHERE (staff_task.staff_id = 1)
*/
func (t Task) GetTasksByStaffId(
	staffId int,
) ([]entity.GetTasksResponse, error) {
	var tasks []entity.GetTasksResponse

	tasksFromDb, err := t.db.
		Table(fmt.Sprintf(`%s staff_task`, new(model.Task).TableName())).
		Select(`staff_task.id, staff_task.parent_id, task_type.code, tasks_state.code, staff_task.started_at, staff_task.finished_at`).
		Joins("join tasks.task_type task_type on (staff_task.type_id = task_type.id)").
		Joins("join tasks.tasks_state tasks_state on(staff_task.state_id = tasks_state.id)").
		Joins("").
		Where(`staff_task.staff_id = ?`, staffId).
		Rows()

	if err != nil {
		return nil, err
	}

	for tasksFromDb.Next() {
		var task entity.GetTasksResponse
		err := tasksFromDb.Scan(&task.Id, &task.ParentId, &task.TypeCode, &task.StateCode, &task.StartedAt, &task.FinishedAt)
		if err != nil {
			return nil, err
		}
		flags, err := t.GetFlagsByTask(task.Id)
		if err != nil {
			return nil, err
		}
		task.Flags = flags

		switch task.TypeCode {
		case "FILL_TASK_FORM":
			task.Content, err = t.GetTasksForms(task.Id)
		case "TASK":
			task.Content, err = t.GetTaskContent(task.Id)
		}

		if err != nil {
			return nil, err
		}

		tasks = append(tasks, task)
	}

	return tasks, nil
}

func (t Task) GetTasksLastUpdate(
	staffId int,
	updateTime time.Time,
) ([]entity.GetTasksResponse, error) {
	var tasks []entity.GetTasksResponse

	tasksFromDb, err := t.db.
		Table(fmt.Sprintf(`%s staff_task`, new(model.Task).TableName())).
		Select(`staff_task.id, staff_task.parent_id, task_type.code, tasks_state.code, staff_task.expected_lead_time, 
				staff_task.difficulty_level, staff_task.started_at, staff_task.finished_at`).
		Joins("join tasks.task_type task_type on (staff_task.type_id = task_type.id)").
		Joins("join tasks.tasks_state tasks_state on(staff_task.state_id = tasks_state.id)").
		Where(`staff_task.staff_id = ? and staff_task.updated_at > ?`, staffId, updateTime).
		Rows()

	if err != nil {
		return nil, err
	}

	for tasksFromDb.Next() {
		var task model.GetTasksResponse
		err := tasksFromDb.Scan(&task.Id, &task.ParentId, &task.TypeCode, &task.StateCode, &task.ExpectedLeadTime,
			&task.DifficultyLevel, &task.StartedAt, &task.FinishedAt)
		if err != nil {
			return nil, err
		}

		flags, err := t.GetFlagsByTask(task.Id)
		if err != nil {
			return nil, err
		}
		var taskEntity = entity.GetTasksResponse{
			Id:               task.Id,
			ParentId:         task.ParentId,
			TypeCode:         task.TypeCode,
			StateCode:        task.StateCode,
			ExpectedLeadTime: task.ExpectedLeadTime.Float64,
			DifficultyLevel:  task.DifficultyLevel.Int64,
			StartedAt:        task.StartedAt.Time,
			FinishedAt:       task.FinishedAt.Time,
			Flags:            flags,
		}

		switch taskEntity.TypeCode {
		case "FILL_TASK_FORM":
			taskEntity.Content, err = t.GetTasksForms(taskEntity.Id)
		case "TASK":
			taskEntity.Content, err = t.GetTaskContent(task.Id)
		}

		if err != nil {
			return nil, err
		}

		tasks = append(tasks, taskEntity)
	}

	return tasks, nil
}

func (t Task) GetTasksLastUpdateForBoss(
	updateTime time.Time,
) ([]entity.GetTasksResponse, error) {
	var tasks []entity.GetTasksResponse

	tasksFromDb, err := t.db.
		Table(fmt.Sprintf(`%s staff_task`, new(model.Task).TableName())).
		Select(`staff_task.id, staff_task.staff_id, staff_task.parent_id, task_type.code, tasks_state.code, staff_task.expected_lead_time, 
				staff_task.difficulty_level, staff_task.started_at, staff_task.finished_at`).
		Joins("join tasks.task_type task_type on (staff_task.type_id = task_type.id)").
		Joins("join tasks.tasks_state tasks_state on(staff_task.state_id = tasks_state.id)").
		Where(`staff_task.updated_at > ?`, updateTime).
		Rows()

	if err != nil {
		return nil, err
	}

	for tasksFromDb.Next() {
		var task model.GetTasksResponse
		err := tasksFromDb.Scan(&task.Id, &task.StaffId, &task.ParentId, &task.TypeCode, &task.StateCode, &task.ExpectedLeadTime,
			&task.DifficultyLevel, &task.StartedAt, &task.FinishedAt)
		if err != nil {
			return nil, err
		}

		flags, err := t.GetFlagsByTask(task.Id)
		if err != nil {
			return nil, err
		}

		var taskEntity = entity.GetTasksResponse{
			Id:               task.Id,
			StaffId:          task.StaffId.Int64,
			ParentId:         task.ParentId,
			TypeCode:         task.TypeCode,
			StateCode:        task.StateCode,
			ExpectedLeadTime: task.ExpectedLeadTime.Float64,
			DifficultyLevel:  task.DifficultyLevel.Int64,
			StartedAt:        task.StartedAt.Time,
			FinishedAt:       task.FinishedAt.Time,
			Flags:            flags,
		}

		switch taskEntity.TypeCode {
		case "FILL_TASK_FORM":
			taskEntity.Content, err = t.GetTasksForms(taskEntity.Id)
		case "TASK":
			taskEntity.Content, err = t.GetTaskContent(task.Id)
		}

		if err != nil {
			return nil, err
		}

		tasks = append(tasks, taskEntity)
	}

	return tasks, nil
}

func (t Task) AddTask(typeId int, staffId int, parentId int, expectedLeadTime float64,
	difficultyLevel int64, flags []string) error {
	task := model.Task{Task: entity.Task{
		TypeId:           typeId,
		StaffId:          staffId,
		ParentId:         parentId,
		StateId:          1,
		ExpectedLeadTime: expectedLeadTime,
		DifficultyLevel:  difficultyLevel,
		CreatedAt:        time.Time{},
	}}

	d := t.db.Create(&task).Scan(&task)

	if d.Error != nil {
		return d.Error
	}

	err := t.AddFlags(flags, task.Id)

	if err != nil {
		return err
	}

	return nil
}

func (t Task) AddTaskWithContent(typeId int, staffId int, parentId int, expectedLeadTime float64,
	difficultyLevel int64, flags []string, content interface{}) error {
	task := model.Task{Task: entity.Task{
		TypeId:           typeId,
		StaffId:          staffId,
		ParentId:         parentId,
		StateId:          1,
		ExpectedLeadTime: expectedLeadTime,
		DifficultyLevel:  difficultyLevel,
		CreatedAt:        time.Time{},
	}}

	d := t.db.Create(&task).Scan(&task)

	if d.Error != nil {
		return d.Error
	}

	err := t.AddFlags(flags, task.Id)

	if err != nil {
		return err
	}

	switch task.TypeId {
	case 6:
		{
			var newContent = content.(entity.TaskContent)
			err = t.AddTaskContent(task.Id, newContent.Text, newContent.Title, newContent.Address)
			if err != nil {
				return err
			}
		}
	}

	return nil
}

func (t Task) UpdateTaskExpectedLeadTime(taskId int, newLeadTime int) error {
	return t.db.
		Table(fmt.Sprintf(`%s staff_task`, new(model.Task).TableName())).
		Where(`staff_task.id = ?`, taskId).
		Updates(map[string]interface{}{"updated_at": time.Now(), "expected_lead_time": newLeadTime}).Error
}

//update tasks.staff_task set state_id = 2
//from (SELECT tsc.state_to_id as new_state FROM tasks.task_state_change tsc
//where tsc.type_id = 2 and tsc.state_from_id = 1 and tsc.state_to_id = 2)
//as subquery
//where id =  13 and type_id = 2
func (t Task) UpdateTaskStatus(taskId int, stateTo int) error {
	var task entity.Task

	taskFromDB := t.db.
		Table(fmt.Sprintf(`%s staff_task`, new(model.Task).TableName())).
		Where(`staff_task.id = ?`, taskId).Row()

	err := taskFromDB.Scan(&task.Id, &task.TypeId, &task.StaffId, &task.StateId, &task.ParentId,
		&task.StartedAt, &task.FinishedAt, &task.CreatedAt, &task.UpdatedAt, &task.DeletedAt,
		&task.ExpectedLeadTime, &task.DifficultyLevel)

	println(task.Id, task.TypeId, task.StaffId, task.StateId, task.ParentId,
		task.ExpectedLeadTime, task.DifficultyLevel)

	if err != nil {
		return err
	}

	subQuery := t.db.Table(fmt.Sprintf(`%s task_state_change`, new(model.Task).StateChangesTableName())).
		Select(`task_state_change.state_to_id as new_state`).
		Where(`task_state_change.type_id = ? and task_state_change.state_from_id = ? and task_state_change.state_to_id = ?`,
			task.TypeId, task.StateId, stateTo).SubQuery()
	return t.db.
		Table(fmt.Sprintf(`%s staff_task`, new(model.Task).TableName())).
		Where(`staff_task.id = ? and staff_task.type_id = ?`, taskId, task.TypeId).
		Updates(map[string]interface{}{"updated_at": time.Now(), "state_id": subQuery}).Error
}

//select s.id,
//sum(case when st.difficulty_level is null then 0 else st.difficulty_level end +
//case when st.expected_lead_time is null then 0 else st.expected_lead_time end) as aggr
//from tasks.staff s
//left join tasks.staff_task st on (s.id = st.staff_id)
//where st.state_id = 1 or st.state_id = 2 or st.difficulty_level is null or st.expected_lead_time is null
//group by s.id

func (t Task) GetStaffWorkLoad() ([]entity.Workload, error) {
	var workloadByStaff []entity.Workload

	workloadFromDb, err := t.db.
		Table(fmt.Sprintf(`%s s`, new(model.Staff).TableName())).
		Select(`s.id, sum(case when st.difficulty_level is null then 0 else st.difficulty_level end + case when st.expected_lead_time is null then 0 else st.expected_lead_time end) as aggr`).
		Joins("left join tasks.staff_task st on (s.id = st.staff_id)").
		Where(`st.state_id = 1 or st.state_id = 2 or st.difficulty_level is null or st.expected_lead_time is null`).
		Group("s.id").
		Rows()

	if err != nil {
		return nil, err
	}

	for workloadFromDb.Next() {
		var workload entity.Workload
		err := workloadFromDb.Scan(&workload.StaffId, &workload.Aggr)
		if err != nil {
			return nil, err
		}
		workloadByStaff = append(workloadByStaff, workload)
	}

	return workloadByStaff, nil

}

func (t *Task) AddAwaitingTask(taskId int, staffId int) error {
	task := model.AwaitingTask{AwaitingTask: entity.AwaitingTask{
		TaskId:    taskId,
		StaffId:   staffId,
		StateId:   1,
		CreatedAt: time.Time{},
		UpdatedAt: time.Time{},
	}}

	return t.db.Create(&task).Error
}

func (t Task) AddTaskWithoutStaff(typeId int, expectedLeadTime float64,
	difficultyLevel int64, flags []string) (int, error) {

	task := model.Task{Task: entity.Task{
		TypeId:           typeId,
		StateId:          7,
		ExpectedLeadTime: expectedLeadTime,
		DifficultyLevel:  difficultyLevel,
		CreatedAt:        time.Time{},
	}}

	d := t.db.Create(&task).Scan(&task)

	if d.Error != nil {
		return 0, d.Error
	}

	err := t.AddFlags(flags, task.Id)

	if err != nil {
		return 0, err
	}

	return task.Id, nil
}

func (t Task) AddTaskWithAutomaticStaffSelection(typeId int, expectedLeadTime float64, difficultyLevel int64, flags []string) error {
	staffWorkLoad, err := t.GetStaffWorkLoad()
	if err != nil {
		return err
	}

	id, err := t.AddTaskWithoutStaff(typeId, expectedLeadTime, difficultyLevel, flags)

	if err != nil {
		return err
	}

	for _, v := range staffWorkLoad {
		err := t.AddAwaitingTask(id, v.StaffId)
		if err != nil {
			return err
		}
	}

	return nil
}

//update tasks.staff_task set state_id = 1, staff_id = 1
//from (select st.id from tasks.staff_task st where st.id = 38 and st.state_id = 7) as subquery
//where tasks.staff_task.id = subquery.id

type Result struct {
	TaskId int
}

func (t Task) UpdateAwaitingTaskToActive(taskId int, staffId int) error {

	//сделать транзакцию с делитом
	var result Result
	d := t.db.Raw("update tasks.staff_task set state_id = 1, staff_id = ?, updated_at = ? from "+
		"(select st.id from tasks.staff_task st where st.id = ? and st.state_id = 7) as subquery "+
		"where tasks.staff_task.id = subquery.id returning tasks.staff_task.id", staffId, time.Now(), taskId).Scan(&result)
	if d.Error != nil {
		return d.Error
	}

	//update tasks.awaiting_tasks set state_id = 2 where task_id = 38
	return t.db.
		Table(fmt.Sprintf(`%s awaiting_tasks`, new(model.Task).AwaitingTasksTableName())).
		Where(`awaiting_tasks.task_id = ?`, taskId).
		Updates(map[string]interface{}{"state_id": 2, "updated_at": time.Now()}).Error
}

func (t Task) GetFlagsByTask(taskId int) ([]string, error) {
	var flags []string

	flagsFromDb, err := t.db.Table(fmt.Sprintf(`%s tf`, new(model.Task).TasksFlagsTableName())).
		Select(`f.code`).
		Joins("join tasks.flags f on (tf.flag_id = f.id)").
		Where(`tf.task_id = ?`, taskId).
		Rows()

	if err != nil {
		return nil, err
	}

	for flagsFromDb.Next() {
		var flag string
		err := flagsFromDb.Scan(&flag)
		if err != nil {
			return nil, err
		}
		flags = append(flags, flag)
	}

	return flags, nil
}

func (t Task) AddFlags(flags []string, taskId int) error {

	for _, v := range flags {
		var id int
		flagIdFromDb := t.db.Table(fmt.Sprintf(`%s f`, new(model.Task).FlagTableName())).
			Select(`f.id`).
			Where(`f.code = ?`, v).
			Row()
		err := flagIdFromDb.Scan(&id)
		if err != nil {
			return err
		}

		flag := model.FlagsForTasks{Flag: entity.Flag{
			TaskId: taskId,
			FlagId: id,
		}}
		err = t.db.Create(&flag).Error
		if err != nil {
			return err
		}
	}

	return nil
}

func NewDaoTask(db *gorm.DB) dao.Task {
	return &Task{
		db: db,
	}
}

func (t Task) UpdateTaskStatusByBoss(taskId int, stateTo int) error {
	var task entity.Task

	taskFromDB := t.db.
		Table(fmt.Sprintf(`%s staff_task`, new(model.Task).TableName())).
		Where(`staff_task.id = ?`, taskId).Row()

	err := taskFromDB.Scan(&task.Id, &task.TypeId, &task.StaffId, &task.StateId, &task.ParentId,
		&task.StartedAt, &task.FinishedAt, &task.CreatedAt, &task.UpdatedAt, &task.DeletedAt,
		&task.ExpectedLeadTime, &task.DifficultyLevel)

	println(task.Id, task.TypeId, task.StaffId, task.StateId, task.ParentId,
		task.ExpectedLeadTime, task.DifficultyLevel)

	if err != nil {
		return err
	}

	subQuery := t.db.Table(fmt.Sprintf(`%s task_state_change`, new(model.Task).StateChangesForBossTableName())).
		Select(`task_state_change.state_to_id as new_state`).
		Where(`task_state_change.type_id = ? and task_state_change.state_from_id = ? and task_state_change.state_to_id = ?`,
			task.TypeId, task.StateId, stateTo).SubQuery()
	return t.db.
		Table(fmt.Sprintf(`%s staff_task`, new(model.Task).TableName())).
		Where(`staff_task.id = ? and staff_task.type_id = ?`, taskId, task.TypeId).
		Updates(map[string]interface{}{"updated_at": time.Now(), "state_id": subQuery}).Error
}

//5 исполнителей, у которых меньше всего заданий
//select s.id, count(*) as amount from tasks.staff s join tasks.staff_task st
//on (s.id = st.staff_id) where st.state_id = 1 or st.state_id = 2
//group by s.id order by amount desc limit 5

//5 исполнителей, у которых меньше всего часов занято заданиями
//select s.id, sum(st.expected_lead_time) as amount from tasks.staff s join tasks.staff_task st
//on (s.id = st.staff_id) where st.state_id = 1 or st.state_id = 2
//group by s.id order by amount desc limit 5

//5 исполнителей, сложность, количество, время
//вариант 1
//select s.id,
//sum(case when st.difficulty_level is null then 0 else st.difficulty_level end +
//case when st.expected_lead_time is null then 0 else st.expected_lead_time end) as aggr
//from tasks.staff s
//left join tasks.staff_task st on (s.id = st.staff_id)
//where st.state_id = 1 or st.state_id = 2 or st.difficulty_level is null or st.expected_lead_time is null
//group by s.id
//вариант 2
//select s.id, sum(st.difficulty_level + st.expected_lead_time) as aggr from tasks.staff s
//left join tasks.staff_task st on (s.id = st.staff_id)
//where st.state_id = 1 or st.state_id = 2 or st.difficulty_level is null or st.expected_lead_time is null
//group by s.id
