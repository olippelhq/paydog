package queue

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"time"

	"github.com/dogpay/payment-service/internal/models"
	amqp "github.com/rabbitmq/amqp091-go"
)

const (
	TransferQueue = "transfers"
	DeadLetterQueue = "transfers.dlq"
)

type RabbitMQ struct {
	conn    *amqp.Connection
	channel *amqp.Channel
}

func NewRabbitMQ(url string) (*RabbitMQ, error) {
	var conn *amqp.Connection
	var err error

	// Retry connection (RabbitMQ may not be ready immediately)
	for i := 0; i < 10; i++ {
		conn, err = amqp.Dial(url)
		if err == nil {
			break
		}
		log.Printf("RabbitMQ not ready, retrying in %ds... (%v)", i+1, err)
		time.Sleep(time.Duration(i+1) * time.Second)
	}
	if err != nil {
		return nil, fmt.Errorf("connect to RabbitMQ: %w", err)
	}

	ch, err := conn.Channel()
	if err != nil {
		conn.Close()
		return nil, fmt.Errorf("open channel: %w", err)
	}

	rmq := &RabbitMQ{conn: conn, channel: ch}
	if err := rmq.setup(); err != nil {
		return nil, err
	}

	return rmq, nil
}

func (r *RabbitMQ) setup() error {
	// Declare dead letter queue
	_, err := r.channel.QueueDeclare(
		DeadLetterQueue,
		true,  // durable
		false, // auto-delete
		false, // exclusive
		false, // no-wait
		nil,
	)
	if err != nil {
		return fmt.Errorf("declare DLQ: %w", err)
	}

	// Declare main queue with DLQ
	args := amqp.Table{
		"x-dead-letter-exchange":    "",
		"x-dead-letter-routing-key": DeadLetterQueue,
		"x-max-retries":             3,
	}
	_, err = r.channel.QueueDeclare(
		TransferQueue,
		true,
		false,
		false,
		false,
		args,
	)
	if err != nil {
		return fmt.Errorf("declare transfer queue: %w", err)
	}

	return nil
}

func (r *RabbitMQ) PublishTransfer(ctx context.Context, msg models.TransferMessage) error {
	body, err := json.Marshal(msg)
	if err != nil {
		return fmt.Errorf("marshal message: %w", err)
	}

	return r.channel.PublishWithContext(ctx,
		"",            // exchange
		TransferQueue, // routing key
		false,         // mandatory
		false,         // immediate
		amqp.Publishing{
			ContentType:  "application/json",
			Body:         body,
			DeliveryMode: amqp.Persistent,
		},
	)
}

func (r *RabbitMQ) ConsumeTransfers() (<-chan amqp.Delivery, error) {
	return r.channel.Consume(
		TransferQueue,
		"payment-service-consumer",
		false, // auto-ack (we'll manual ack)
		false, // exclusive
		false, // no-local
		false, // no-wait
		nil,
	)
}

func (r *RabbitMQ) Close() {
	if r.channel != nil {
		r.channel.Close()
	}
	if r.conn != nil {
		r.conn.Close()
	}
}
