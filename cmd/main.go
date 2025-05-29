package main

import (
	"log"
	"net/http"
	"os"

	"goDial/internal/database"
	"goDial/internal/router"
)

func main() {
	db, err := database.InitDB("goDial.db")
	if err != nil {
		db, err := database.InitDB("goDial.db")
		if err != nil {
			log.Fatal(err)
		}
		defer db.Close()
		log.Fatal(err)
	}
	defer db.Close()

	r := router.NewRouter(db)

	// Show startup message in development mode but make it more informative
	if os.Getenv("GO_ENV") == "development" && os.Getenv("AIR_ENABLED") == "1" {
		log.Println("Server restarting on :8081")
	} else {
		log.Println("Starting server on :8081")
	}

	if err := http.ListenAndServe(":8081", r); err != nil {
		log.Fatal(err)
	}
}
