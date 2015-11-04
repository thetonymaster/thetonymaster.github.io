package server

type FibServer struct{}

func (s FibServer) GetFibonacci(number int, result *int) error {
	*result = fibonacci(number)
	return nil
}

func fibonacci(n int) int {
	a := 0
	b := 1
	for i := 0; i < n; i++ {
		temp := a
		a = b
		b = temp + a
	}
	return a
}
