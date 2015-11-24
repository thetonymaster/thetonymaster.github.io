package paymentprocessor

import (
	"fmt"
	"math/rand"
	"time"
)

type Payment struct {
	ID          string
	PaymentType string
	Amount      int
}

type PaymentProcessor struct {
	payments chan Payment
	random   *rand.Rand
}

func New(capacity int) chan Payment {
	payments := make(chan Payment, capacity)

	s1 := rand.NewSource(time.Now().UnixNano())
	r1 := rand.New(s1)

	paymentsp := PaymentProcessor{
		payments: payments,
		random:   r1,
	}

	go paymentsp.start()
	return payments
}

func (paymentsp PaymentProcessor) start() {
	for payment := range paymentsp.payments {
		tm, _ := time.ParseDuration(fmt.Sprintf("%vs", paymentsp.random.Int31n(10)))
		time.Sleep(tm)
		fmt.Println(payment)
	}
}
