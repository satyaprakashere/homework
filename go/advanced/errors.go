package main

import (
	"errors"
	"fmt"
)

// AppError is a custom error type that wraps an underlying error with more context.
type AppError struct {
	Code    int
	Message string
	Err     error
}

func (e *AppError) Error() string {
	return fmt.Sprintf("Error %d: %s (Original: %v)", e.Code, e.Message, e.Err)
}

// Unwrap allows the error to be used with errors.Is and errors.As.
func (e *AppError) Unwrap() error {
	return e.Err
}

func doSomethingRisky() error {
	return &AppError{
		Code:    404,
		Message: "Resource Not Found",
		Err:     errors.New("db record missing"),
	}
}

func RunErrorDemo() {
	fmt.Println("\n--- 7. Custom Errors Demo ---")
	
	err := doSomethingRisky()
	if err != nil {
		fmt.Println("Caught an error:", err)

		// Check if it's our custom AppError type
		var appErr *AppError
		if errors.As(err, &appErr) {
			fmt.Printf("Custom metadata -> Code: %d, Message: %s\n", appErr.Code, appErr.Message)
		}

		// Check for underlying error
		if errors.Is(err, errors.New("db record missing")) {
			// Note: errors.Is usually compares against a sentinel variable
		}
	}
}
