//
//  ManageStationsView.swift
//  LocalNOAARadio
//
//  Created by Stewart French on 6/15/26.
//

import SwiftUI


//------------
struct ManageStationsView: View
{
  @Environment(\.dismiss) var dismiss
  @Binding var customStationManager: CustomStationManager
  @State private var showAddStation = false
  

  var body: some View
  {
    NavigationView
    {
      List
      {
        if customStationManager.customStations.isEmpty
        {
          Section
          {
            VStack(spacing: 12)
            {
              Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.system(size: 50))
                .foregroundStyle(.secondary)
              
              Text("No Custom Stations")
                .font(.headline)
              
              Text("Add your own NOAA weather radio stations with custom streaming URLs")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            } // VStack
            .frame(maxWidth: .infinity)
            .padding()
          } // Section
        } // if
        else
        {
          Section(header: Text("Custom Stations (\(customStationManager.customStations.count))"))
          {
            ForEach(customStationManager.customStations.indices,
                    id: \.self)
            { index in
              VStack(alignment: .leading,
                     spacing   : 4)
              {
                Text(customStationManager.customStations[index].callSign)
                  .font(.headline)
                
                Text(customStationManager.customStations[index].city)
                  .font(.subheadline)
                  .foregroundStyle(.secondary)
                
                Text(customStationManager.customStations[index].frequency)
                  .font(.caption)
                  .foregroundStyle(.secondary)
              } // VStack
            } // ForEach
            .onDelete(perform: deleteStations)
          } // Section
          
          Section
          {
            Button(role: .destructive)
            {
              deleteAllStations()
            } // Button
            label:
            {
              HStack
              {
                Image(systemName: "trash")
                Text("Delete All Custom Stations")
              } // HStack
            } // label
          } // Section
        } // else
      } // List
      .navigationTitle("Manage Stations")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar
      {
        ToolbarItem(placement: .cancellationAction)
        {
          Button("Done")
          {
            dismiss()
          } // Button
        } // ToolbarItem
        
        ToolbarItem(placement: .primaryAction)
        {
          Button(action:
          {
            showAddStation = true
          }) // action
          {
            Label("Add Station",
                  systemImage: "plus")
          } // Button
        } // ToolbarItem
      } // toolbar
      .sheet(isPresented: $showAddStation)
      {
        AddCustomStationView(customStationManager: $customStationManager)
      } // sheet
    } // NavigationView
  } // body


  //----
          // Delete stations at specified indices
  func deleteStations(at offsets: IndexSet)
  {
    for index in offsets
    {
      customStationManager.deleteStation(at: index)
    } // for
  } // deleteStations


  //----
          // Delete all custom stations
  func deleteAllStations()
  {
    customStationManager.deleteAllStations()
  } // deleteAllStations

} // struct ManageStationsView
