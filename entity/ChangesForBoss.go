package entity

type ChangesForBoss struct {
	Staff         []Staff                   `json:",omitempty"`
	Tasks         []GetTasksResponse        `json:",omitempty"`
	AwaitingTasks []GetAwaitingTaskResponse `json:",omitempty"`
}
