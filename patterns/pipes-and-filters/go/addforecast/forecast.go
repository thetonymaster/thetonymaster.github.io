package addforecast

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
	"time"
)

func NewForecast(in <-chan []byte) <-chan []byte {
	out := make(chan []byte, 10)
	go addForecast(in, out)
	return out
}

func addForecast(in <-chan []byte, out chan []byte) {
	forecastURL := "http://api.openweathermap.org/data/2.5/forecast/daily?id=%d&units=metric"
	for msg := range in {
		ct := city{}
		err := json.Unmarshal(msg, &ct)
		if err != nil {
			panic(err)
		}

		resp, err := http.Get(fmt.Sprintf(forecastURL, ct.ID))
		if err != nil {
			panic(err)
		}

		body, err := ioutil.ReadAll(resp.Body)
		list := jsonList{}
		err = json.Unmarshal(body, &list)
		if err != nil {
			panic(err)
		}

		f := []forecast{}
		for _, wj := range list.List {
			tm := time.Unix(wj.Time, 0)
			w := forecast{
				Time:        tm.Format("Sat Mar  7 11:06:39 PST 2015"),
				Temperature: wj.Temperature,
				Pressure:    wj.Pressure,
				Humidity:    wj.Humidity,
				Weather:     wj.Weather[0],
				Speed:       wj.Speed,
				Degrees:     wj.Degrees,
				Rain:        wj.Rain,
			}

			f = append(f, w)
		}
		ct.Forecast = f

		res, err := json.Marshal(ct)
		if err != nil {
			panic(err)
		}
		out <- res

	}
}

type weather struct {
	Main        string `json:"main"`
	Description string `json:"description"`
}

type temperature struct {
	Temperature float32 `json:"temp"`
	Pressure    float32 `json:"pressure" `
	Humidity    float32 `json:"humidity"`
	TempMin     float32 `json:"temp_min"`
	TempMax     float32 `json:"temp_max"`
}

type city struct {
	Name        string      `json:"name"`
	ID          int         `json:"id"`
	Weather     weather     `json:"weather"`
	Temperature temperature `json:"temperature"`
	Forecast    []forecast  `json:"forecast"`
}

type jsonList struct {
	List []forecastJson `json:"list"`
}

type forecast struct {
	Time        string  `json:"time"`
	Temperature temp    `json:"temp"`
	Pressure    float32 `json:"pressure"`
	Humidity    float32 `json:"humidity"`
	Weather     weather `json:"weather"`
	Speed       float32 `json:"speed"`
	Degrees     float32 `json:"deg"`
	Rain        float32 `json:"rain"`
}

type forecastJson struct {
	Time        int64     `json:"dt"`
	Temperature temp      `json:"temp"`
	Pressure    float32   `json:"pressure"`
	Humidity    float32   `json:"humidity"`
	Weather     []weather `json:"weather"`
	Speed       float32   `json:"speed"`
	Degrees     float32   `json:"deg"`
	Rain        float32   `json:"rain"`
}

type temp struct {
	Day     float32 `json:"day"`
	Min     float32 `json:"min"`
	Max     float32 `json:"max"`
	Night   float32 `json:"night"`
	Eve     float32 `json:"eve"`
	Morning float32 `json:"morn"`
}
