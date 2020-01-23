package main

import (
	"github.com/elizavetamikhailova/TasksProject/api"
	"github.com/elizavetamikhailova/TasksProject/cmd/di"
	"github.com/elizavetamikhailova/TasksProject/configs"
	"github.com/jinzhu/configor"
	"net/http"
)

func main() {
	cfg := configs.Config{}
	if err := configor.Load(&cfg, "configs/config.prod1.yaml", "configs/config.yaml"); err != nil {
		panic(err)
	}
	container := di.GetDI(cfg)
	route := new(api.Router).Get(container)
	println("Hello!")

	if err := http.ListenAndServe(":7777", route); err != nil {
		panic(err)
	}
}
