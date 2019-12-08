package dao

type Staff interface {
	Add(login string,
		phone string,
		passMd5 string) error
}
