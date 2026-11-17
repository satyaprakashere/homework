//go:build ignore

package main

import (
	"fmt"
	"time"
)

/*
================================================================================
SYSTEM DESIGN INTERVIEW (SD3): DISTRIBUTED TRANSACTIONS (2PC vs SAGA PATTERN)
================================================================================
Key Topics Covered:
1. ACID Properties in Monoliths vs Distributed Microservices.
2. Two-Phase Commit (2PC) Protocol:
   - Phase 1 (Prepare): Coordinator broadcasts PREPARE. Participants lock resources and vote YES/NO.
   - Phase 2 (Commit/Abort): Coordinator broadcasts COMMIT if all voted YES; else ABORT.
   - 2PC Fatal Flaws: Synchronous blocking, coordinator single point of failure (SPOF),
     holds distributed locks across network boundaries reducing throughput to a crawl.
3. The Saga Pattern (Eventual Consistency & Compensating Actions):
   - Sequence of local transactions coordinated via Orchestrator or Choreography (Events).
   - If Step N fails, execute Compensating Transactions for Step N-1 down to Step 1 in reverse!
   - Non-blocking: No global locks held.
================================================================================
*/

// Participant represents an independent microservice database
type Participant struct {
	Name         string
	PreparedLock bool
	Committed    bool
	WillFail     bool
}

func (p *Participant) Prepare() bool {
	if p.WillFail {
		fmt.Printf("  [%s] Vote: NO (Resource unavailable/constraint failed)\n", p.Name)
		return false
	}
	p.PreparedLock = true
	fmt.Printf("  [%s] Vote: YES (Local resource locked & WAL written)\n", p.Name)
	return true
}

func (p *Participant) Commit() {
	p.Committed = true
	p.PreparedLock = false
	fmt.Printf("  [%s] State: COMMITTED (Locks released)\n", p.Name)
}

func (p *Participant) Rollback() {
	p.Committed = false
	p.PreparedLock = false
	fmt.Printf("  [%s] State: ROLLED BACK (Locks released)\n", p.Name)
}

// TwoPhaseCoordinator manages 2PC protocol
type TwoPhaseCoordinator struct {
	participants []*Participant
}

func (c *TwoPhaseCoordinator) ExecuteTransaction() bool {
	fmt.Println("  --- Phase 1: PREPARE (Voting Phase) ---")
	allYes := true
	for _, p := range c.participants {
		if !p.Prepare() {
			allYes = false
		}
	}

	fmt.Println("\n  --- Phase 2: COMMIT / ABORT (Decision Phase) ---")
	if allYes {
		fmt.Println("  [COORDINATOR DECISION]: All voted YES -> Sending GLOBAL COMMIT")
		for _, p := range c.participants {
			p.Commit()
		}
		return true
	}

	fmt.Println("  [COORDINATOR DECISION]: One or more voted NO -> Sending GLOBAL ROLLBACK")
	for _, p := range c.participants {
		p.Rollback()
	}
	return false
}

// -----------------------------------------------------------------------------
// SAGA PATTERN WITH COMPENSATING TRANSACTIONS
// -----------------------------------------------------------------------------

type SagaStep struct {
	Name       string
	Execute    func() error
	Compensate func()
}

type SagaOrchestrator struct {
	steps []SagaStep
}

func (s *SagaOrchestrator) Run() bool {
	var completedSteps []SagaStep

	for _, step := range s.steps {
		fmt.Printf("  [Saga Executing] %s...\n", step.Name)
		err := step.Execute()
		if err != nil {
			fmt.Printf("  [Saga FAILED at %s]: %v\n", step.Name, err)
			fmt.Println("  >>> Initiating Compensating Transactions in REVERSE order <<<")
			// Roll back previously completed steps
			for i := len(completedSteps) - 1; i >= 0; i-- {
				fmt.Printf("  [Saga Compensating] Undoing: %s...\n", completedSteps[i].Name)
				completedSteps[i].Compensate()
			}
			return false
		}
		completedSteps = append(completedSteps, step)
	}

	fmt.Println("  [Saga SUCCESS]: All distributed steps completed successfully!")
	return true
}

func main() {
	fmt.Println("=== SD3 Distributed Transactions: Two-Phase Commit (2PC) vs Saga Pattern ===")

	// 1. Two-Phase Commit Success
	fmt.Println("\n[1] 2PC Happy Path (Order DB + Inventory DB + Payment DB):")
	p1 := &Participant{Name: "OrderService-DB"}
	p2 := &Participant{Name: "InventoryService-DB"}
	p3 := &Participant{Name: "PaymentService-DB"}

	coord := &TwoPhaseCoordinator{participants: []*Participant{p1, p2, p3}}
	coord.ExecuteTransaction()

	// 2. Two-Phase Commit Abort (Inventory Out of Stock)
	fmt.Println("\n[2] 2PC Abort Scenario (Inventory Service Out of Stock):")
	p1 = &Participant{Name: "OrderService-DB"}
	p2 = &Participant{Name: "InventoryService-DB", WillFail: true}
	p3 = &Participant{Name: "PaymentService-DB"}

	coordFail := &TwoPhaseCoordinator{participants: []*Participant{p1, p2, p3}}
	coordFail.ExecuteTransaction()

	// 3. Saga Pattern Demonstration (Compensating Transactions)
	fmt.Println("\n[3] Saga Pattern: Order Placement with Payment Failure & Compensation:")
	orchestrator := &SagaOrchestrator{
		steps: []SagaStep{
			{
				Name: "Reserve Order (Order Service)",
				Execute: func() error {
					time.Sleep(5 * time.Millisecond)
					return nil
				},
				Compensate: func() {
					fmt.Println("    -> Order marked CANCELLED")
				},
			},
			{
				Name: "Deduct Inventory (Inventory Service)",
				Execute: func() error {
					time.Sleep(5 * time.Millisecond)
					return nil
				},
				Compensate: func() {
					fmt.Println("    -> Inventory items RESTORED (+1 stock)")
				},
			},
			{
				Name: "Charge Credit Card (Payment Service)",
				Execute: func() error {
					// Simulate Payment Gateway Decline
					return fmt.Errorf("insufficient funds / card declined")
				},
				Compensate: func() {
					// Step that failed does not need compensation
				},
			},
		},
	}

	orchestrator.Run()

	fmt.Println("\n[SD3 Takeaway]: 2PC provides strict ACID consistency but suffers synchronous lock blocking; Sagas provide eventual consistency via compensating actions.")
}
