//go:build ignore

package main

import (
	"fmt"
)

/*
================================================================================
SYSTEM DESIGN INTERVIEW (SD3): DATABASE NORMALIZATION (1NF, 2NF, 3NF, BCNF)
================================================================================
Key Topics Covered:
1. The Core Purpose of Relational Normalization:
   - Eliminates Data Redundancy.
   - Prevents the 3 Classical Relational Anomalies:
     * Insertion Anomaly: Cannot insert a department without an employee assigned.
     * Deletion Anomaly: Deleting the last employee accidentally deletes the department data!
     * Update Anomaly: Updating department name in 10,000 employee rows; inconsistent if 1 fails.
2. The Normal Forms:
   - 1NF: Atomic attributes (no repeated arrays/lists) + Primary Key.
   - 2NF: 1NF + No Partial Functional Dependencies (non-prime attributes depend on the WHOLE primary key).
   - 3NF: 2NF + No Transitive Dependencies (non-prime attributes must NOT depend on other non-prime attributes).
     Mnemonic: "Each attribute must depend on the key, the whole key, and nothing but the key, so help me Codd."
   - BCNF: Every determinant must be a candidate key.
================================================================================
*/

// UnnormalizedRecord suffers from repeated data and modification anomalies
type UnnormalizedRecord struct {
	EmpID          int
	EmpName        string
	DeptID         int
	DeptName       string // Redundant! Transitive dependency: EmpID -> DeptID -> DeptName
	DeptHead       string // Redundant!
	Skills         string // Violates 1NF: comma-separated list "Go,SQL,Docker"
}

// -----------------------------------------------------------------------------
// NORMALIZED 3NF SCHEMA
// -----------------------------------------------------------------------------

// Table 1: Departments (Eliminates Transitive Dependency)
type Department struct {
	DeptID   int
	DeptName string
	DeptHead string
}

// Table 2: Employees (Depends strictly on Primary Key EmpID)
type Employee struct {
	EmpID    int
	EmpName  string
	DeptID   int // Foreign Key to Department
}

// Table 3: EmployeeSkills (Eliminates repeated groups to satisfy 1NF)
type EmployeeSkill struct {
	EmpID int
	Skill string
}

func main() {
	fmt.Println("=== SD3 Database Normalization: 1NF, 2NF, 3NF & Anomaly Prevention ===")

	// 1. Anomaly Demonstration in Unnormalized Schema
	fmt.Println("\n[1] The 3 Relational Anomalies in Unnormalized Data:")
	unnormalizedData := []UnnormalizedRecord{
		{EmpID: 1, EmpName: "Alice", DeptID: 10, DeptName: "Engineering", DeptHead: "Bob", Skills: "Go,Docker"},
		{EmpID: 2, EmpName: "Charlie", DeptID: 10, DeptName: "Engineering", DeptHead: "Bob", Skills: "Kubernetes"},
	}
	fmt.Printf("  Inspecting %d unnormalized records with denormalized DeptHead repeated.\n", len(unnormalizedData))

	fmt.Println("  Update Anomaly Risk:")
	fmt.Println("    If Engineering's DeptHead changes from 'Bob' to 'Eve', all 50,000 employee rows")
	fmt.Println("    must be updated. If the query aborts midway, the database is corrupted with split data!")

	fmt.Println("  Deletion Anomaly Risk:")
	fmt.Println("    If Charlie leaves, and Charlie was the only one in a new 'Quantum Computing' department,")
	fmt.Println("    deleting Charlie's row erases all evidence that the Quantum department ever existed!")

	// 2. Normalized 3NF Architecture
	fmt.Println("\n[2] Decomposed 3NF Architecture (Key, Whole Key, Nothing but the Key):")
	departments := map[int]Department{
		10: {DeptID: 10, DeptName: "Engineering", DeptHead: "Eve"},
	}
	employees := []Employee{
		{EmpID: 1, EmpName: "Alice", DeptID: 10},
		{EmpID: 2, EmpName: "Charlie", DeptID: 10},
	}
	skills := []EmployeeSkill{
		{EmpID: 1, Skill: "Go"},
		{EmpID: 1, Skill: "Docker"},
		{EmpID: 2, Skill: "Kubernetes"},
	}

	fmt.Printf("  Departments Table (Count: %d) -> DeptName stored ONCE!\n", len(departments))
	fmt.Printf("  Employees Table   (Count: %d) -> References DeptID cleanly.\n", len(employees))
	fmt.Printf("  Skills 1NF Table  (Count: %d) -> Atomic single-value rows.\n", len(skills))

	fmt.Println("\n[SD3 Takeaway]: 3NF guarantees zero update anomalies and optimal write integrity; at internet scale, selective denormalization is applied to relieve join bottlenecks.")
}
