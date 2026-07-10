//
//  ContentView.swift
//  LocalNOAARadio
//
//  Created by Stewart French on 6/15/26.
//

import SwiftUI
import CoreLocation


//------------
struct ContentView: View
{
  @State private var weatherService = NOAAWeatherService()
  @State private var speechManager = SpeechManager()
  @State private var locationManager = LocationManager()
  @State private var showLocationSearch = false
  

  var body: some View
  {
    VStack(spacing: 20)
    {
              // Header
      VStack(spacing: 8)
      {
        Image(systemName: "cloud.sun.fill")
          .font(.system(size: 60))
          .foregroundStyle(.blue)
        
        Text("NOAA Weather")
          .font(.largeTitle)
          .fontWeight(.bold)
        
        if let location = weatherService.currentLocation
        {
          Text(locationManager.locationName ?? "Your Location")
            .font(.headline)
            .foregroundStyle(.secondary)
          
          Text(String(format: "%.4f°, %.4f°",
                     location.coordinate.latitude,
                     location.coordinate.longitude))
            .font(.caption)
            .foregroundStyle(.secondary)
        } // if
      } // VStack
      .padding(.top)
      
              // Status message
      Text(weatherService.statusMessage)
        .font(.subheadline)
        .foregroundStyle(weatherService.errorMessage != nil ? .red : .secondary)
        .multilineTextAlignment(.center)
        .padding(.horizontal)
      
              // Action Buttons
      HStack(spacing: 12)
      {
                // Enter Location button
        Button(action:
        {
          showLocationSearch = true
        }) // action
        {
          VStack(spacing: 4)
          {
            Image(systemName: "magnifyingglass")
              .font(.title2)
            Text("Enter\nLocation")
              .font(.caption)
              .multilineTextAlignment(.center)
          } // VStack
          .frame(maxWidth: .infinity, minHeight: 50)
          .padding()
          .background(Color.blue)
          .foregroundColor(.white)
          .cornerRadius(12)
        } // Button
        
                // Listen button
        Button(action:
        {
          if speechManager.isSpeaking
          {
            speechManager.stop()
          } // if
          else
          {
            speechManager.speak(weatherService.speechText)
          } // else
        }) // action
        {
          VStack(spacing: 4)
          {
            Image(systemName: speechManager.isSpeaking ? "stop.fill" : "play.fill")
              .font(.title2)
            Text(speechManager.isSpeaking ? "Stop" : "Listen")
              .font(.caption)
          } // VStack
          .frame(maxWidth: .infinity, minHeight: 50)
          .padding()
          .background(!weatherService.forecastPeriods.isEmpty ? Color.green : Color.gray)
          .foregroundColor(.white)
          .cornerRadius(12)
        } // Button
        .disabled(weatherService.forecastPeriods.isEmpty)
        
                // Refresh button
        Button(action:
        {
          Task
          {
            if let location = weatherService.currentLocation
            {
              await weatherService.fetchWeather(for: location)
            } // if
            else if let location = locationManager.currentLocation
            {
              await weatherService.fetchWeather(for: location)
            } // else if
          } // Task
        }) // action
        {
          VStack(spacing: 4)
          {
            Image(systemName: "arrow.clockwise")
              .font(.title2)
            Text("Refresh")
              .font(.caption)
          } // VStack
          .frame(maxWidth: .infinity, minHeight: 50)
          .padding()
          .background(Color.blue)
          .foregroundColor(.white)
          .cornerRadius(12)
        } // Button
        .disabled(weatherService.isLoading)
      } // HStack
      .padding(.horizontal)
      
              // Speech status
      if speechManager.isSpeaking
      {
        Text(speechManager.statusText)
          .font(.subheadline)
          .foregroundStyle(.secondary)
      } // if
      
              // Active alerts section
      if !weatherService.activeAlerts.isEmpty
      {
        VStack(alignment: .leading, spacing: 8)
        {
          HStack
          {
            Image(systemName: "exclamationmark.triangle.fill")
              .foregroundStyle(.red)
            Text("ACTIVE ALERTS")
              .font(.headline)
              .foregroundStyle(.red)
          } // HStack
          
          ForEach(weatherService.activeAlerts.prefix(3))
          { alert in
            VStack(alignment: .leading, spacing: 4)
            {
              Text(alert.properties.event)
                .font(.subheadline)
                .fontWeight(.bold)
              
              if let headline = alert.properties.headline
              {
                Text(headline)
                  .font(.caption)
                  .foregroundStyle(.secondary)
              } // if
            } // VStack
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.red.opacity(0.1))
            .cornerRadius(8)
          } // ForEach
        } // VStack
        .padding(.horizontal)
      } // if
      
              // Scrollable weather forecast
      ScrollView
      {
        VStack(alignment: .leading, spacing: 16)
        {
          if weatherService.isLoading
          {
            ProgressView("Loading weather data...")
              .frame(maxWidth: .infinity)
              .padding()
          } // if
          else if let error = weatherService.errorMessage
          {
            VStack(spacing: 8)
            {
              Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.orange)
              Text(error)
                .multilineTextAlignment(.center)
            } // VStack
            .frame(maxWidth: .infinity)
            .padding()
          } // else if
          else if !weatherService.forecastPeriods.isEmpty
          {
            ForEach(weatherService.forecastPeriods.prefix(6))
            { period in
              VStack(alignment: .leading, spacing: 8)
              {
                HStack
                {
                  Text(period.name)
                    .font(.headline)
                  Spacer()
                  Text("\(period.temperature)°\(period.temperatureUnit)")
                    .font(.title2)
                    .fontWeight(.bold)
                } // HStack
                
                HStack
                {
                  Image(systemName: period.isDaytime ? "sun.max.fill" : "moon.stars.fill")
                    .foregroundStyle(period.isDaytime ? .orange : .blue)
                  Text(period.shortForecast)
                    .font(.subheadline)
                } // HStack
                
                Text(period.detailedForecast)
                  .font(.body)
                  .foregroundStyle(.secondary)
                
                HStack
                {
                  Image(systemName: "wind")
                  Text("\(period.windSpeed) \(period.windDirection)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                } // HStack
              } // VStack
              .padding()
              .frame(maxWidth: .infinity, alignment: .leading)
              .background(Color(.systemGray6))
              .cornerRadius(12)
            } // ForEach
          } // else if
          else
          {
            VStack(spacing: 16)
            {
              Image(systemName: "cloud.sun.fill")
                .font(.system(size: 60))
                .foregroundStyle(.blue)
              
              Text("Welcome to NOAA Weather")
                .font(.title2)
                .fontWeight(.bold)
              
              Text("Get real-time weather forecasts and alerts from the National Weather Service")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
              
              Text("Tap the location button to get started")
                .font(.caption)
                .foregroundStyle(.secondary)
            } // VStack
            .padding()
          } // else
        } // VStack
        .padding()
      } // ScrollView
      .frame(minHeight: 300)
      
      Spacer()
    } // VStack
    .sheet(isPresented: $showLocationSearch)
    {
      LocationSearchView(weatherService: weatherService,
                        locationManager: locationManager)
    } // sheet
    .onAppear
    {
      locationManager.requestLocation()
    } // onAppear
    .onChange(of: locationManager.currentLocation)
    {
      if let location = locationManager.currentLocation
      {
        Task
        {
          await weatherService.fetchWeather(for: location)
        } // Task
      } // if
    } // onChange
  } // body

} // struct ContentView


//------------
// Simple location manager for getting user location
@Observable
class LocationManager: NSObject, CLLocationManagerDelegate
{
  private var manager = CLLocationManager()
  var currentLocation: CLLocation?
  var locationName: String?
  var locationStatus: String = "Getting location..."
  
  
  override init()
  {
    super.init()
    manager.delegate = self
    manager.desiredAccuracy = kCLLocationAccuracyKilometer
  } // init
  
  
  func requestLocation()
  {
    manager.requestWhenInUseAuthorization()
    manager.requestLocation()
  } // requestLocation
  
  
  func locationManager(_ manager: CLLocationManager,
                      didUpdateLocations locations: [CLLocation])
  {
    guard let location = locations.first else { return }
    currentLocation = location
    locationStatus = "Location found"
    
    // Reverse geocode to get location name
    let geocoder = CLGeocoder()
    geocoder.reverseGeocodeLocation(location)
    { placemarks, error in
      if let placemark = placemarks?.first
      {
        if let city = placemark.locality,
           let state = placemark.administrativeArea
        {
          self.locationName = "\(city), \(state)"
        } // if
        else if let name = placemark.name
        {
          self.locationName = name
        } // else if
      } // if
    } // reverseGeocodeLocation
  } // didUpdateLocations
  
  
  func locationManager(_ manager: CLLocationManager,
                      didFailWithError error: Error)
  {
    locationStatus = "Failed to get location"
    print("❌ Location error: \(error)")
  } // didFailWithError

} // class LocationManager


//------------
#Preview
{
  ContentView()
} // Preview
