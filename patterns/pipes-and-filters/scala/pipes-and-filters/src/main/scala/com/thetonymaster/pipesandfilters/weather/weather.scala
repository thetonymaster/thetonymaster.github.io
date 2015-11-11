package com.thetonymaster.pipesandfilters.weather

case class WeatherList (list: List[CityJSON])
case class CityJSON(name: String, id: Int, weather: List[WeatherJSON], main: Temperature)
case class WeatherJSON(main: String, description: String)
case class Temperature(temp: Float, pressure: Float, humidity: Float, temp_min: Float, temp_max: Float)

case class ForecastList(list: List[ForecastJson])
case class ForecastJson(dt: Long, temp: ForecastTemperature, pressure: Float, humidity: Float, weather: List[WeatherJSON], speed: Float, deg: Int, clouds: Int)
case class ForecastTemperature(day: Float, min: Float, max: Float, night: Float, eve: Float, morn: Float)

case class City(name: String, id: Int, weather: List[WeatherJSON], main: Temperature, forecast: List[ForecastJson])
