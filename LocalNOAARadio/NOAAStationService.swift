//
//  NOAAStationService.swift
//  LocalNOAARadio
//
//  Created by Stewart French on 6/15/26.
//

import Foundation
import CoreLocation


//------------
        // Represents a NOAA weather radio station
struct NOAAStation: Codable, Equatable
{
  let callSign: String
  let frequency: String
  let city: String
  let latitude: Double
  let longitude: Double
  let streamURL: String?  // Optional - not all stations have streams
  

          // Computed property for location coordinate
  var location: CLLocationCoordinate2D
  {
    CLLocationCoordinate2D(latitude : latitude,
                           longitude: longitude)
  } // location
  

          // Computed property for URL
  var url: URL?
  {
    guard let streamURL = streamURL else { return nil }
    return URL(string: streamURL)
  } // url
  

          // Check if station has a stream available
  var hasStream: Bool
  {
    streamURL != nil && !streamURL!.isEmpty
  } // hasStream

} // struct NOAAStation


//------------
        // Finds the closest NOAA weather radio station based on user location
@Observable
class NOAAStationService: NSObject, CLLocationManagerDelegate
{
  var closestStation: NOAAStation?          // Closest streamable station
  var closestNonStreamStation: NOAAStation? // Closest station without stream (if closer)
  var currentLocation: CLLocation?
  var locationStatus = "Getting location..."
  var customStationManager = CustomStationManager()
  var sortedStreamableStations: [NOAAStation] = [] // All streamable stations sorted by distance
  var triedStations: Set<String> = []              // Track stations that have been tried (by callSign)
  
  private let locationManager = CLLocationManager()
  private var stations: [NOAAStation] = []
  

  override init()
  {
    super.init()
    locationManager.delegate = self
    locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    loadStations()
  } // init


  //----
          // Load stations from JSON file
  private func loadStations()
  {
    guard let url = Bundle.main.url(forResource  : "NOAAStations",
                                     withExtension: "json") else
    {
      print("❌ Failed to locate NOAAStations.json")
      return
    } // guard
    
    do
    {
      let data = try Data(contentsOf: url)
      let decoder = JSONDecoder()
      stations = try decoder.decode([NOAAStation].self,
                                     from: data)
      print("✅ Loaded \(stations.count) NOAA stations from database")
    } // do
    catch
    {
      print("❌ Failed to load stations: \(error)")
    } // catch
  } // loadStations


  //----
          // Request location permission and start updates
  func requestLocation()
  {
    let authStatus = locationManager.authorizationStatus
    print("🔐 Location authorization status: \(authStatus.rawValue)")
    
    switch authStatus
    {
      case .notDetermined:
        locationManager.requestWhenInUseAuthorization()

      case .authorizedWhenInUse, .authorizedAlways:
        locationManager.startUpdatingLocation()

      case .denied, .restricted:
        locationStatus = "Location access denied. Using default station."
        closestStation = stations.first
        return

      @unknown default:
        break
    } // switch
    
    locationManager.startUpdatingLocation()
  } // requestLocation


  //----
          // Handle authorization changes
  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager)
  {
    print("🔐 Authorization changed to: \(manager.authorizationStatus.rawValue)")
    if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways
    {
      locationManager.startUpdatingLocation()
    } // if
  } // locationManagerDidChangeAuthorization


  //----
          // CLLocationManagerDelegate method - called when location is updated
  func locationManager(_ manager  : CLLocationManager,
                       didUpdateLocations locations: [CLLocation])
  {
    guard let location = locations.last else { return }
    currentLocation = location
    findClosestStationInternal(to: location)
    locationManager.stopUpdatingLocation()
  } // locationManager


  //----
          // CLLocationManagerDelegate method - called when location update fails
  func locationManager(_ manager     : CLLocationManager,
                       didFailWithError error: Error)
  {
    locationStatus = "Location error: \(error.localizedDescription)"

            // Fallback to a default station if location fails
    closestStation = stations.first
  } // locationManager


  //----
          // Public method to find closest station at a specific location
  func findClosestStation(at location: CLLocation)
  {
    currentLocation = location
    findClosestStationInternal(to: location)
  } // findClosestStation


  //----
          // Internal method to find the closest NOAA station to the given location
  private func findClosestStationInternal(to location: CLLocation)
  {
    var nearestStreamableStation: NOAAStation?
    var shortestStreamableDistance: CLLocationDistance = .infinity
    
    var nearestOverallStation: NOAAStation?
    var shortestOverallDistance: CLLocationDistance = .infinity
    
            // Reset tried stations when location changes
    triedStations.removeAll()
    
    print("📍 Your location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
    
            // Combine built-in and custom stations
    let allStations = stations + customStationManager.customStations
    
            // Create array of streamable stations with distances
    var streamableStationsWithDistance: [(station: NOAAStation, distance: CLLocationDistance)] = []
    
    for station in allStations
    {
      let stationLocation = CLLocation(latitude : station.location.latitude,
                                        longitude: station.location.longitude)
      let distance = location.distance(from: stationLocation)
      let distanceInMiles = distance / 1609.34
      
      print("  📡 \(station.city): \(String(format: "%.1f", distanceInMiles)) miles \(station.hasStream ? "(stream)" : "(no stream)")")
      
              // Track closest overall station
      if distance < shortestOverallDistance
      {
        shortestOverallDistance = distance
        nearestOverallStation = station
      } // if
      
              // Track closest streamable station
      if station.hasStream && distance < shortestStreamableDistance
      {
        shortestStreamableDistance = distance
        nearestStreamableStation = station
      } // if
      
              // Add to streamable list for sorting
      if station.hasStream
      {
        streamableStationsWithDistance.append((station: station, distance: distance))
      } // if
    } // for
    
            // Sort streamable stations by distance
    sortedStreamableStations = streamableStationsWithDistance
      .sorted { $0.distance < $1.distance }
      .map { $0.station }
    
            // Set the closest streamable station for playback
    closestStation = nearestStreamableStation
    
            // If there's a closer non-streamable station, save it
    if let overall = nearestOverallStation,
       let streamable = nearestStreamableStation,
       shortestOverallDistance < shortestStreamableDistance
    {
      closestNonStreamStation = overall
      let overallMiles = shortestOverallDistance / 1609.34
      let streamableMiles = shortestStreamableDistance / 1609.34
      print("ℹ️ Closest overall: \(overall.city) (\(String(format: "%.1f", overallMiles)) miles) - no stream")
      print("✅ Closest streamable: \(streamable.city) (\(String(format: "%.1f", streamableMiles)) miles)")
      
      locationStatus = "Streaming: \(streamable.city) (\(String(format: "%.1f", streamableMiles)) mi)\nCloser station available (no stream): \(overall.city) at \(overall.frequency)"
    } // if
    else if let streamable = nearestStreamableStation
    {
      closestNonStreamStation = nil
      let distanceInMiles = shortestStreamableDistance / 1609.34
      print("✅ Selected: \(streamable.city) (\(String(format: "%.1f", distanceInMiles)) miles away)")
      locationStatus = "Closest station: \(streamable.city) (\(String(format: "%.1f", distanceInMiles)) miles away)"
    } // else if
    else if let overall = nearestOverallStation
    {
      closestNonStreamStation = overall
      let distanceInMiles = shortestOverallDistance / 1609.34
      print("⚠️ Only non-streamable station found: \(overall.city)")
      locationStatus = "Nearest station: \(overall.city) at \(overall.frequency) (\(String(format: "%.1f", distanceInMiles)) mi)\nNo streaming available - use a physical weather radio"
    } // else if
  } // findClosestStationInternal


  //----
          // Try the next closest station (used when current stream fails)
  func tryNextClosestStation() -> NOAAStation?
  {
    guard let current = closestStation,
          let currentIndex = sortedStreamableStations.firstIndex(of: current),
          currentIndex + 1 < sortedStreamableStations.count else
    {
      print("⚠️ No more stations available to try")
      return nil
    } // guard
    
    let nextStation = sortedStreamableStations[currentIndex + 1]
    closestStation = nextStation
    triedStations.insert(nextStation.callSign)
    
    let distanceInMiles = currentLocation?.distance(from: CLLocation(latitude : nextStation.latitude,
                                                                      longitude: nextStation.longitude)) ?? 0.0
    let miles = distanceInMiles / 1609.34
    
    print("🔄 Switching to next closest station: \(nextStation.city) (\(String(format: "%.1f", miles)) miles away)")
    locationStatus = "Station: \(nextStation.city) (\(String(format: "%.1f", miles)) mi) - Previous stream failed"
    
    return nextStation
  } // tryNextClosestStation


  //----
          // Skip to next closest station (user-initiated)
  func skipToNextStation() -> NOAAStation?
  {
    guard !sortedStreamableStations.isEmpty else
    {
      print("⚠️ No stations available")
      return nil
    } // guard
    
            // Mark current station as tried if it exists
    if let current = closestStation
    {
      triedStations.insert(current.callSign)
    } // if
    
            // Find next untried station
    for station in sortedStreamableStations
    {
      if !triedStations.contains(station.callSign)
      {
        closestStation = station
        triedStations.insert(station.callSign)
        
        let distanceInMiles = currentLocation?.distance(from: CLLocation(latitude : station.latitude,
                                                                          longitude: station.longitude)) ?? 0.0
        let miles = distanceInMiles / 1609.34
        
        print("⏭️ Skipping to next station: \(station.city) (\(String(format: "%.1f", miles)) miles away)")
        locationStatus = "Station: \(station.city) (\(String(format: "%.1f", miles)) mi)"
        
        return station
      } // if
    } // for
    
            // All stations have been tried - reset and start over
    print("🔄 All stations tried, resetting...")
    triedStations.removeAll()
    if let firstStation = sortedStreamableStations.first
    {
      closestStation = firstStation
      triedStations.insert(firstStation.callSign)
      
      let distanceInMiles = currentLocation?.distance(from: CLLocation(latitude : firstStation.latitude,
                                                                        longitude: firstStation.longitude)) ?? 0.0
      let miles = distanceInMiles / 1609.34
      
      locationStatus = "Station: \(firstStation.city) (\(String(format: "%.1f", miles)) mi) - Restarted from closest"
      
      return firstStation
    } // if
    
    return nil
  } // skipToNextStation

} // class NOAAStationService
