package main

import "fmt"

// DataStore is an interface that decouples the service from the DB implementation.
type DataStore interface {
	Save(id string, val any) error
}

type MyService struct {
	db DataStore
}

func (s *MyService) Process(id string, val any) {
	fmt.Printf("Service processing data for %s...\n", id)
	_ = s.db.Save(id, val)
}

// PostgresDB is a concrete implementation of DataStore.
type PostgresDB struct{}

func (p *PostgresDB) Save(id string, val any) error {
	fmt.Printf("[Postgres] Successfully saved %s\n", id)
	return nil
}

// MockDB is another implementation for testing purposes.
type MockDB struct{}

func (m *MockDB) Save(id string, val any) error {
	fmt.Printf("[Mock] Simulated save for %s\n", id)
	return nil
}

func RunDIDemo() {
	fmt.Println("\n--- 5. Dependency Injection Demo ---")

	// Inject PostgresDB
	service := &MyService{db: &PostgresDB{}}
	service.Process("user_123", "Alice")

	// Inject MockDB (easily swap implementations)
	testService := &MyService{db: &MockDB{}}
	testService.Process("test_1", "Secret")
}
