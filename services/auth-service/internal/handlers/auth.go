package handlers

import (
	"crypto/sha256"
	"fmt"
	"net/http"
	"os"
	"strings"
	"time"

	"github.com/dogpay/auth-service/internal/middleware"
	"github.com/dogpay/auth-service/internal/models"
	"github.com/dogpay/auth-service/internal/repository"
	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"golang.org/x/crypto/bcrypt"
)

type AuthHandler struct {
	repo      *repository.UserRepository
	jwtSecret string
}

func NewAuthHandler(repo *repository.UserRepository, jwtSecret string) *AuthHandler {
	return &AuthHandler{repo: repo, jwtSecret: jwtSecret}
}

func (h *AuthHandler) Register(c *gin.Context) {
	var req models.RegisterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	hash, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to hash password"})
		return
	}

	user, err := h.repo.Create(c.Request.Context(), req.Email, string(hash), req.Name)
	if err != nil {
		c.JSON(http.StatusConflict, gin.H{"error": "email already registered"})
		return
	}

	// Notify payment service to create account
	go notifyPaymentService(user.ID)

	accessToken, refreshToken, err := h.generateTokens(user)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to generate tokens"})
		return
	}

	if err := h.storeRefreshToken(c, user.ID, refreshToken); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to store refresh token"})
		return
	}

	c.JSON(http.StatusCreated, models.AuthResponse{
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
		User:         user,
	})
}

func (h *AuthHandler) Login(c *gin.Context) {
	var req models.LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	user, err := h.repo.FindByEmail(c.Request.Context(), req.Email)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid credentials"})
		return
	}

	if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(req.Password)); err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid credentials"})
		return
	}

	accessToken, refreshToken, err := h.generateTokens(user)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to generate tokens"})
		return
	}

	if err := h.storeRefreshToken(c, user.ID, refreshToken); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to store refresh token"})
		return
	}

	c.JSON(http.StatusOK, models.AuthResponse{
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
		User:         user,
	})
}

func (h *AuthHandler) Me(c *gin.Context) {
	userID := c.GetString("user_id")
	user, err := h.repo.FindByID(c.Request.Context(), userID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "user not found"})
		return
	}
	c.JSON(http.StatusOK, user)
}

func (h *AuthHandler) Refresh(c *gin.Context) {
	var req models.RefreshRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	tokenHash := hashToken(req.RefreshToken)
	userID, err := h.repo.FindRefreshToken(c.Request.Context(), tokenHash)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid or expired refresh token"})
		return
	}

	user, err := h.repo.FindByID(c.Request.Context(), userID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "user not found"})
		return
	}

	_ = h.repo.DeleteRefreshToken(c.Request.Context(), tokenHash)

	accessToken, refreshToken, err := h.generateTokens(user)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to generate tokens"})
		return
	}

	if err := h.storeRefreshToken(c, user.ID, refreshToken); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to store refresh token"})
		return
	}

	c.JSON(http.StatusOK, models.AuthResponse{
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
		User:         user,
	})
}

func (h *AuthHandler) generateTokens(user *models.User) (string, string, error) {
	accessExpiry := 15 * time.Minute
	refreshExpiry := 7 * 24 * time.Hour

	accessClaims := &middleware.Claims{
		UserID: user.ID,
		Email:  user.Email,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(accessExpiry)),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
			Subject:   user.ID,
		},
	}

	accessToken, err := jwt.NewWithClaims(jwt.SigningMethodHS256, accessClaims).SignedString([]byte(h.jwtSecret))
	if err != nil {
		return "", "", err
	}

	refreshClaims := &middleware.Claims{
		UserID: user.ID,
		Email:  user.Email,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(refreshExpiry)),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
			Subject:   user.ID,
		},
	}

	refreshToken, err := jwt.NewWithClaims(jwt.SigningMethodHS256, refreshClaims).SignedString([]byte(h.jwtSecret))
	if err != nil {
		return "", "", err
	}

	return accessToken, refreshToken, nil
}

func (h *AuthHandler) storeRefreshToken(c *gin.Context, userID, refreshToken string) error {
	tokenHash := hashToken(refreshToken)
	expiresAt := time.Now().Add(7 * 24 * time.Hour)
	return h.repo.StoreRefreshToken(c.Request.Context(), userID, tokenHash, expiresAt)
}

func hashToken(token string) string {
	h := sha256.New()
	h.Write([]byte(token))
	return fmt.Sprintf("%x", h.Sum(nil))
}

func notifyPaymentService(userID string) {
	paymentURL := os.Getenv("PAYMENT_SERVICE_URL")
	if paymentURL == "" {
		paymentURL = "http://payment-service:8002"
	}

	body := fmt.Sprintf(`{"user_id":"%s"}`, userID)

	// Simple HTTP call to payment service to create account
	// Retry a few times to handle startup race conditions
	for i := 0; i < 5; i++ {
		time.Sleep(time.Duration(i+1) * time.Second)
		resp, err := http.Post(
			paymentURL+"/internal/accounts",
			"application/json",
			strings.NewReader(body),
		)
		if err != nil {
			continue
		}
		resp.Body.Close()
		if resp.StatusCode == http.StatusCreated || resp.StatusCode == http.StatusOK {
			return
		}
	}
}
