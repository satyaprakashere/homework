package main

import (
	"net/http"
	"net/http/httptest"
	"net/url"
	"strings"
	"testing"
)

func TestAuthFlow(t *testing.T) {
	// 1. Test Register GET (Get CSRF Token)
	req1 := httptest.NewRequest("GET", "/register", nil)
	w1 := httptest.NewRecorder()
	registerHandler(w1, req1)

	if w1.Code != http.StatusOK {
		t.Errorf("Register GET failed: expected %d, got %d", http.StatusOK, w1.Code)
	}

	csrfCookie := ""
	for _, cookie := range w1.Result().Cookies() {
		if cookie.Name == "csrf_token" {
			csrfCookie = cookie.Value
		}
	}
	if csrfCookie == "" {
		t.Error("CSRF cookie not set on Register GET")
	}

	// 2. Test Register POST (with valid CSRF)
	form := url.Values{}
	form.Add("username", "testuser")
	form.Add("password", "testpass")
	form.Add("csrf_token", csrfCookie)

	req2 := httptest.NewRequest("POST", "/register", strings.NewReader(form.Encode()))
	req2.Header.Set("Content-Type", "application/x-www-form-urlencoded")
	req2.AddCookie(&http.Cookie{Name: "csrf_token", Value: csrfCookie})

	w2 := httptest.NewRecorder()
	registerHandler(w2, req2)

	if w2.Code != http.StatusSeeOther {
		t.Errorf("Register POST failed: expected %d, got %d. Body: %s", http.StatusSeeOther, w2.Code, w2.Body.String())
	}

	// 3. Test Login POST
	req3_get := httptest.NewRequest("GET", "/login", nil)
	w3_get := httptest.NewRecorder()
	loginHandler(w3_get, req3_get)
	
	loginCSRF := ""
	for _, cookie := range w3_get.Result().Cookies() {
		if cookie.Name == "csrf_token" {
			loginCSRF = cookie.Value
		}
	}

	loginForm := url.Values{}
	loginForm.Add("username", "testuser")
	loginForm.Add("password", "testpass")
	loginForm.Add("csrf_token", loginCSRF)

	req3 := httptest.NewRequest("POST", "/login", strings.NewReader(loginForm.Encode()))
	req3.Header.Set("Content-Type", "application/x-www-form-urlencoded")
	req3.AddCookie(&http.Cookie{Name: "csrf_token", Value: loginCSRF})

	w3 := httptest.NewRecorder()
	loginHandler(w3, req3)

	if w3.Code != http.StatusSeeOther {
		t.Errorf("Login POST failed: expected %d, got %d. Body: %s", http.StatusSeeOther, w3.Code, w3.Body.String())
	}

	sessionID := ""
	for _, cookie := range w3.Result().Cookies() {
		if cookie.Name == "session_id" {
			sessionID = cookie.Value
		}
	}
	if sessionID == "" {
		t.Error("Session ID cookie not set on Login POST")
	}
}
