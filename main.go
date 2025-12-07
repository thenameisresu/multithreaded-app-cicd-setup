package main

import (
	"fmt"
	"net/http"
	"runtime"
	"sync"
	"time"
)

func worker(id int, wg *sync.WaitGroup) {
	defer wg.Done()
	fmt.Printf("Worker %d starting\n", id)
	time.Sleep(time.Second * 2)
	fmt.Printf("Worker %d done\n", id)
}

func healthHandler(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	fmt.Fprintf(w, "OK")
}

func mainHandler(w http.ResponseWriter, r *http.Request) {
	var wg sync.WaitGroup
	numWorkers := 5

	for i := 1; i <= numWorkers; i++ {
		wg.Add(1)
		go worker(i, &wg)
	}

	wg.Wait()

	fmt.Fprintf(w, "Completed %d workers using %d CPUs\n", numWorkers, runtime.NumCPU())
}

func main() {
	http.HandleFunc("/", mainHandler)
	http.HandleFunc("/health", healthHandler)

	fmt.Println("Server starting on :8080")
	if err := http.ListenAndServe(":8080", nil); err != nil {
		panic(err)
	}
}
