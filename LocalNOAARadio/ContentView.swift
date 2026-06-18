//
//  ContentView.swift
//  LocalNOAARadio
//
//  Created by Stewart French on 6/15/26.
//

import SwiftUI


//------------
struct ContentView: View
{
  @State private var audioPlayer = AudioPlayerManager()
  @State private var stationService = NOAAStationService()
  @State private var showManageStations = false
  @State private var showLocationSearch = false
  

          // Computed property for dynamic weather text
  var weatherText: String
  {
    if audioPlayer.isPlaying
    {
      return """
      🔴 LIVE BROADCAST
      
      You are listening to continuous NOAA Weather Radio from the National Weather Service.
      
      This broadcast provides:
      • Current weather conditions
      • Weather forecasts and warnings
      • Severe weather alerts
      • Marine and aviation weather
      • Hydrological information
      
      NOAA Weather Radio is the official voice of the National Weather Service, providing 24/7 weather information for your area.
      
      Note: Stream may be delayed 10-60 seconds due to internet buffering.
      """
    } // if
    else if stationService.closestStation != nil
    {
      let station = stationService.closestStation!
      return """
      📻 Ready to Listen
      
      Station: \(station.callSign)
      Location: \(station.city)
      Frequency: \(station.frequency)
      
      NOAA Weather Radio provides continuous weather information directly from the National Weather Service, including:
      
      • Local forecasts and conditions
      • Severe weather warnings
      • Watches and advisories
      • Marine and fire weather
      • Natural disaster information
      
      Press PLAY to start listening to your local weather radio station.
      """
    } // else if
    else
    {
      return """
      📍 Finding Your Station
      
      Searching for the closest NOAA Weather Radio station to your location...
      
      NOAA Weather Radio (NWR) is a nationwide network of radio stations broadcasting continuous weather information directly from the nearest National Weather Service office.
      
      NWR broadcasts official Weather Service warnings, watches, forecasts and other hazard information 24 hours a day, 7 days a week.
      """
    } // else
  } // weatherText
  

  var body: some View
  {
    VStack(spacing: 20)
    {
              // Header
      VStack(spacing: 8)
      {
        HStack
        {
          Spacer()
          
          Button(action:
          {
            showManageStations = true
          }) // action
          {
            Image(systemName: "gearshape")
              .font(.title2)
              .foregroundStyle(.blue)
          } // Button
          .padding(.trailing)
        } // HStack
        
        Image(systemName: "antenna.radiowaves.left.and.right")
          .font(.system(size: 60))
          .foregroundStyle(.blue)
        
        Text("NOAA Weather Radio")
          .font(.title)
          .fontWeight(.bold)
        
        if let station = stationService.closestStation
        {
          Text(station.city)
            .font(.headline)
            .foregroundStyle(.secondary)
          
          Text(station.frequency)
            .font(.subheadline)
            .foregroundStyle(.secondary)
        } // if
      } // VStack
      .padding(.top)
      
              // Location status with search button
      VStack(spacing: 8)
      {
        Text(stationService.locationStatus)
          .font(.caption)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
        
        Button(action:
        {
          showLocationSearch = true
        }) // action
        {
          HStack(spacing: 6)
          {
            Image(systemName: "magnifyingglass")
              .font(.caption)
            Text("Search Different Location")
              .font(.caption)
          } // HStack
          .foregroundStyle(.blue)
        } // Button
      } // VStack
      .padding(.horizontal)
      
              // Play/Pause and Next Station buttons
      HStack(spacing: 12)
      {
                // Play/Pause button
        Button(action:
        {
          if let station = stationService.closestStation,
             let url = station.url
          {
            audioPlayer.togglePlayPause(url: url)
          } // if
        }) // action
        {
          HStack
          {
            Image(systemName: audioPlayer.isPlaying ? "pause.fill" : "play.fill")
              .font(.title2)
            Text(audioPlayer.isPlaying ? "Pause" : "Play")
              .font(.headline)
          } // HStack
          .frame(maxWidth: .infinity)
          .padding()
          .background(stationService.closestStation?.hasStream == true ? Color.blue : Color.gray)
          .foregroundColor(.white)
          .cornerRadius(12)
        } // Button
        .disabled(stationService.closestStation?.hasStream != true)
        
                // Next Station button
        Button(action:
        {
          if let nextStation = stationService.skipToNextStation(),
             let url = nextStation.url
          {
            if audioPlayer.isPlaying
            {
              audioPlayer.play(url: url)
            } // if
          } // if
        }) // action
        {
          VStack(spacing: 4)
          {
            Image(systemName: "forward.fill")
              .font(.title2)
            Text("Next")
              .font(.caption)
          } // VStack
          .frame(width: 80)
          .padding()
          .background(stationService.sortedStreamableStations.count > 1 ? Color.blue : Color.gray)
          .foregroundColor(.white)
          .cornerRadius(12)
        } // Button
        .disabled(stationService.sortedStreamableStations.count <= 1)
      } // HStack
      .padding(.horizontal)
      
              // Status text
      Text(audioPlayer.statusText)
        .font(.subheadline)
        .foregroundStyle(.secondary)
      
              // Debug: Show stream URL
      if let station = stationService.closestStation,
         let streamURL = station.streamURL
      {
        Text("Stream: \(streamURL)")
          .font(.caption2)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
          .padding(.horizontal)
      } // if
      
              // Scrollable weather information view
      ScrollView
      {
        Text(weatherText)
          .font(.body)
          .padding()
          .frame(maxWidth: .infinity,
                 alignment: .leading)
      } // ScrollView
      .background(Color(.systemGray6))
      .cornerRadius(12)
      .padding(.horizontal)
      
      Spacer()
    } // VStack
    .onAppear
    {
      stationService.requestLocation()
      
              // Set up stream failure callback
      audioPlayer.onStreamFailure =
      {
        print("🔄 Stream failed, trying next closest station...")
        if let nextStation = stationService.tryNextClosestStation(),
           let url = nextStation.url
        {
          print("▶️ Auto-switching to: \(nextStation.city)")
          audioPlayer.play(url: url)
        } // if
        else
        {
          print("⚠️ No more stations available")
        } // else
      } // onStreamFailure
    } // onAppear
    .onChange(of: stationService.closestStation)
    { oldValue, newValue in
              // Handle station changes
      if let station = newValue,
         let url = station.url
      {
                // If playing, stop and switch to new stream
        if audioPlayer.isPlaying
        {
          print("🔄 Location changed while playing, switching streams...")
          audioPlayer.stop()
          audioPlayer.play(url: url)
        } // if
                // If not playing, auto-play on initial load only
        else if oldValue == nil
        {
          print("▶️ Initial station found, auto-playing...")
          audioPlayer.play(url: url)
        } // else if
      } // if
    } // onChange
    .onDisappear
    {
              // Stop audio when view disappears (app is closed/terminated)
      audioPlayer.stop()
    } // onDisappear
    .sheet(isPresented: $showManageStations)
    {
      ManageStationsView(customStationManager: $stationService.customStationManager)
    } // sheet
    .sheet(isPresented: $showLocationSearch)
    {
      LocationSearchView(stationService: $stationService)
    } // sheet
  } // body

} // struct ContentView


#Preview
{
  ContentView()
} // Preview
