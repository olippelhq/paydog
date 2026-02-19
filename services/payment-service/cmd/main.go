package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"os"

	"github.com/dogpay/payment-service/internal/handlers"
	"github.com/dogpay/payment-service/internal/middleware"
	"github.com/dogpay/payment-service/internal/models"
	"github.com/dogpay/payment-service/internal/queue"
	"github.com/dogpay/payment-service/internal/repository"
	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5/pgxpool"
)

func main() {
	// Database connection (cross-schema: can access auth schema too)
	dbURL := fmt.Sprintf(
		"postgres://%s:%s@%s:%s/%s",
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

	// RabbitMQ connection
	rabbitURL := fmt.Sprintf(
		"amqp://%s:%s@%s:%s%s",
		getEnv("RABBITMQ_USER", "dogpay"),
		getEnv("RABBITMQ_PASSWORD", "dogpay_secret"),
		getEnv("RABBITMQ_HOST", "localhost"),
		getEnv("RABBITMQ_PORT", "5672"),
		getEnv("RABBITMQ_VHOST", "/"),
	)

	mq, err := queue.NewRabbitMQ(rabbitURL)
	if err != nil {
		log.Fatalf("failed to connect to RabbitMQ: %v", err)
	}
	defer mq.Close()
	log.Println("Connected to RabbitMQ")

	jwtSecret := getEnv("PAYMENT_JWT_SECRET", "dev-secret")

	// Setup dependencies
	paymentRepo := repository.NewPaymentRepository(db)
	paymentHandler := handlers.NewPaymentHandler(paymentRepo, mq)

	// Start queue consumer
	go startConsumer(mq, paymentRepo)

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
		c.JSON(200, gin.H{"status": "ok", "service": "payment-service"})
	})

	// Internal endpoint (called by auth service)
	r.POST("/internal/accounts", paymentHandler.CreateAccount)

	payments := r.Group("/payments", middleware.JWTAuth(jwtSecret))
	{
		payments.GET("/balance", paymentHandler.GetBalance)
		payments.POST("/transfer", paymentHandler.Transfer)
		payments.GET("/history", paymentHandler.GetHistory)
	}

	port := getEnv("PAYMENT_PORT", "8002")
	log.Printf("Payment service starting on :%s", port)
	if err := r.Run(":" + port); err != nil {
		log.Fatalf("server error: %v", err)
	}
}

func startConsumer(mq *queue.RabbitMQ, repo *repository.PaymentRepository) {
	deliveries, err := mq.ConsumeTransfers()
	if err != nil {
		log.Fatalf("failed to start consumer: %v", err)
	}

	log.Println("Queue consumer started, waiting for messages...")

	for d := range deliveries {
		var msg models.TransferMessage
		if err := json.Unmarshal(d.Body, &msg); err != nil {
			log.Printf("failed to unmarshal message: %v", err)
			d.Nack(false, false) // send to DLQ
			continue
		}

		log.Printf("Processing transfer: %s (%.2f)", msg.TransactionID, msg.Amount)

		err := repo.ProcessTransfer(
			context.Background(),
			msg.TransactionID,
			msg.FromAccountID,
			msg.ToAccountID,
			msg.Amount,
		)

		if err != nil {
			log.Printf("transfer failed: %v", err)
			d.Nack(false, false) // send to DLQ
		} else {
			log.Printf("Transfer completed: %s", msg.TransactionID)
			d.Ack(false)
		}
	}
}

func getEnv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}
