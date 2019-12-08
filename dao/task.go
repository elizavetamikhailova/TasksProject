package dao

type Task interface {
	AddTask(typeId int,
		staffId int,
		) error

	AddSubTask(
		typeId int,
		staffId int,
		parentId int,
		) error
}
