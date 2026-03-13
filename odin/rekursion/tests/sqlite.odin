package tests

import sqlite "../sqlite"

import "core:fmt"
import "core:os"
import "core:testing"

@(test)
test_sqlite :: proc(t: ^testing.T) {
	// Ensure directory exists
	os.make_directory("tests/db")
	db, status := sqlite.open(DB_FILE); if status != nil {
		fmt.eprintf(
			"Unable to open database '%s'(%v): %s\n",
			DB_FILE,
			status,
			sqlite.status_explain(status),
		)
		os.exit(1)
	}
	defer sqlite.close(db)

	sqlite.sql_exec(
		db,
		`
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY
            , name VARCHAR(64) NOT NULL
            , flag INTEGER NOT NULL
        );
    `,
	)
	sqlite.sql_exec(
		db,
		`
        INSERT INTO users (name, flag) VALUES
            ('john', 1)
            , ('mary', 0)
            , ('alice', 1)
            , ('bob', 0);
    `,
	)
	query, _ := sqlite.sql_bind(
		db,
		`
        SELECT
            name
            , flag
        FROM users
        WHERE flag = ?1;
    `,
		false,
	)
	count := 0
	for row in sqlite.sql_row(db, query, struct {
			name: string,
			ok:   bool,
		}) {
		count += 1
	}
	testing.expect(t, count > 0, "Expected at least one row from SQLite query")
	sqlite.sql_exec(db, "DROP TABLE users;")
}
