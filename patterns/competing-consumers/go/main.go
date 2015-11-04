package main

import (
	"fmt"
	"math/rand"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/thetonymaster/competing-consumers/go/collector"
	"github.com/thetonymaster/competing-consumers/go/dispatcher"
)

func main() {

	sigs := make(chan os.Signal, 1)
	done := make(chan bool, 1)
	signal.Notify(sigs, syscall.SIGINT, syscall.SIGTERM)

	s1 := rand.NewSource(time.Now().UnixNano())
	r1 := rand.New(s1)

	go func() {
		sig := <-sigs
		fmt.Println()
		fmt.Println(sig)
		done <- true
	}()

	dispatcher.StartDispatcher(3)
	for i := 0; i < 10; i++ {
		collector.Collector("", r1.Intn(10))
	}
	fmt.Println("awaiting signal")
	<-done
	fmt.Println("exiting")
}
