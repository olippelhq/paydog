package main

import (
	"context"
	"fmt"
	"log"
	"os"

	"github.com/dogpay/auth-service/internal/handlers"
	"github.com/dogpay/auth-service/internal/middleware"
	"github.com/dogpay/auth-service/internal/repository"
	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5/pgxpool"
)

func main() {
	// Database connection
	dbURL := fmt.Sprintf(
		"postgres://%s:%s@%s:%s/%s?search_path=auth,public",
		getEnv("POSTGRES_USER", "dogpay"),
		getEnv("POSTGRES_PASSWORD", "dogpay_secret"),
		getEnv("POSTGRES_HOST", "localhost"),
		getEnv("POSTGRES_PORT", "5432"),
		getEnv("POSTGRES_DB", "dogpay"),
	)

	db, err := pgxpool.New(context.Background(), dbURL)
	if err != nil {
		log.Fatalf("failed to connect to database: %v", err)
	}
	defer db.Close()

	if err := db.Ping(context.Background()); err != nil {
		log.Fatalf("failed to ping database: %v", err)
	}
	log.Println("Connected to PostgreSQL")

	jwtSecret := getEnv("AUTH_JWT_SECRET", "dev-secret")

	// Setup dependencies
	userRepo := repository.NewUserRepository(db)
	authHandler := handlers.NewAuthHandler(userRepo, jwtSecret)

	// Gin router
	r := gin.Default()

	// CORS
	r.Use(cors.New(cors.Config{
		AllowOrigins:     []string{"http://localhost:5173", "http://localhost:80"},
		AllowMethods:     []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
		AllowHeaders:     []string{"Origin", "Content-Type", "Authorization"},
		ExposeHeaders:    []string{"Content-Length"},
		AllowCredentials: true,
	}))

	// Routes
	r.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{"status": "ok", "service": "auth-service"})
	})

	auth := r.Group("/auth")
	{
		auth.POST("/register", authHandler.Register)
		auth.POST("/login", authHandler.Login)
		auth.POST("/refresh", authHandler.Refresh)
		auth.GET("/me", middleware.JWTAuth(jwtSecret), authHandler.Me)
	}

	port := getEnv("AUTH_PORT", "8001")
	log.Printf("Auth service starting on :%s", port)
	if err := r.Run(":" + port); err != nil {
		log.Fatalf("server error: %v", err)
	}
}

func getEnv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}
