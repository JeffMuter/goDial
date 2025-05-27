package router

import (
	"fmt"
	"net/http"
	"os"
	"time"
)

func NewRouter() http.Handler {
	mux := http.NewServeMux()

	// Health check endpoint
	mux.HandleFunc("/health", handleHealthCheck)

	// Serve static files
	fs := http.FileServer(http.Dir("static"))
	mux.Handle("/static/", http.StripPrefix("/static/", fs))

	// Live reload endpoint for development
	mux.HandleFunc("/live-reload", handleLiveReload)

	// Routes
	mux.HandleFunc("/", handleHomePage)
	mux.HandleFunc("/stripePage", handleStripePage)

	return mux
}

// handleHealthCheck provides a simple health check endpoint
func handleHealthCheck(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	fmt.Fprintf(w, `{"status":"ok","timestamp":"%s"}`, time.Now().Format(time.RFC3339))
}

// handleLiveReload provides server-sent events for live reload functionality
func handleLiveReload(w http.ResponseWriter, r *http.Request) {
	// Only enable in development (when running through Air)
	if os.Getenv("AIR_ENABLED") == "" && os.Getenv("GO_ENV") != "development" {
		http.NotFound(w, r)
		return
	}

	w.Header().Set("Content-Type", "text/event-stream")
	w.Header().Set("Cache-Control", "no-cache")
	w.Header().Set("Connection", "keep-alive")
	w.Header().Set("Access-Control-Allow-Origin", "*")

	// Send initial connection message
	fmt.Fprintf(w, "data: connected\n\n")

	// Flush the response
	if flusher, ok := w.(http.Flusher); ok {
		flusher.Flush()
	}

	// Keep the connection alive and send periodic heartbeats
	ctx := r.Context()
	ticker := time.NewTicker(30 * time.Second)
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			// Client disconnected
			return
		case <-ticker.C:
			// Send heartbeat to keep connection alive
			fmt.Fprintf(w, "data: heartbeat\n\n")
			if flusher, ok := w.(http.Flusher); ok {
				flusher.Flush()
			}
		}
	}
}
