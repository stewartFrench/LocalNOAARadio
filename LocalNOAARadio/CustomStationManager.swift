//
//  CustomStationManager.swift
//  LocalNOAARadio
//
//  Created by Stewart French on 6/15/26.
//

import Foundation
import CoreLocation


//------------
        // Manager for user-created custom NOAA stations
@Observable
class CustomStationManager
{
  var customStations: [NOAAStation] = []
  
  private let userDefaultsKey = "customNOAAStations"
  

  init()
  {
    loadCustomStations()
  } // init


  //----
          // Load custom stations from UserDefaults
  private func loadCustomStations()
  {
    guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else
    {
      return
    } // guard
    
    do
    {
      let decoder = JSONDecoder()
      customStations = try decoder.decode([NOAAStation].self,
                                          from: data)
      print("✅ Loaded \(customStations.count) custom stations")
    } // do
    catch
    {
      print("❌ Failed to load custom stations: \(error)")
    } // catch
  } // loadCustomStations


  //----
          // Save custom stations to UserDefaults
  private func saveCustomStations()
  {
    do
    {
      let encoder = JSONEncoder()
      let data = try encoder.encode(customStations)
      UserDefaults.standard.set(data,
                                forKey: userDefaultsKey)
      print("✅ Saved \(customStations.count) custom stations")
    } // do
    catch
    {
      print("❌ Failed to save custom stations: \(error)")
    } // catch
  } // saveCustomStations


  //----
          // Add a new custom station
  func addStation(callSign : String,
                  frequency: String,
                  city     : String,
                  latitude : Double,
                  longitude: Double,
                  streamURL: String?)
  {
    let newStation = NOAAStation(callSign : callSign,
                                  frequency: frequency,
                                  city     : city,
                                  latitude : latitude,
                                  longitude: longitude,
                                  streamURL: streamURL)
    
    customStations.append(newStation)
    saveCustomStations()
  } // addStation


  //----
          // Delete a custom station
  func deleteStation(at index: Int)
  {
    guard index >= 0 && index < customStations.count else { return }
    customStations.remove(at: index)
    saveCustomStations()
  } // deleteStation


  //----
          // Delete all custom stations
  func deleteAllStations()
  {
    customStations.removeAll()
    saveCustomStations()
  } // deleteAllStations

} // class CustomStationManager
