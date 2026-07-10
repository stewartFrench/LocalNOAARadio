//
//  LocationSearchView.swift
//  LocalNOAARadio
//
//  Created by Stewart French on 6/15/26.
//

import SwiftUI
import MapKit


//------------
struct LocationSearchView: View
{
  @Environment(\.dismiss) var dismiss
  @Bindable var weatherService: NOAAWeatherService
  @Bindable var locationManager: LocationManager
  
  @State private var searchText = ""
  @State private var isSearching = false
  
  
  var body: some View
  {
    NavigationView
    {
      VStack(spacing: 20)
      {
        Text("Search for any US location to get weather forecasts and alerts")
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
          .padding()
        
        HStack
        {
          TextField("Enter city or address",
                   text: $searchText)
            .textFieldStyle(.roundedBorder)
            .autocapitalization(.words)
          
          Button(action:
          {
            searchLocation()
          }) // action
          {
            Image(systemName: "magnifyingglass")
              .font(.title3)
              .padding(8)
              .background(Color.blue)
              .foregroundColor(.white)
              .cornerRadius(8)
          } // Button
          .disabled(searchText.isEmpty || isSearching)
        } // HStack
        .padding(.horizontal)
        
        if isSearching
        {
          ProgressView("Searching...")
            .padding()
        } // if
        
        Spacer()
      } // VStack
      .navigationTitle("Search Location")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar
      {
        ToolbarItem(placement: .cancellationAction)
        {
          Button("Cancel")
          {
            dismiss()
          } // Button
        } // ToolbarItem
      } // toolbar
    } // NavigationView
  } // body
  
  
  //----
          // Search for location
  func searchLocation()
  {
    isSearching = true
    
    let request = MKLocalSearch.Request()
    request.naturalLanguageQuery = searchText
    request.resultTypes = [.address, .pointOfInterest]
    
    let search = MKLocalSearch(request: request)
    search.start
    { response, error in
      isSearching = false
      
      if let error = error
      {
        print("❌ Search error: \(error)")
        return
      } // if
      
      guard let mapItem = response?.mapItems.first else
      {
        print("❌ No results found")
        return
      } // guard
      
      let coordinate = mapItem.placemark.coordinate
      let location = CLLocation(latitude: coordinate.latitude,
                               longitude: coordinate.longitude)
      
      // Update location name
      if let name = mapItem.name
      {
        locationManager.locationName = name
      } // if
      else if let city = mapItem.placemark.locality,
              let state = mapItem.placemark.administrativeArea
      {
        locationManager.locationName = "\(city), \(state)"
      } // else if
      
      locationManager.currentLocation = location
      
      // Fetch weather for this location
      Task
      {
        await weatherService.fetchWeather(for: location)
        dismiss()
      } // Task
    } // start
  } // searchLocation

} // struct LocationSearchView
