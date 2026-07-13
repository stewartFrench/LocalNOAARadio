//
//  LocationSearchView.swift
//  LocalNOAARadio
//
//  Created by Stewart French on 6/15/26.
//

import SwiftUI
import CoreLocation
import MapKit


//------------
struct LocationSearchView: View
{
  @Environment(\.dismiss) var dismiss
  @Binding var stationService: NOAAStationService
  
  @State private var searchText = ""
  @State private var isSearching = false
  @State private var errorMessage = ""
  @State private var showError = false
  

  var body: some View
  {
    NavigationView
    {
      VStack(spacing: 20)
      {
        VStack(alignment: .leading,
               spacing   : 8)
        {
          Text("Enter a Location")
            .font(.headline)
          
          Text("Search for any city, address, or landmark in the USA")
            .font(.subheadline)
            .foregroundStyle(.secondary)
        } // VStack
        .frame(maxWidth: .infinity,
               alignment: .leading)
        .padding()
        
        TextField("e.g., Austin, TX or 123 Main St",
                  text: $searchText)
          .textFieldStyle(.roundedBorder)
          .padding(.horizontal)
          .submitLabel(.search)
          .onSubmit
          {
            searchLocation()
          } // onSubmit
        
        Button(action:
        {
          searchLocation()
        }) // action
        {
          HStack
          {
            if isSearching
            {
              ProgressView()
                .tint(.white)
            } // if
            else
            {
              Image(systemName: "magnifyingglass")
            } // else
            
            Text(isSearching ? "Searching..." : "Find Station")
              .font(.headline)
          } // HStack
          .frame(maxWidth: .infinity)
          .padding()
          .background(searchText.isEmpty ? Color.gray : Color.blue)
          .foregroundColor(.white)
          .cornerRadius(12)
        } // Button
        .disabled(searchText.isEmpty || isSearching)
        .padding(.horizontal)
        
        Divider()
          .padding(.vertical)
        
        VStack(spacing: 12)
        {
          Image(systemName: "location.magnifyingglass")
            .font(.system(size: 50))
            .foregroundStyle(.blue)
          
          Text("Examples:")
            .font(.headline)
          
          VStack(alignment: .leading,
                 spacing   : 6)
          {
            ExampleRow(text: "Austin, TX")
            ExampleRow(text: "New York City")
            ExampleRow(text: "Central Park, NYC")
            ExampleRow(text: "Golden Gate Bridge")
          } // VStack
          .font(.subheadline)
          .foregroundStyle(.secondary)
        } // VStack
        .padding()
        
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
        
        ToolbarItem(placement: .primaryAction)
        {
          Button("Use Current")
          {
            useCurrentLocation()
          } // Button
        } // ToolbarItem
      } // toolbar
      .alert("Location Not Found",
             isPresented: $showError)
      {
        Button("OK",
               role: .cancel)
        {
        } // Button
      } message:
      {
        Text(errorMessage)
      } // alert
    } // NavigationView
  } // body


  //----
          // Search for the entered location
  func searchLocation()
  {
    isSearching = true
    
            // Use MapKit's modern geocoding API
    let request = MKLocalSearch.Request()
    request.naturalLanguageQuery = searchText
    request.resultTypes = [.address, .pointOfInterest]
    
    let search = MKLocalSearch(request: request)
    search.start
    { response, error in
      isSearching = false
      
      if let error = error
      {
        errorMessage = "Could not find location: \(error.localizedDescription)"
        showError = true
        return
      } // if
      
      guard let mapItem = response?.mapItems.first else
      {
        errorMessage = "No results found for '\(searchText)'. Please try a different search."
        showError = true
        return
      } // guard
      
              // Get location from map item
      let location = mapItem.location
      
              // Update station service with the searched location
      stationService.findClosestStation(at: location)
      
      dismiss()
    } // start
  } // searchLocation


  //----
          // Use current GPS location
  func useCurrentLocation()
  {
    stationService.requestLocation()
    dismiss()
  } // useCurrentLocation

} // struct LocationSearchView


//------------
        // Example row for location search
struct ExampleRow: View
{
  let text: String
  

  var body: some View
  {
    HStack
    {
      Image(systemName: "mappin.circle.fill")
        .foregroundStyle(.blue)
      Text(text)
    } // HStack
  } // body

} // struct ExampleRow
