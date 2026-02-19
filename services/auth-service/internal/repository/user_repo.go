package repository

import (
	"context"
	"fmt"

	"github.com/dogpay/auth-service/internal/models"
	"github.com/jackc/pgx/v5/pgxpool"
)

type UserRepository struct {
	db *pgxpool.Pool
}

func NewUserRepository(db *pgxpool.Pool) *UserRepository {
	return &UserRepository{db: db}
}

func (r *UserRepository) Create(ctx context.Context, email, passwordHash, name string) (*models.User, error) {
	user := &models.User{}
	err := r.db.QueryRow(ctx, `
		INSERT INTO auth.users (email, password_hash, name)
		VALUES ($1, $2, $3)
		RETURNING id, email, password_hash, name, created_at, updated_at
	`, email, passwordHash, name).Scan(
		&user.ID, &user.Email, &user.PasswordHash, &user.Name, &user.CreatedAt, &user.UpdatedAt,
	)
	if err != nil {
		return nil, fmt.Errorf("create user: %w", err)
	}
	return user, nil
}

func (r *UserRepository) FindByEmail(ctx context.Context, email string) (*models.User, error) {
	user := &models.User{}
	err := r.db.QueryRow(ctx, `
		SELECT id, email, password_hash, name, created_at, updated_at
		FROM auth.users
		WHERE email = $1
	`, email).Scan(
		&user.ID, &user.Email, &user.PasswordHash, &user.Name, &user.CreatedAt, &user.UpdatedAt,
	)
	if err != nil {
		return nil, fmt.Errorf("find user by email: %w", err)
	}
	return user, nil
}

func (r *UserRepository) FindByID(ctx context.Context, id string) (*models.User, error) {
	user := &models.User{}
	err := r.db.QueryRow(ctx, `
		SELECT id, email, password_hash, name, created_at, updated_at
		FROM auth.users
		WHERE id = $1
	`, id).Scan(
		&user.ID, &user.Email, &user.PasswordHash, &user.Name, &user.CreatedAt, &user.UpdatedAt,
	)
	if err != nil {
		return nil, fmt.Errorf("find user by id: %w", err)
	}
	return user, nil
}

func (r *UserRepository) StoreRefreshToken(ctx context.Context, userID, tokenHash string, expiresAt interface{}) error {
	_, err := r.db.Exec(ctx, `
		INSERT INTO auth.refresh_tokens (user_id, token_hash, expires_at)
		VALUES ($1, $2, $3)
	`, userID, tokenHash, expiresAt)
	if err != nil {
		return fmt.Errorf("store refresh token: %w", err)
	}
	return nil
}

func (r *UserRepository) FindRefreshToken(ctx context.Context, tokenHash string) (string, error) {
	var userID string
	err := r.db.QueryRow(ctx, `
		SELECT user_id FROM auth.refresh_tokens
		WHERE token_hash = $1 AND expires_at > NOW()
	`, tokenHash).Scan(&userID)
	if err != nil {
		return "", fmt.Errorf("find refresh token: %w", err)
	}
	return userID, nil
}

func (r *UserRepository) DeleteRefreshToken(ctx context.Context, tokenHash string) error {
	_, err := r.db.Exec(ctx, `
		DELETE FROM auth.refresh_tokens WHERE token_hash = $1
	`, tokenHash)
	return err
}
