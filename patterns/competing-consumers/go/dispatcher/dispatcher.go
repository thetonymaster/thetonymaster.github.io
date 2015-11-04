package dispatcher

import (
	"fmt"

	"github.com/thetonymaster/competing-consumers/go/collector"
	"github.com/thetonymaster/competing-consumers/go/worker"
)

func StartDispatcher(nworkers int) {
	WorkerQueue := make(chan chan worker.WorkRequest, nworkers)

	for i := 0; i < nworkers; i++ {
		worker := worker.NewWorker(i+1, WorkerQueue)
		worker.Start()
	}

	go func() {
		for {
			select {
			case work := <-collector.WorkQueue:
				fmt.Println("Received work request")
				go func() {
					worker := <-WorkerQueue

					fmt.Println("Dispatching work request")
					worker <- work
				}()
			}
		}
	}()
}
