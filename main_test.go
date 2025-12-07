package main

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

// Test healthHandler
func TestHealthHandler(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/health", nil)
	rr := httptest.NewRecorder()

	healthHandler(rr, req)

	if status := rr.Code; status != http.StatusOK {
		t.Fatalf("expected status %d, got %d", http.StatusOK, status)
	}

	if body := rr.Body.String(); body != "OK" {
		t.Fatalf("expected body 'OK', got '%s'", body)
	}
}

// Test mainHandler (workers + final output)
func TestMainHandler(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/", nil)
	rr := httptest.NewRecorder()

	mainHandler(rr, req)

	if status := rr.Code; status != http.StatusOK {
		t.Fatalf("expected status 200, got %d", status)
	}

	body := rr.Body.String()

	if !strings.Contains(body, "Completed 5 workers") {
		t.Errorf("expected worker completion message, got '%s'", body)
	}

	if !strings.Contains(body, "CPUs") {
		t.Errorf("expected CPU info in response, got '%s'", body)
	}
}
