package router

import (
	"goDial/internal/templates/pages"
	"net/http"
)

func handleHomePage(w http.ResponseWriter, r *http.Request) {
	pages.Home().Render(r.Context(), w)
}

func handleStripePage(w http.ResponseWriter, r *http.Request) {
	pages.Stripe(36).Render(r.Context(), w)
}
