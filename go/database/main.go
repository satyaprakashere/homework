package main

import (
	"database/sql"
	"fmt"
	"log"

	_ "github.com/lib/pq" // PostgreSQL driver
)

type user struct {
	id   int
	name string
	pass string
}

func main() {
	dsn := "postgres://prakash:2004@localhost:5432/postgres?sslmode=disable"

	// Open the connection
	// The driver name is "postgres"
	db, err := sql.Open("postgres", dsn)
	if err != nil {
		log.Fatal("Error opening database:", err)
	}
	defer db.Close()

	// Verify the connection
	err = db.Ping()
	if err != nil {
		log.Fatal("Error connecting to database. Make sure PostgreSQL is running and the DSN is correct.\n", err)
	}
	log.Println("Successfully connected to database")

	// Create a table if it doesn't exist
	// PostgreSQL differences:
	// - SERIAL: automatically increments (replaces AUTO_INCREMENT)
	// - TEXT or VARCHAR(n): VARCHAR is standard, but TEXT is often used in Postgres
	_, err = db.Exec(`
		CREATE TABLE IF NOT EXISTS users (
			id SERIAL PRIMARY KEY,
			name VARCHAR(50) NOT NULL,
			pass VARCHAR(255) NOT NULL
		)
	`)
	if err != nil {
		log.Fatal("Error creating table:", err)
	}
	log.Println("Table 'users' checked/created successfully")

	// Insert data
	// PostgreSQL uses $1, $2, etc. as placeholders instead of ?
	stmt, err := db.Prepare("INSERT INTO users(name, pass) VALUES ($1, $2)")
	if err != nil {
		log.Fatal("Error preparing insert statement:", err)
	}
	defer stmt.Close()

	_, err = stmt.Exec("alice", "pass123")
	if err != nil {
		log.Fatal("Error inserting user:", err)
	}
	log.Println("Inserted user alice")

	_, err = stmt.Exec("bob", "securepass")
	if err != nil {
		log.Fatal("Error inserting user:", err)
	}
	log.Println("Inserted user bob")

	// Query and display data
	rows, err := db.Query("SELECT id, name, pass FROM users")
	if err != nil {
		log.Fatal("Error querying users:", err)
	}
	defer rows.Close()

	fmt.Println("\n--- All Users ---")
	for rows.Next() {
		var u user
		if err := rows.Scan(&u.id, &u.name, &u.pass); err != nil {
			log.Fatal(err)
		}
		log.Printf("ID: %d, Name: %s, Pass: %s\n", u.id, u.name, u.pass)
	}

	// Check for errors during iteration
	if err = rows.Err(); err != nil {
		log.Fatal(err)
	}
}
