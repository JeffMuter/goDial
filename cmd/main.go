package main

import (
	"log"
	"net/http"

	"goDial/internal/router"
)

func main() {
	r := router.NewRouter()

	log.Println("Starting server on :8080")
	if err := http.ListenAndServe(":8080", r); err != nil {
		log.Fatal(err)
	}
}
