package main

import (
	"fmt"
	"log"
	"net"
	"net/http"
	"net/rpc"

	"github.com/thetonymaster/rpc/go/server"
)

func main() {
	fibserver := new(server.FibServer)
	rpc.Register(fibserver)
	rpc.HandleHTTP()
	l, e := net.Listen("tcp", ":1234")
	if e != nil {
		log.Fatal("listen error:", e)
	}
	go http.Serve(l, nil)

	client, err := rpc.DialHTTP("tcp", "localhost:1234")
	if err != nil {
		log.Fatal("dialing:", err)
	}

	// Synchronous call
	var reply int
	err = client.Call("FibServer.GetFibonacci", 10, &reply)
	if err != nil {
		log.Fatal("error:", err)
	}
	fmt.Printf("Result: %d\n", reply)

	// Async call
	var reply2 int
	asyncCall := client.Go("FibServer.GetFibonacci", 10, &reply2, nil)
	if err != nil {
		log.Fatal("error:", err)
	}
	<-asyncCall.Done
	fmt.Printf("Result: %d\n", reply2)

}
