package configs

type Config struct {
	DB struct{
		Host string //`default:"localhost"`
		Name     string
		Db       string
		User     string //`default:"root"`
		Password string
		Port     uint
	}
}

