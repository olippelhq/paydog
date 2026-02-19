package handlers

import (
	"net/http"

	"github.com/dogpay/payment-service/internal/models"
	"github.com/dogpay/payment-service/internal/queue"
	"github.com/dogpay/payment-service/internal/repository"
	"github.com/gin-gonic/gin"
)

type PaymentHandler struct {
	repo *repository.PaymentRepository
	mq   *queue.RabbitMQ
}

func NewPaymentHandler(repo *repository.PaymentRepository, mq *queue.RabbitMQ) *PaymentHandler {
	return &PaymentHandler{repo: repo, mq: mq}
}

func (h *PaymentHandler) CreateAccount(c *gin.Context) {
	var req models.CreateAccountRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	account, err := h.repo.CreateAccount(c.Request.Context(), req.UserID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to create account"})
		return
	}

	c.JSON(http.StatusCreated, account)
}

func (h *PaymentHandler) GetBalance(c *gin.Context) {
	userID := c.GetString("user_id")

	account, err := h.repo.GetAccountByUserID(c.Request.Context(), userID)
	if err != nil {
		// Auto-create account if it doesn't exist
		account, err = h.repo.CreateAccount(c.Request.Context(), userID)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to get balance"})
			return
		}
	}

	c.JSON(http.StatusOK, gin.H{
		"balance":    account.Balance,
		"account_id": account.ID,
		"user_id":    account.UserID,
	})
}

func (h *PaymentHandler) Transfer(c *gin.Context) {
	userID := c.GetString("user_id")

	var req models.TransferRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Get sender account
	fromAccount, err := h.repo.GetAccountByUserID(c.Request.Context(), userID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "sender account not found"})
		return
	}

	// Get recipient account by email
	toAccount, err := h.repo.GetAccountByEmail(c.Request.Context(), req.ToEmail)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "recipient not found"})
		return
	}

	if fromAccount.ID == toAccount.ID {
		c.JSON(http.StatusBadRequest, gin.H{"error": "cannot transfer to yourself"})
		return
	}

	// Create pending transaction
	tx, err := h.repo.CreatePendingTransaction(
		c.Request.Context(),
		fromAccount.ID,
		toAccount.ID,
		req.Amount,
		req.Description,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to create transaction"})
		return
	}

	// Publish to RabbitMQ
	msg := models.TransferMessage{
		TransactionID: tx.ID,
		FromAccountID: fromAccount.ID,
		ToAccountID:   toAccount.ID,
		Amount:        req.Amount,
	}

	if err := h.mq.PublishTransfer(c.Request.Context(), msg); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to queue transfer"})
		return
	}

	c.JSON(http.StatusAccepted, gin.H{
		"message":        "transfer queued",
		"transaction_id": tx.ID,
		"status":         "pending",
	})
}

func (h *PaymentHandler) GetHistory(c *gin.Context) {
	userID := c.GetString("user_id")

	account, err := h.repo.GetAccountByUserID(c.Request.Context(), userID)
	if err != nil {
		c.JSON(http.StatusOK, gin.H{"transactions": []interface{}{}})
		return
	}

	txs, err := h.repo.GetTransactionHistory(c.Request.Context(), account.ID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to get history"})
		return
	}

	if txs == nil {
		txs = []models.Transaction{}
	}

	c.JSON(http.StatusOK, gin.H{"transactions": txs})
}
