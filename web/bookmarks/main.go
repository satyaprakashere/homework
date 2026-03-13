package main

import (
	"database/sql"
	"fmt"
	"html/template"
	"log"
	"net/http"
	"strings"

	_ "modernc.org/sqlite"
)

type Post struct {
	ID        int
	Title     string
	URL       string
	Score     int
	CreatedAt string
	Username  string
}

func getDB() (*sql.DB, error) {
	return sql.Open("sqlite", "news.db")
}

func indexHandler(w http.ResponseWriter, r *http.Request) {
	db, err := getDB()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer db.Close()

	rows, err := db.Query(`
		SELECT p.id, p.title, p.url, p.score, p.created_at, u.username
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
		var url sql.NullString
		if err := rows.Scan(&p.ID, &p.Title, &url, &p.Score, &p.CreatedAt, &p.Username); err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		if url.Valid {
			p.URL = url.String
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

	data := struct {
		Posts []Post
	}{
		Posts: posts,
	}

	if err := tmpl.Execute(w, data); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
}

func main() {
	http.Handle("/static/", http.StripPrefix("/static/", http.FileServer(http.Dir("static"))))
	http.HandleFunc("/", indexHandler)

	fmt.Println("Server starting on http://localhost:8080")
	log.Fatal(http.ListenAndServe(":8080", nil))
}
