package router

import (
	"fmt"
	"goDial/internal/database"
	"goDial/internal/templates/pages"
	"net/http"
)

func handleHomePage(w http.ResponseWriter, r *http.Request) {
	pages.Home().Render(r.Context(), w)
}

func handleStripePage(db *database.DB) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		minutes, err := db.GetUserMinutes(r.Context(), "test@test.com")
		if err != nil {
			fmt.Printf("handleStripePage(couldnt get minutes for user): %v\n", err)
			minutes = 0
		}

		minutesInt := 0

		if m, ok := minutes.(int64); ok {
			minutesInt = int(m)
		}

		pages.Stripe(minutesInt).Render(r.Context(), w)
	}
}
