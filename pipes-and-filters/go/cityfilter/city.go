package cityfilter

import "encoding/json"

func NewCityFilter(in <-chan []byte) <-chan []byte {
	out := make(chan []byte, 10)
	go filter(in, out)
	return out
}

func filter(in <-chan []byte, out chan []byte) {
	for msg := range in {
		list := weatherlist{}
		err := json.Unmarshal(msg, &list)
		if err != nil {
			panic(err)
		}

		for _, ct := range list.List {
			ct2 := city{
				ID:          ct.ID,
				Name:        ct.Name,
				Temperature: ct.Temperature,
				Weather:     ct.Weather[0],
			}

			res, err := json.Marshal(ct2)
			if err != nil {
				panic(err)
			}
			out <- res
		}

	}
}

type weatherlist struct {
	Count int        `json:"cnt"`
	List  []cityJSON `json:"list"`
}

type cityJSON struct {
	Name        string      `json:"name"`
	ID          int         `json:"id"`
	Weather     []weather   `json:"weather"`
	Temperature temperature `json:"main"`
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
}
