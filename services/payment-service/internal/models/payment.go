package models

import "time"

type Account struct {
	ID        string    `json:"id" db:"id"`
	UserID    string    `json:"user_id" db:"user_id"`
	Balance   float64   `json:"balance" db:"balance"`
	CreatedAt time.Time `json:"created_at" db:"created_at"`
	UpdatedAt time.Time `json:"updated_at" db:"updated_at"`
}

type Transaction struct {
	ID              string     `json:"id" db:"id"`
	FromAccountID   *string    `json:"from_account_id" db:"from_account_id"`
	ToAccountID     string     `json:"to_account_id" db:"to_account_id"`
	Amount          float64    `json:"amount" db:"amount"`
	Status          string     `json:"status" db:"status"`
	Description     *string    `json:"description" db:"description"`
	ErrorMessage    *string    `json:"error_message,omitempty" db:"error_message"`
	CreatedAt       time.Time  `json:"created_at" db:"created_at"`
	UpdatedAt       time.Time  `json:"updated_at" db:"updated_at"`
}

type TransferRequest struct {
	ToEmail     string  `json:"to_email" binding:"required,email"`
	Amount      float64 `json:"amount" binding:"required,gt=0"`
	Description string  `json:"description"`
}

type TransferMessage struct {
	TransactionID   string  `json:"transaction_id"`
	FromAccountID   string  `json:"from_account_id"`
	ToAccountID     string  `json:"to_account_id"`
	Amount          float64 `json:"amount"`
}

type CreateAccountRequest struct {
	UserID string `json:"user_id" binding:"required"`
}
