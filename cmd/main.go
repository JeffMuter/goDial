package main

import (
	"log"

	"goDial/internal/database"
)

func main() {
	// Initialize database
	dbPath := database.GetDBPath()
	db, err := database.InitDB(dbPath)
	if err != nil {
		log.Fatalf("Failed to initialize database: %v", err)
	}
	defer db.Close()

	log.Printf("Database initialized successfully at: %s", dbPath)
	log.Println("goDial application started")

	// TODO: Add web server and other application logic here
}
