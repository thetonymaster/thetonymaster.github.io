package collector

import (
	"fmt"

	"github.com/thetonymaster/competing-consumers/go/work"
)

var WorkQueue = make(chan work.Request, 100)

func Collector(name string, payload interface{}) {

	work := work.New(name, payload)

	WorkQueue <- work
	fmt.Println("Work request queued")

}
