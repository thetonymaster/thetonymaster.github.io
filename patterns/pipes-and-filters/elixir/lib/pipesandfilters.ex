defmodule PipesAndFilters do

  def start do
    cities = spawn(Cities, :filter, [])
    :global.register_name("nextcity", cities)

    forecast = spawn(Forecast, :get, [])
    :global.register_name("nextforecast", forecast)

    writer = spawn(Sink, :write, [])
    :global.register_name("nextsink", writer)

    get_weather
  end

  def get_weather do
    HTTPotion.get("http://api.openweathermap.org/data/2.5/group?id=3979844,4005539,3530597,4005270&units=metric")
    |> process_response
    :timer.sleep(30000)
    get_weather
  end

  defp process_response(%{status_code: 200, body: body}) do
    cities = body
            |> to_string
            |> Poison.decode!
            |> extract_cities
    send :global.whereis_name("nextcity"), cities
  end

  defp extract_cities(%{"list" => cities}) do
    cities
  end

end

defmodule Cities do

    def filter do
      receive do
        cities ->
          get_cities cities
      end
      filter
    end

    defp get_cities [next | tail] do
      send :global.whereis_name("nextforecast"), next
      get_cities tail
    end

    defp get_cities [] do
    end

end

defmodule Forecast do

  def get do
    receive do
      city ->
        append city
    end
    get
  end

  defp append city do
    url = geturl city["id"]
    forecast = HTTPotion.get(url)
      |> process_response
    city = Map.put(city, "forecast", forecast)
    send :global.whereis_name("nextsink"), city
  end

  defp geturl id do
      "http://api.openweathermap.org/data/2.5/forecast/daily?id=" <> to_string(id) <>"&units=metric"
  end

  defp process_response(%{status_code: 200, body: body}) do
    body
      |> to_string
      |> Poison.decode!
      |> extract_forecast
  end

  defp extract_forecast(%{"list" => forecast}) do
    forecast
  end

end

defmodule Sink do

  def write do
    receive do
      city ->
        current_forecast city
    end
    write
  end

  defp current_forecast city do
    IO.puts "Hello your forecast for " <> city["name"] <> " will be"
    write_weather city["weather"]
    IO.puts "The current temperature is " <> to_string(city["main"]["temp"]) <>"°C, Max and Min will be "<> to_string(city["main"]["temp_min"])<>"°C and "<> to_string(city["main"]["temp_max"])<>"°C"
    IO.puts "With a humidity of "<> to_string(city["weather"]["humidity"]) <> " percent"
    IO.puts "The forecast for the next few days will be"
    write_forecast city["forecast"]
  end

  defp write_weather [] do
  end
  defp write_weather [weather | tail] do
      IO.puts "The weather is " <> weather["main"] <>" with " <> weather["description"]
      write_weather tail
  end

  defp write_forecast [] do
  end
  defp write_forecast [forecast | tail] do
    dt = Convert.from_timestamp(forecast["dt"])
         |> Calendar.DateTime.from_erl!("America/Mexico_City")
         |> Calendar.DateTime.Format.rfc2822
    IO.puts "The forecast for is " <> dt
    write_weather forecast["weather"]
		IO.puts "A temperature of "<> to_string(forecast["temp"]["morn"]) <>" durint the morning"
		IO.puts "A temperature of " <> to_string(forecast["temp"]["day"]) <> " durint the day"
		IO.puts "A temperature of " <> to_string(forecast["temp"]["eve"]) <> " durint the eve"
		IO.puts "Max and Min will be " <> to_string(forecast["temp"]["max"]) <> "°C and " <> to_string(forecast["temp"]["min"]) <> "°C"
		IO.puts "With a wind of " <> to_string(forecast["speed"]) <> " and with "<>to_string(forecast["deg"]) <> "°"
		IO.puts "With a humidity of " <> to_string(forecast["humidity"]) <> " percent "
    IO.puts ""
    write_forecast tail
  end

end

defmodule Convert do
  epoch = {{1970, 1, 1}, {0, 0, 0}}
  @epoch :calendar.datetime_to_gregorian_seconds(epoch)

  def from_timestamp(timestamp) do
    timestamp
    |> +(@epoch)
    |> :calendar.gregorian_seconds_to_datetime
  end

  def to_timestamp(datetime) do
    datetime
    |> :calendar.datetime_to_gregorian_seconds
    |> -(@epoch)
  end
end
