package di

import (
	"fmt"
	"github.com/elizavetamikhailova/TasksProject/app/staff"
	"github.com/elizavetamikhailova/TasksProject/app/task"
	"github.com/elizavetamikhailova/TasksProject/configs"
	dao "github.com/elizavetamikhailova/TasksProject/dao/gorm"
	"github.com/jinzhu/gorm"
	_ "github.com/jinzhu/gorm/dialects/postgres"
	"go.uber.org/dig"
	"log"
	"os"
)

func GetDI(cfg configs.Config) *dig.Container {
	di := dig.New()
	di.Provide(func() *gorm.DB {
		db, err := gorm.Open("postgres",
			fmt.Sprintf("host=%s port=%d user=%s dbname=%s password=%s sslmode=disable",
				cfg.DB.Host, cfg.DB.Port, cfg.DB.User, cfg.DB.Db, cfg.DB.Password,
			),
		)
		if err != nil {
			panic(err)
		}
		db.LogMode(true)
		db.SetLogger(log.New(os.Stdout, "\r\n", 0))
		return db
	})

	di.Provide(dao.NewDaoStaff)
	di.Provide(staff.NewAppStaff)

	di.Provide(dao.NewDaoTask)
	di.Provide(task.NewAppTask)

	return di
}
