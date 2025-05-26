package router

import (
	"net/http"

	"goDial/internal/templates/pages"
)

func NewRouter() http.Handler {
	mux := http.NewServeMux()

	// Serve static files
	fs := http.FileServer(http.Dir("static"))
	mux.Handle("/static/", http.StripPrefix("/static/", fs))

	// Routes
	mux.HandleFunc("/", handleHome)
	mux.HandleFunc("/simple", handleSimpleHome)

	return mux
}

func handleHome(w http.ResponseWriter, r *http.Request) {
	if r.URL.Path != "/" {
		http.NotFound(w, r)
		return
	}
	pages.Home().Render(r.Context(), w)
}

func handleSimpleHome(w http.ResponseWriter, r *http.Request) {
	pages.SimpleHome().Render(r.Context(), w)
}
