package com.thetonymaster.pipesandfilters.weatherforecast

import com.thetonymaster.pipesandfilters.weather._

import akka.actor._
import net.liftweb.json._
import scalaj.http._

class WeatherForecast(nextFilter: ActorRef) extends Actor{
  implicit val formats = DefaultFormats
  val forecasrURL: String = "http://api.openweathermap.org/data/2.5/forecast/daily?id="
  val apiKey: String = "&units=metric&appid=5a917cc621913d534c113dbae4b5e5d9"
  def receive = {
    case city: CityJSON =>
      val url: String = forecasrURL ++ city.id.toString ++ apiKey
      val response: HttpResponse[String] = Http(url).asString
      val json = parse(response.body)
      val forecast = json.extract[ForecastList]
      val city2 = City(city.name, city.id, city.weather, city.main, forecast.list)
      nextFilter ! city2
  }
}
