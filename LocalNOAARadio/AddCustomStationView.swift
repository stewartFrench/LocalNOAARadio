//
//  AddCustomStationView.swift
//  LocalNOAARadio
//
//  Created by Stewart French on 6/15/26.
//

import SwiftUI


//------------
struct AddCustomStationView: View
{
  @Environment(\.dismiss) var dismiss
  @Binding var customStationManager: CustomStationManager
  
  @State private var callSign = ""
  @State private var frequency = ""
  @State private var city = ""
  @State private var latitude = ""
  @State private var longitude = ""
  @State private var streamURL = ""
  @State private var showError = false
  @State private var errorMessage = ""
  

  var body: some View
  {
    NavigationView
    {
      Form
      {
        Section
        {
          VStack(alignment: .leading, spacing: 8)
          {
            Text("Add a Custom NOAA Station")
              .font(.headline)
            
            Text("If you know of a NOAA weather radio station with a streaming URL, you can add it here. The app will include your custom station when determining the closest station to stream from your location.")
              .font(.subheadline)
              .foregroundStyle(.secondary)
              .fixedSize(horizontal: false, vertical: true)
          } // VStack
          .padding(.vertical, 4)
        } // Section
        
        Section(header: Text("Enter Station Information"))
        {
          TextField("Call Sign (e.g., KEC56)",
                    text: $callSign)
            .autocapitalization(.allCharacters)
          
          TextField("Frequency (e.g., 162.400 MHz)",
                    text: $frequency)
          
          TextField("City, State (e.g., Dallas, TX)",
                    text: $city)
        } // Section
        
        Section(header: Text("Enter Station Location Coordinates"))
        {
          TextField("Latitude (e.g., 32.7767)",
                    text: $latitude)
            .keyboardType(.decimalPad)
          
          TextField("Longitude (e.g., -96.7970)",
                    text: $longitude)
            .keyboardType(.decimalPad)
          
          Text("Tip: Long-press on Apple Maps to get coordinates")
            .font(.caption)
            .foregroundStyle(.secondary)
        } // Section
        
        Section(header: Text("Stream URL"))
        {
          TextField("Enter Stream URL (e.g., https://...)",
                    text: $streamURL)
            .keyboardType(.URL)
            .autocapitalization(.none)
          
          Text("Enter the complete streaming URL for the station")
            .font(.caption)
            .foregroundStyle(.secondary)
        } // Section
      } // Form
      .navigationTitle("Add Custom Station")
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
        
        ToolbarItem(placement: .confirmationAction)
        {
          Button("Add")
          {
            addStation()
          } // Button
          .disabled(!isValidInput)
        } // ToolbarItem
      } // toolbar
      .alert("Error",
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
          // Validate input fields
  var isValidInput: Bool
  {
    !callSign.isEmpty &&
    !frequency.isEmpty &&
    !city.isEmpty &&
    !latitude.isEmpty &&
    !longitude.isEmpty &&
    !streamURL.isEmpty
  } // isValidInput


  //----
          // Add the custom station
  func addStation()
  {
    guard let lat = Double(latitude),
          let lon = Double(longitude) else
    {
      errorMessage = "Invalid coordinates. Please enter valid numbers."
      showError = true
      return
    } // guard
    
    guard lat >= -90 && lat <= 90 else
    {
      errorMessage = "Latitude must be between -90 and 90."
      showError = true
      return
    } // guard
    
    guard lon >= -180 && lon <= 180 else
    {
      errorMessage = "Longitude must be between -180 and 180."
      showError = true
      return
    } // guard
    
    customStationManager.addStation(callSign : callSign,
                                    frequency: frequency,
                                    city     : city,
                                    latitude : lat,
                                    longitude: lon,
                                    streamURL: streamURL)
    
    dismiss()
  } // addStation

} // struct AddCustomStationView
