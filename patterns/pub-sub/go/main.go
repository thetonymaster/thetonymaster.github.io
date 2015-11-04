package main

import (
	"fmt"
	"time"

	"github.com/thetonymaster/pub-sub/go/pubsub"
)

func main() {
	ps := pubsub.New(10)

	topicA := ps.Sub("TopicA")
	topicA2 := ps.Sub("TopicA")
	topicB := ps.Sub("TopicB")

	go topic(topicA, "TopicA")
	go topic(topicA2, "TopicA2")
	go topic(topicB, "TopicB")

	ps.Pub("Hello", "TopicB")
	ps.Pub("Bye", "TopicA")

	time.Sleep(1 * time.Second)
}

func topic(ch chan interface{}, title string) {
	message := <-ch
	fmt.Printf("From %s, %s\n", title, message)

}
