package inventory

import (
	"fmt"
	"math/rand"
	"time"
)

type InventoryRequest struct {
	Items []Item
}

type Item struct {
	ID     int
	Number int
}

type InventoryManager struct {
	requests chan InventoryRequest
	random   *rand.Rand
}

func New(capacity int) chan InventoryRequest {
	requests := make(chan InventoryRequest, capacity)

	s1 := rand.NewSource(time.Now().UnixNano())
	r1 := rand.New(s1)

	inventorym := InventoryManager{
		requests: requests,
		random:   r1,
	}

	go inventorym.start()
	return requests
}

func (inventorym InventoryManager) start() {
	for request := range inventorym.requests {
		tm, _ := time.ParseDuration(fmt.Sprintf("%vs", inventorym.random.Int31n(10)))
		time.Sleep(tm)
		fmt.Println(request)
	}
}
