package main

import (
	"crypto/rand"
	"database/sql"
	"encoding/base64"
	"fmt"
	"html/template"
	"log"
	"net/http"
	"strings"
	"time"

	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"
	_ "modernc.org/sqlite"
)

const DB_NAME = "news.db"

type Post struct {
	ID        int
	Title     string
	URL       string
	Score     int
	CreatedAt string
	Username  string
	FullURL   string
}

type User struct {
	ID           int
	Username     string
	PasswordHash string
}

func extractDomain(rawURL string) string {
	if rawURL == "" {
		return ""
	}
	parts := strings.Split(rawURL, "//")
	if len(parts) > 1 {
		domain := strings.Split(parts[1], "/")[0]
		return domain
	}
	return rawURL
}

func generateCSRFToken() string {
	b := make([]byte, 32)
	rand.Read(b)
	return base64.StdEncoding.EncodeToString(b)
}

func main() {
	http.Handle("/static/", http.StripPrefix("/static/", http.FileServer(http.Dir("static"))))
	http.HandleFunc("/manifest.json", func(w http.ResponseWriter, r *http.Request) {
		http.ServeFile(w, r, "static/manifest.json")
	})
	http.HandleFunc("/sw.js", func(w http.ResponseWriter, r *http.Request) {
		http.ServeFile(w, r, "static/sw.js")
	})
	http.HandleFunc("/", indexHandler)
	http.HandleFunc("/submit", submitHandler)
	http.HandleFunc("/login", loginHandler)
	http.HandleFunc("/logout", logoutHandler)
	http.HandleFunc("/register", registerHandler)

	fmt.Println("Server starting on http://localhost:9000")
	log.Fatal(http.ListenAndServe(":9000", nil))
}

func getCurrentUser(r *http.Request) (*User, error) {
	cookie, err := r.Cookie("session_id")
	if err != nil {
		return nil, err
	}

	db, err := getDB()
	if err != nil {
		return nil, err
	}
	defer db.Close()

	var u User
	err = db.QueryRow(`
		SELECT u.id, u.username 
		FROM users u 
		JOIN sessions s ON u.id = s.user_id 
		WHERE s.id = ? AND s.expires_at > datetime('now')
	`, cookie.Value).Scan(&u.ID, &u.Username)
	if err != nil {
		return nil, err
	}

	return &u, nil
}

func registerHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method == http.MethodGet {
		token := generateCSRFToken()
		http.SetCookie(w, &http.Cookie{
			Name:     "csrf_token",
			Value:    token,
			Path:     "/", HttpOnly: true, SameSite: http.SameSiteLaxMode,
			HttpOnly: true,
			SameSite: http.SameSiteLaxMode,
			MaxAge: 3600,
		})

		tmpl, err := template.ParseFiles("templates/register.html")
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		data := struct{ CSRFToken string }{CSRFToken: token}
		tmpl.Execute(w, data)
		return
	}

	if r.Method == http.MethodPost {
		// CSRF Validation
		cookie, err := r.Cookie("csrf_token")
		if err != nil || cookie.Value == "" || cookie.Value != r.FormValue("csrf_token") {
			http.Error(w, "Forbidden: Invalid CSRF token", http.StatusForbidden)
			return
		}

		username := r.FormValue("username")
		password := r.FormValue("password")

		if username == "" || password == "" {
			http.Error(w, "Username and password are required", http.StatusBadRequest)
			return
		}

		hash, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		db, err := getDB()
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		defer db.Close()

		fmt.Println("Register POST: executing INSERT")
		_, err = db.Exec("INSERT INTO users (username, password_hash) VALUES (?, ?)", username, string(hash))
		fmt.Println("Register POST: INSERT done")
		if err != nil {
			http.Error(w, "Username already exists", http.StatusBadRequest)
			return
		}

		http.Redirect(w, r, "/login", http.StatusSeeOther)
		return
	}
}

func loginHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method == http.MethodGet {
		token := generateCSRFToken()
		http.SetCookie(w, &http.Cookie{
			Name:     "csrf_token",
			Value:    token,
			Path:     "/", HttpOnly: true, SameSite: http.SameSiteLaxMode,
			HttpOnly: true,
			SameSite: http.SameSiteLaxMode,
			MaxAge: 3600,
		})

		tmpl, err := template.ParseFiles("templates/login.html")
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		data := struct{ CSRFToken string }{CSRFToken: token}
		tmpl.Execute(w, data)
		return
	}

	if r.Method == http.MethodPost {
		// CSRF Validation
		cookie, err := r.Cookie("csrf_token")
		if err != nil || cookie.Value == "" || cookie.Value != r.FormValue("csrf_token") {
			http.Error(w, "Forbidden: Invalid CSRF token", http.StatusForbidden)
			return
		}

		username := r.FormValue("username")
		password := r.FormValue("password")

		fmt.Println("Login POST: getting DB")
		db, err := getDB()
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		defer db.Close()

		var u User
		fmt.Println("Login POST: querying user")
		err = db.QueryRow("SELECT id, username, password_hash FROM users WHERE username = ?", username).Scan(&u.ID, &u.Username, &u.PasswordHash)
		fmt.Println("Login POST: query done")
		if err != nil {
			http.Error(w, "Invalid username or password", http.StatusUnauthorized)
			return
		}

		err = bcrypt.CompareHashAndPassword([]byte(u.PasswordHash), []byte(password))
		if err != nil {
			http.Error(w, "Invalid username or password", http.StatusUnauthorized)
			return
		}

		sessionID := uuid.New().String()
		expiresAt := time.Now().Add(24 * time.Hour)

		_, err = db.Exec("INSERT INTO sessions (id, user_id, expires_at) VALUES (?, ?, ?)", sessionID, u.ID, expiresAt)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		http.SetCookie(w, &http.Cookie{
			Name:     "session_id",
			Value:    sessionID,
			Expires:  expiresAt,
			Path:     "/", HttpOnly: true, SameSite: http.SameSiteLaxMode, MaxAge: 3600,
		})

		http.Redirect(w, r, "/", http.StatusSeeOther)
		return
	}
}

func logoutHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method == http.MethodPost {
		// CSRF Validation
		cookie, err := r.Cookie("csrf_token")
		if err != nil || cookie.Value == "" || cookie.Value != r.FormValue("csrf_token") {
			http.Error(w, "Forbidden: Invalid CSRF token", http.StatusForbidden)
			return
		}

		sessionCookie, err := r.Cookie("session_id")
		if err == nil {
			db, err := getDB()
			if err == nil {
				defer db.Close()
				db.Exec("DELETE FROM sessions WHERE id = ?", sessionCookie.Value)
			}
		}
	}

	http.SetCookie(w, &http.Cookie{
		Name:     "session_id",
		Value:    "",
		Expires:  time.Now().Add(-1 * time.Hour),
		Path:     "/", HttpOnly: true, SameSite: http.SameSiteLaxMode, MaxAge: 3600,
	})

	http.Redirect(w, r, "/", http.StatusSeeOther)
}

func submitHandler(w http.ResponseWriter, r *http.Request) {
	user, err := getCurrentUser(r)
	if err != nil {
		http.Redirect(w, r, "/login", http.StatusSeeOther)
		return
	}

	if r.Method == http.MethodGet {
		token := generateCSRFToken()
		http.SetCookie(w, &http.Cookie{
			Name:     "csrf_token",
			Value:    token,
			Path:     "/", HttpOnly: true, SameSite: http.SameSiteLaxMode, MaxAge: 3600,
		})

		tmpl, err := template.ParseFiles("templates/submit.html")
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		data := struct {
			CSRFToken string
			User      *User
		}{
			CSRFToken: token,
			User:      user,
		}
		tmpl.Execute(w, data)
		return
	}

	if r.Method == http.MethodPost {
		user, err := getCurrentUser(r)
		if err != nil {
			http.Redirect(w, r, "/login", http.StatusSeeOther)
			return
		}

		// CSRF Validation
		cookie, err := r.Cookie("csrf_token")
		if err != nil || cookie.Value == "" || cookie.Value != r.FormValue("csrf_token") {
			http.Error(w, "Forbidden: Invalid CSRF token", http.StatusForbidden)
			return
		}

		title := strings.TrimSpace(r.FormValue("title"))
		url := strings.TrimSpace(r.FormValue("url"))

		// Input Validation
		if title == "" || url == "" {
			http.Error(w, "Title and URL are required", http.StatusBadRequest)
			return
		}
		if len(title) > 100 {
			http.Error(w, "Title is too long (max 100 chars)", http.StatusBadRequest)
			return
		}
		if len(url) > 500 {
			http.Error(w, "URL is too long (max 500 chars)", http.StatusBadRequest)
			return
		}
		if !strings.HasPrefix(url, "http://") && !strings.HasPrefix(url, "https://") {
			http.Error(w, "Invalid URL format (must start with http:// or https://)", http.StatusBadRequest)
			return
		}

		db, err := getDB()
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		defer db.Close()

		domain := extractDomain(url)

		_, err = db.Exec(`
			INSERT INTO posts (title, url, full_url, score, user_id, created_at)
			VALUES (?, ?, ?, 1, ?, datetime('now'))
		`, title, domain, url, user.ID)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		http.Redirect(w, r, "/", http.StatusSeeOther)
		return
	}

	http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
}

func indexHandler(w http.ResponseWriter, r *http.Request) {
	if r.URL.Path != "/" {
		http.NotFound(w, r)
		return
	}
	db, err := getDB()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer db.Close()

	rows, err := db.Query(`
		SELECT p.id, p.title, p.url, p.score, p.created_at, u.username, p.full_url
		FROM posts p
		JOIN users u ON p.user_id = u.id
		ORDER BY p.score DESC
	`)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var posts []Post
	for rows.Next() {
		var p Post
		var url, fullURL sql.NullString
		if err := rows.Scan(&p.ID, &p.Title, &url, &p.Score, &p.CreatedAt, &p.Username, &fullURL); err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		if url.Valid {
			p.URL = url.String
		}
		if fullURL.Valid {
			p.FullURL = fullURL.String
		}
		posts = append(posts, p)
	}

	funcMap := template.FuncMap{
		"getDomain": func(rawURL string) string {
			if rawURL == "" {
				return ""
			}
			parts := strings.Split(rawURL, "//")
			if len(parts) > 1 {
				domain := strings.Split(parts[1], "/")[0]
				return domain
			}
			return rawURL
		},
	}

	tmpl, err := template.New("index.html").Funcs(funcMap).ParseFiles("templates/index.html")
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	token := generateCSRFToken()
	http.SetCookie(w, &http.Cookie{
		Name:     "csrf_token",
		Value:    token,
		Path:     "/", HttpOnly: true, SameSite: http.SameSiteLaxMode, MaxAge: 3600,
	})

	user, _ := getCurrentUser(r)

	data := struct {
		Posts     []Post
		User      *User
		CSRFToken string
	}{
		Posts:     posts,
		User:      user,
		CSRFToken: token,
	}

	if err := tmpl.Execute(w, data); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
}

func getDB() (*sql.DB, error) {
	return sql.Open("sqlite", DB_NAME)
}
