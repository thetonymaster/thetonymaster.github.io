package presenter

import (
	"bytes"
	"encoding/json"
	"fmt"
)

func NewPresenter(in <-chan []byte) <-chan []byte {
	out := make(chan []byte, 10)
	go present(in, out)
	return out
}

func present(in <-chan []byte, out chan []byte) {
	for msg := range in {
		ct := city{}
		err := json.Unmarshal(msg, &ct)
		if err != nil {
			panic(err)
		}
		res := getPresentation(&ct)
		out <- res
	}
}

func getPresentation(ct *city) []byte {
	buf := bytes.Buffer{}

	greeting := fmt.Sprintf("Hello your forecast for %s will be\n", ct.Name)
	curr := fmt.Sprintf("The current weather is %s with %s\n", ct.Weather.Main, ct.Weather.Description)
	t := fmt.Sprintf("The current temperature is %f°C, Max and Min will be %f°C and %f°C\n", ct.Temperature.Temperature, ct.Temperature.TempMax, ct.Temperature.TempMin)
	h := fmt.Sprintf("With a humidity of %f percent \n", ct.Temperature.Humidity)
	forecast := "The forecast for the next few days will be\n"

	buf.WriteString(greeting)
	buf.WriteString(curr)
	buf.WriteString(t)
	buf.WriteString(h)
	buf.WriteString(forecast)
	buf.WriteString("\n")
	buf.Write(getForecast(ct.Forecast, ct.Name))
	return buf.Bytes()

}

func getForecast(fc []forecast, city string) []byte {
	buf := bytes.Buffer{}

	for _, f := range fc {
		curr := fmt.Sprintf("The forecast in %s for %s is %s with %s\n", city, f.Time, f.Weather.Main, f.Weather.Description)
		morning := fmt.Sprintf("A temperature of %f durint the morning\n", f.Temperature.Morning)
		day := fmt.Sprintf("A temperature of %f durint the day\n", f.Temperature.Day)
		eve := fmt.Sprintf("A temperature of %f durint the eve\n", f.Temperature.Eve)
		minmax := fmt.Sprintf("Max and Min will be %f°C and %f°C\n", f.Temperature.Min, f.Temperature.Max)
		wind := fmt.Sprintf("With a wind of %f and with %f°\n", f.Speed, f.Degrees)
		h := fmt.Sprintf("With a humidity of %f percent \n", f.Humidity)

		buf.WriteString(curr)
		buf.WriteString(morning)
		buf.WriteString(day)
		buf.WriteString(eve)
		buf.WriteString(minmax)
		buf.WriteString(wind)
		buf.WriteString(h)
		buf.WriteString("\n")

	}

	return buf.Bytes()
}

type city struct {
	Name        string      `json:"name"`
	Weather     weather     `json:"weather"`
	Temperature temperature `json:"temperature"`
	Forecast    []forecast  `json:"forecast"`
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

type temp struct {
	Day     float32 `json:"day"`
	Min     float32 `json:"min"`
	Max     float32 `json:"max"`
	Night   float32 `json:"night"`
	Eve     float32 `json:"eve"`
	Morning float32 `json:"morn"`
}
