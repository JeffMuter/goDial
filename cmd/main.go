package main

import (
	"log"
	"net/http"
	"os"

	"goDial/internal/router"
)

func main() {
	r := router.NewRouter()

	// Show startup message in development mode but make it more informative
	if os.Getenv("GO_ENV") == "development" && os.Getenv("AIR_ENABLED") == "1" {
		log.Println("🔄 Server restarting on :8081")
	} else {
		log.Println("Starting server on :8081")
	}

	if err := http.ListenAndServe(":8081", r); err != nil {
		log.Fatal(err)
	}
}
