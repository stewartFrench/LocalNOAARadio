//
//  NOAAWeatherService.swift
//  LocalNOAARadio
//
//  Created by Stewart French on 6/20/26.
//

import Foundation
import CoreLocation


//------------
// Models for NOAA Weather API responses
struct NOAAPointResponse: Codable
{
  let properties: PointProperties
  
  
  struct PointProperties: Codable
  {
    let forecast: String
    let forecastHourly: String
    let forecastGridData: String
    let observationStations: String
  } // PointProperties
} // NOAAPointResponse


//------------
struct NOAAForecastResponse: Codable
{
  let properties: ForecastProperties
  
  
  struct ForecastProperties: Codable
  {
    let periods: [ForecastPeriod]
  } // ForecastProperties
  
  
  struct ForecastPeriod: Codable, Identifiable
  {
    let number: Int
    let name: String
    let startTime: String
    let endTime: String
    let isDaytime: Bool
    let temperature: Int
    let temperatureUnit: String
    let windSpeed: String
    let windDirection: String
    let shortForecast: String
    let detailedForecast: String
    
    var id: Int { number }
  } // ForecastPeriod
} // NOAAForecastResponse


//------------
struct NOAAAlertResponse: Codable
{
  let features: [AlertFeature]
  
  
  struct AlertFeature: Codable, Identifiable
  {
    let id: String
    let properties: AlertProperties
  } // AlertFeature
  
  
  struct AlertProperties: Codable
  {
    let event: String
    let headline: String?
    let description: String
    let instruction: String?
    let severity: String
    let urgency: String
    let certainty: String
  } // AlertProperties
} // NOAAAlertResponse


//------------
@Observable
class NOAAWeatherService
{
  var forecastPeriods: [NOAAForecastResponse.ForecastPeriod] = []
  var activeAlerts: [NOAAAlertResponse.AlertFeature] = []
  var currentLocation: CLLocation?
  var statusMessage: String = "Finding your location..."
  var isLoading: Bool = false
  var errorMessage: String?
  
  
  //----
          // Fetch weather data for a location
  func fetchWeather(for location: CLLocation) async
  {
    currentLocation = location
    isLoading = true
    statusMessage = "Fetching weather data..."
    errorMessage = nil
    
    do
    {
      // Step 1: Get the forecast URL from coordinates
      let pointURL = URL(string: "https://api.weather.gov/points/\(location.coordinate.latitude),\(location.coordinate.longitude)")!
      
      let (pointData, _) = try await URLSession.shared.data(from: pointURL)
      let pointResponse = try JSONDecoder().decode(NOAAPointResponse.self,
                                                   from: pointData)
      
      // Step 2: Fetch the forecast
      let forecastURL = URL(string: pointResponse.properties.forecast)!
      let (forecastData, _) = try await URLSession.shared.data(from: forecastURL)
      let forecastResponse = try JSONDecoder().decode(NOAAForecastResponse.self,
                                                      from: forecastData)
      
      forecastPeriods = forecastResponse.properties.periods
      
      // Step 3: Fetch active alerts
      let alertsURL = URL(string: "https://api.weather.gov/alerts/active?point=\(location.coordinate.latitude),\(location.coordinate.longitude)")!
      let (alertsData, _) = try await URLSession.shared.data(from: alertsURL)
      let alertsResponse = try JSONDecoder().decode(NOAAAlertResponse.self,
                                                    from: alertsData)
      
      activeAlerts = alertsResponse.features
      
      // Update status
      if !activeAlerts.isEmpty
      {
        statusMessage = "⚠️ \(activeAlerts.count) active weather alert(s)"
      } // if
      else if !forecastPeriods.isEmpty
      {
        statusMessage = "Weather forecast ready"
      } // else if
      else
      {
        statusMessage = "No forecast data available"
      } // else
      
      isLoading = false
    } // do
    catch
    {
      errorMessage = "Failed to fetch weather data: \(error.localizedDescription)"
      statusMessage = "Error loading weather data"
      isLoading = false
      print("❌ Weather fetch error: \(error)")
    } // catch
  } // fetchWeather
  
  
  //----
          // Get a readable summary of current weather
  var weatherSummary: String
  {
    guard !forecastPeriods.isEmpty else
    {
      return "No weather data available. Please check your location and try again."
    } // guard
    
    var summary = ""
    
    // Add alerts if present
    if !activeAlerts.isEmpty
    {
      summary += "⚠️ ACTIVE WEATHER ALERTS ⚠️\n\n"
      for alert in activeAlerts
      {
        summary += "\(alert.properties.event)\n"
        if let headline = alert.properties.headline
        {
          summary += "\(headline)\n"
        } // if
        summary += "\n"
      } // for
      summary += "---\n\n"
    } // if
    
    // Add current forecast period
    if let current = forecastPeriods.first
    {
      summary += "\(current.name)\n"
      summary += "\(current.temperature)°\(current.temperatureUnit) - \(current.shortForecast)\n"
      summary += "Wind: \(current.windSpeed) \(current.windDirection)\n\n"
      summary += "\(current.detailedForecast)\n\n"
    } // if
    
    // Add next few periods
    for period in forecastPeriods.dropFirst().prefix(3)
    {
      summary += "---\n\n"
      summary += "\(period.name): \(period.shortForecast)\n"
      summary += "\(period.temperature)°\(period.temperatureUnit)\n\n"
    } // for
    
    return summary
  } // weatherSummary
  
  
  //----
          // Get text suitable for speech synthesis
  var speechText: String
  {
    guard !forecastPeriods.isEmpty else
    {
      return "No weather data available."
    } // guard
    
    var speech = ""
    
    // Announce alerts first
    if !activeAlerts.isEmpty
    {
      speech += "Attention. There are \(activeAlerts.count) active weather alerts. "
      for alert in activeAlerts.prefix(3)
      {
        speech += "\(alert.properties.event). "
        if let headline = alert.properties.headline
        {
          speech += "\(headline). "
        } // if
      } // for
    } // if
    
    // Current forecast
    if let current = forecastPeriods.first
    {
      speech += "Current forecast for \(current.name). "
      speech += "\(current.detailedForecast) "
      speech += "Temperature \(current.temperature) degrees \(current.temperatureUnit). "
      speech += "Wind \(current.windSpeed) from the \(current.windDirection). "
    } // if
    
    // Next period
    if forecastPeriods.count > 1
    {
      let next = forecastPeriods[1]
      speech += "\(next.name). \(next.shortForecast). "
      speech += "Temperature \(next.temperature) degrees. "
    } // if
    
    return speech
  } // speechText

} // class NOAAWeatherService
