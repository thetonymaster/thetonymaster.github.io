package main

import (
	"fmt"
	"io/ioutil"
	"net/http"
	"time"

	"github.com/thetonymaster/pipes-and-filters/addforecast"
	"github.com/thetonymaster/pipes-and-filters/cityfilter"
	"github.com/thetonymaster/pipes-and-filters/presenter"
)

func main() {
	var weatherURL = "http://api.openweathermap.org/data/2.5/group?id=3979844,4005539,3530597,4005270&units=metric"
	weather := GetWeather(weatherURL)
	cities := cityfilter.NewCityFilter(weather)
	forecast := addforecast.NewForecast(cities)
	res := presenter.NewPresenter(forecast)
	for msg := range res {
		fmt.Println(string(msg))
	}
}

func GetWeather(weatherURL string) <-chan []byte {
	out := make(chan []byte, 10)

	go func() {
		for {
			resp, err := http.Get(weatherURL)
			if err != nil {
				panic(err)
			}

			body, err := ioutil.ReadAll(resp.Body)
			if err != nil {
				panic(err)
			}
			resp.Body.Close()
			out <- body
			time.Sleep(30 * time.Second)
		}
	}()

	return out
}
