package main

import (
	"awesomeProject1/api"
	"awesomeProject1/cmd/di"
	"awesomeProject1/configs"
	"github.com/jinzhu/configor"
	"net/http"
)


func main() {
	cfg := configs.Config{}
	if err := configor.Load(&cfg, "configs/config.yaml"); err != nil {
		panic(err)
	}
	container := di.GetDI(cfg)
	route := new(api.Router).Get(container)
	println("Hello!")

	if err := http.ListenAndServe(":7777", route); err != nil {
		panic(err)
	}
}