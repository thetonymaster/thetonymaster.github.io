package work

import (
	"fmt"
	"time"
)

type Request struct {
	Name    string
	Payload interface{}
}

func New(name string, payload interface{}) Request {
	r := Request{
		Name:    name,
		Payload: payload,
	}
	return r
}

func (wr Request) Do() error {
	tm, _ := time.ParseDuration(fmt.Sprintf("%vs", wr.Payload))
	time.Sleep(tm)
	return nil
}
