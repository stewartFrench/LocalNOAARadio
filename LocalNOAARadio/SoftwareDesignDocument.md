# LocalNOAARadio - Software Design Document

## 1. Introduction

### 1.1 Purpose
This document provides a comprehensive technical overview of
LocalNOAARadio, an iOS application that streams NOAA Weather Radio
broadcasts from the closest available station to the user's location.

### 1.2 Scope
LocalNOAARadio is a native iOS application built with SwiftUI that:
- Automatically detects user location
- Identifies the closest NOAA weather radio station with streaming
  capability
- Streams live NOAA weather broadcasts
- Supports custom station management
- Enables location-based "what if" searches
- Provides information about non-streamable stations that may be
  closer

### 1.3 Definitions and Acronyms
- **NOAA**: National Oceanic and Atmospheric Administration
- **NWR**: NOAA Weather Radio
- **AVFoundation**: Apple's framework for audiovisual media
- **CoreLocation**: Apple's framework for location services
- **MapKit**: Apple's framework for maps and location search

## 2. System Overview

### 2.1 System Context
LocalNOAARadio is a standalone iOS application that:
- Uses device GPS for location detection
- Streams audio from internet-based NOAA radio sources
- Operates in foreground and background modes
- Persists user preferences locally

### 2.2 System Architecture

The application follows the Model-View-ViewModel (MVVM) pattern using
SwiftUI's modern declarative approach with the `@Observable` macro for
state management.

```
┌─────────────────────────────────────────────────────┐
│                   User Interface                    │
│(ContentView, LocationSearchView, ManageStationsView)│
└────────────────┬────────────────────────────────────┘
                 │
                 ├──────────────────┬─────────────────┐
                 │                  │                 │
         ┌───────▼──────┐  ┌────────▼────────┐  ┌─────▼─────────┐
         │AudioPlayer   │  │NOAAStation      │  │CustomStation  │
         │Manager       │  │Service          │  │Manager        │
         └───────┬──────┘  └────────┬────────┘  └─────┬─────────┘
                 │                  │                 │
         ┌───────▼──────┐  ┌────────▼────────┐  ┌─────▼─────────┐
         │AVFoundation  │  │CoreLocation     │  │UserDefaults   │
         │AVPlayer      │  │CLLocationMgr    │  │               │
         └──────────────┘  └────────┬────────┘  └───────────────┘
                                    │
                           ┌────────▼────────┐
                           │NOAAStations.json│
                           └─────────────────┘
```

## 3. Architectural Design

### 3.1 Design Patterns

#### 3.1.1 Observable Pattern

Uses Swift's `@Observable` macro for reactive state management:
- `AudioPlayerManager`: Manages audio playback state
- `NOAAStationService`: Manages location and station data
- `CustomStationManager`: Manages user-added stations

#### 3.1.2 Delegation Pattern

Implements `CLLocationManagerDelegate` for location updates

#### 3.1.3 Repository Pattern

JSON-based station database loaded at runtime

### 3.2 Component Architecture

#### 3.2.1 Presentation Layer
**Views (SwiftUI)**:

- `ContentView`: Main application interface
- `LocationSearchView`: Location search functionality
- `AddCustomStationView`: Form for adding custom stations
- `ManageStationsView`: List management for custom stations

#### 3.2.2 Business Logic Layer
**Services**:

- `NOAAStationService`: Location detection and station selection
- `AudioPlayerManager`: Audio streaming and playback control
- `CustomStationManager`: Persistence and management of custom
   stations

#### 3.2.3 Data Layer
**Models**:

- `NOAAStation`: Represents a weather radio station
- JSON database: Persistent station information

## 4. Detailed Design

### 4.1 Data Models

#### 4.1.1 NOAAStation
```swift

struct NOAAStation: Codable, Equatable
{
  let  callSign: String  // Station identifier (e.g., "KEC56")
  let frequency: String  // Broadcast frequency (e.g., "162.400 MHz")
  let      city: String  // Location (e.g., "Dallas-Fort Worth, TX")
  let  latitude: Double  // Geographic latitude
  let longitude: Double  // Geographic longitude
  let streamURL: String? // Optional streaming URL

  var  location: CLLocationCoordinate2D
                         // Computed coordinate
  var       url: URL?    // Computed URL object
  var hasStream: Bool    // Stream availability check
}
```

**Design Rationale**:

- `streamURL` is optional to support stations without internet streams
- Computed properties reduce data redundancy
- `Equatable` conformance enables SwiftUI change detection
- `Codable` conformance enables JSON serialization

### 4.2 Service Components

#### 4.2.1 NOAAStationService

**Responsibilities**:

- Request and manage location permissions
- Track device location
- Find closest streamable station
- Track closest non-streamable station (if closer)
- Manage custom stations integration

**Key Methods**:

```swift
func requestLocation()
func findClosestStation(at location: CLLocation)
func skipToNextStation() -> NOAAStation?
private func findClosestStationInternal(to location: CLLocation)
```

**State Properties**:
- `closestStation: NOAAStation?` - Closest streamable station
- `closestNonStreamStation: NOAAStation?` - Closest overall station
   (if no stream)
- `currentLocation: CLLocation?` - Current device location
- `locationStatus: String` - User-facing status message
- `customStationManager: CustomStationManager` - Custom station
   integration
- `sortedStreamableStations: [NOAAStation]` - All streamable stations
   sorted by distance (used for "Next Closest" feature)
- `currentStationIndex: Int` - Index in sorted list for cycling through
   stations

**Algorithm: findClosestStationInternal**
```
1. Initialize tracking variables:
   - nearestStreamableStation, shortestStreamableDistance
   - nearestOverallStation, shortestOverallDistance

2. Combine built-in stations + custom stations

3. For each station:
   a. Calculate distance from current location
   b. Update nearestOverallStation if closer
   c. If station has stream AND closer: update
      nearestStreamableStation

4. Set closestStation = nearestStreamableStation

5. If nearestOverallStation is closer than nearestStreamableStation:
   a. Set closestNonStreamStation = nearestOverallStation
   b. Update locationStatus with both stations' information

6. Else: Clear closestNonStreamStation
```

**Distance Calculation**:

Uses `CLLocation.distance(from:)` which calculates geodesic distance
(great circle distance) in meters, then converts to
miles (÷ 1609.34).

**Algorithm: skipToNextStation**
```
1. Check if sortedStreamableStations has at least 2 stations
2. If yes:
   a. Increment currentStationIndex
   b. If index >= array count: wrap to 0 (circular)
   c. Set closestStation = sortedStreamableStations[currentStationIndex]
   d. Return new closestStation
3. If no: return nil
```

This algorithm allows users to cycle through all available streamable
stations in order of distance from their location. It's useful for:
- Trying alternative stations when primary stream fails
- Exploring nearby station coverage
- Comparing broadcast quality between stations

#### 4.2.2 AudioPlayerManager

**Responsibilities**:

- Configure audio session for playback
- Manage AVPlayer lifecycle
- Handle play/pause/stop operations
- Track playback state
- Switch streams when station changes

**Key Methods**:

```swift
func play(url: URL)
func stop()
func togglePlayPause(url: URL)
```

**Audio Session Configuration**:

```swift
Category: .playback
Mode: .spokenAudio
Options: []
```
This configuration:

- Enables background audio
- Optimizes for voice content
- Respects system volume
- Continues during screen lock

**Stream Switching Logic**:

```
1. If player exists:
   a. Get current player's URL
   b. If same URL as requested: resume playback
   c. If different URL: stop current player, create new one

2. If no player exists: create new player

3. Create AVPlayerItem with new URL
4. Create AVPlayer with player item
5. Start playback
6. Update state (isPlaying = true)
```

#### 4.2.3 CustomStationManager

**Responsibilities**:

- Persist custom stations to UserDefaults
- Load custom stations on initialization
- Add new custom stations
- Delete custom stations
- Provide array of custom stations to NOAAStationService

**Storage Key**: `"customStations"`

**Persistence Format**: JSON array serialized to UserDefaults

**Key Methods**:

```swift
func addStation( callSign: String,
                frequency: String,
                     city: String,
                 latitude: Double,
                longitude: Double,
                streamURL: String )  // Now required, not optional
func deleteStation( at index: Int )
func deleteAllStations()
private func saveCustomStations()
private func loadCustomStations()
```

**Design Change**: The `streamURL` parameter is now required (String instead
of String?) to ensure all custom stations have streaming capability. This aligns
with the form validation in AddCustomStationView.

### 4.3 User Interface Design

#### 4.3.1 ContentView

**Layout Structure**:

```
VStack
├── Header
│   ├── Settings gear button (top-right)
│   ├── Antenna icon
│   ├── "NOAA Weather Radio" title
│   ├── Station city (if available)
│   └── Station frequency (if available)
├── Location Status
│   └── Status text (multi-line, centered)
├── Action Buttons (HStack - side by side)
│   ├── Enter Location Button (Blue)
│   │   ├── Magnifying glass icon
│   │   └── "Enter\nLocation" text
│   ├── Play/Pause Button (Green when available)
│   │   ├── Play/Pause icon
│   │   ├── "Play" or "Pause" text
│   │   ├── Enabled only if station has stream
│   │   └── Gray background when unavailable
│   └── Next Closest Button (Blue when available)
│       ├── Forward icon
│       ├── "Next\nClosest" text
│       ├── Enabled only if multiple streamable stations
│       └── Gray background when unavailable
├── Status Text
│   └── Current playback status
├── Debug Info
│   └── Stream URL (for development)
└── ScrollView (minHeight: 300pt)
    └── Dynamic weather information text
```

**Dynamic Text States**:

1. **Playing**: Shows "LIVE BROADCAST" with broadcast information
2. **Ready**: Shows "Ready to Listen" with station details
3. **Searching**: Shows " Finding Your Station" with NWR information

**State Management**:

- `@State private var audioPlayer`
- `@State private var stationService`
- `@State private var showManageStations`
- `@State private var showLocationSearch`

**Button Styling**:

- All buttons: Equal width using `.frame(maxWidth: .infinity, minHeight: 50)`
- Layout: VStack with icon above text, `.padding()`, `.cornerRadius(12)`
- Enter Location: Blue background, always enabled
- Play/Pause: Green when available (gray when disabled)
- Next Closest: Blue when available (gray when disabled)
- Spacing: 12pt between buttons in HStack

**Lifecycle Hooks**:

```swift
.onAppear { stationService.requestLocation() }
.onChange(of: stationService.closestStation)
    { autoplay if stream available, or skip to next if no stream }
.onDisappear { audioPlayer.stop() }
```

**Auto-play Logic**:

When `closestStation` changes:

1. Check if new station exists and has stream URL
2. If yes: automatically start playback
3. If no stream: automatically skip to next closest streamable station

**Next Station Feature**:

The "Next Closest" button allows users to skip to the next nearest streamable
station. This is useful when the closest station's stream is unavailable or
the user wants to check alternative stations. The button:
- Cycles through stations sorted by distance
- Only enabled when multiple streamable stations are available
- Automatically starts playback if audio is already playing

#### 4.3.2 LocationSearchView

**Purpose**: Enable users to search for NOAA stations at any US location

**Search Implementation**:

Uses `MKLocalSearch` API (iOS 26+):

```swift
let request = MKLocalSearch.Request()
request.naturalLanguageQuery = searchText
request.resultTypes = [.address, .pointOfInterest]

let search = MKLocalSearch(request: request)
search.start { response, error in
  // Process first result
  // Update stationService with new location
}
```

**UI Components**:

- Search text field
- Search button
- Results list showing found stations
- Distance display for each station

#### 4.3.3 AddCustomStationView

**Purpose**: Form interface for adding custom NOAA stations with streaming URLs

**Instructional Header**:

Displays prominent instructions at the top of the form:
- **Title**: "Add a Custom NOAA Station"
- **Description**: Explains that users can add NOAA weather radio stations
  with streaming URLs, and that the app will include custom stations when
  determining the closest station to stream from their location

**Form Sections**:

1. **Station Information**
   - Call Sign (uppercase, required)
   - Frequency (required)
   - City, State (required)

2. **Location Coordinates**
   - Latitude (decimal, -90 to 90, required)
   - Longitude (decimal, -180 to 180, required)
   - Helper tip for getting coordinates from Apple Maps

3. **Stream URL (Required)**
   - URL text field (http/https, required)
   - Helper text: "Enter the complete streaming URL for the station"
   - **Design Change**: Stream URL is now required (was optional)
   - This ensures custom stations are only added if they have streaming capability

**Validation**:

```swift
isValidInput: Bool
{
  !callSign.isEmpty &&
  !frequency.isEmpty &&
  !city.isEmpty &&
  !latitude.isEmpty &&
  !longitude.isEmpty &&
  !streamURL.isEmpty  // Now required
}
```

**Coordinate Validation**:

- Latitude: -90° ≤ lat ≤ 90°
- Longitude: -180° ≤ lon ≤ 180°

**UI Design**:

- Clear instructional section at top with headline and explanatory text
- Organized into logical sections with headers
- Inline validation feedback
- "Add" button disabled until all required fields are valid
- Cancel and Add toolbar buttons for navigation

#### 4.3.4 ManageStationsView

**Purpose**: List and manage custom stations

**Features**:

- List of custom stations with swipe-to-delete
- "Delete All Custom Stations" button
- Displays: call sign, city, frequency for each station

## 5. Data Management

### 5.1 Station Database (NOAAStations.json)

**Format**:

```json
[
  {
    "callSign": "KEC56",
    "frequency": "162.550 MHz",
    "city": "Dallas-Fort Worth, TX",
    "latitude": 32.7767,
    "longitude": -96.7970,
    "streamURL": "https://radio.weatherusa.net/NWR/KEC56_3.mp3"
  },
  {
    "callSign": "KIH41",
    "frequency": "162.400 MHz",
    "city": "Lexington, KY",
    "latitude": 38.0406,
    "longitude": -84.5037,
    "streamURL": null
  }
]
```

**Current Coverage**:

- 185 stations with streaming URLs (all 50 states)
- 10 Kentucky stations without streaming (demonstrating feature)
- Total: 195 stations

**Loading Process**:

1. Locate NOAAStations.json in app bundle
2. Load data as Data object
3. Decode JSON using JSONDecoder
4. Store in memory as [NOAAStation] array

### 5.2 User Preferences (UserDefaults)

**Storage**:

- Key: `"customStations"`
- Format: JSON-encoded array of NOAAStation objects

**Persistence Lifecycle**:

1. **Load**: On CustomStationManager initialization
2. **Save**: After add/delete operations
3. **Access**: Real-time through customStations array

## 6. External Dependencies

### 6.1 iOS Frameworks

#### 6.1.1 SwiftUI

- **Purpose**: User interface framework
- **Usage**: All views, navigation, sheets, state management
- **Minimum Version**: iOS 17.0+

#### 6.1.2 AVFoundation

- **Purpose**: Audio playback
- **Components Used**:
  - `AVPlayer`: Media playback
  - `AVPlayerItem`: Playback resource
  - `AVAudioSession`: Audio session configuration
- **Audio Format**: Streaming MP3 over HTTP/HTTPS

#### 6.1.3 CoreLocation

- **Purpose**: Location services
- **Components Used**:
  - `CLLocationManager`: Location updates
  - `CLLocation`: Geographic coordinates
  - `CLLocationManagerDelegate`: Location callbacks
- **Permissions**: "When In Use" location access

#### 6.1.4 MapKit

- **Purpose**: Location search
- **Components Used**:
  - `MKLocalSearch`: Natural language location search
  - `MKLocalSearch.Request`: Search configuration
- **Usage**: Converting place names to coordinates

#### 6.1.5 Foundation

- **Purpose**: Core utilities
- **Components Used**:
  - `JSONDecoder`: JSON parsing
  - `UserDefaults`: Data persistence
  - `Bundle`: Resource access
  - `URL`: Network resource handling

### 6.2 External Services

#### 6.2.1 Weather Radio Streaming Services

- **weatherusa.net**: Primary streaming source
- **wxradio.org**: Alternative streaming source
- **Protocol**: HTTP/HTTPS streaming (typically MP3)
- **Availability**: Public, no authentication required

## 7. Security and Privacy

### 7.1 Location Privacy

**Permission Model**:

- "When In Use" authorization (not "Always")
- Location only accessed when app is active
- Clear purpose string in Info.plist

**Info.plist Entry**:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Location is used to find the closest NOAA weather radio station to you.</string>
```

**Data Handling**:

- Location data never transmitted to external servers
- Only used for local distance calculations
- Not persisted beyond current session

### 7.2 Network Security

**Stream URLs**:

- Prefer HTTPS over HTTP where available
- No user authentication required
- Public NOAA weather broadcasts

### 7.3 Data Privacy

**User Data**:

- Custom stations stored locally only (UserDefaults)
- No analytics or tracking
- No personal information collected
- No third-party data sharing

## 8. Performance Considerations

### 8.1 Location Services

**Accuracy Configuration**:

```swift
desiredAccuracy = kCLLocationAccuracyKilometer
```
- Trade-off: Battery life vs. precision
- 1km accuracy sufficient for station selection
- Stops location updates after first fix

### 8.2 Station Distance Calculation

**Complexity**: O(n) where n = number of stations
**Optimization**: Single pass through all stations
**Performance**: Sub-second for ~200 stations

### 8.3 Audio Streaming

**Buffering**: Handled by AVPlayer automatically
**Latency**: 10-60 seconds behind live broadcast (typical for internet radio)
**Background Playback**: Enabled via audio session configuration

### 8.4 Memory Management

**Station Database**: Loaded once at launch, kept in memory (~100KB)
**Custom Stations**: Small JSON in UserDefaults (typically <10KB)
**Audio Buffer**: Managed by AVFoundation

## 9. Error Handling

### 9.1 Location Errors

**Scenarios**:

1. **User Denies Permission**
   - Display: "Location access denied. Using default station."
   - Fallback: Select first station in database

2. **Location Unavailable**
   - Display error message with description
   - Fallback: Select first station in database

3. **Location Timeout**
   - CLLocationManager handles internally
   - Falls through to didFailWithError delegate method

### 9.2 Audio Errors

**Scenarios**:
1. **Invalid Stream URL**
   - AVPlayer fails to create AVPlayerItem
   - Status remains "Ready to play"

2. **Network Failure**
   - AVPlayer item fails during playback
   - User sees stopped state
   - Can retry by pressing Play again

3. **Stream Unavailable**
   - AVPlayer reports item failure
   - No automatic retry (user must manually retry)

### 9.3 Data Loading Errors

**Station Database**:

```swift
guard let url = Bundle.main.url(forResource: "NOAAStations", withExtension: "json")
else {
  print("❌ Failed to locate NOAAStations.json")
  return
}
```
- Critical error: App cannot function without station data
- Logged to console for debugging

**Custom Stations**:

```swift
catch {
  print("❌ Failed to load custom stations: \(error)")
  customStations = []
}
```
- Non-critical: App continues with empty custom stations array

## 10. Configuration and Settings

### 10.1 App Configuration (Info.plist)

**Required Keys**:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Location is used to find the closest NOAA weather radio station to you.</string>

<key>UIBackgroundModes</key>
<array>
  <string>audio</string>
</array>
```

### 10.2 Audio Session Configuration

**Category**: `.playback`

- Allows background audio
- Continues during screen lock
- Does not mix with other audio by default

**Mode**: `.spokenAudio`

- Optimized for voice/speech content
- Reduces audio processing overhead

### 10.3 Build Settings

**Target**: iOS 17.0+
**Language**: Swift 6.0+
**Architecture**: Universal (iPhone only, portrait orientation)

## 11. Testing Considerations

### 11.1 Unit Testing Opportunities

**NOAAStationService**:

- Distance calculation accuracy
- Station selection logic (closest streamable vs. closest overall)
- Location status message generation
- Custom station integration

**CustomStationManager**:

- Add/delete operations
- Persistence (save/load)
- Data validation

**AudioPlayerManager**:

- State transitions (playing/stopped)
- URL switching logic

### 11.2 Integration Testing

**Location Flow**:

1. Grant location permission
2. Verify closest station selected
3. Verify auto-play initiates

**Search Flow**:

1. Search for location
2. Verify station selection updates
3. Verify audio switches streams

**Custom Station Flow**:

1. Add custom station
2. Verify persistence
3. Verify inclusion in station selection

### 11.3 UI Testing

**Scenarios**:

- Launch app → verify auto-play
- Press pause → verify playback stops
- Search location → verify station changes
- Add custom station → verify appears in list
- Delete custom station → verify removed

## 12. Deployment

### 12.1 App Store Submission

**Requirements**:

- App icon (all sizes)
- Privacy policy (if collecting data beyond location)
- Screenshots for multiple device sizes
- Description and keywords

**Privacy Declarations**:

- Location usage: For finding closest station
- Network usage: For streaming audio

### 12.2 Versioning

**Current Version**: 1.0
**Versioning Scheme**: Semantic (major.minor.patch)

**Version History**:

- 1.0: Initial release
  - Auto-location detection
  - Streaming playback
  - Custom stations with required streaming URLs
  - Location search
  - Non-streamable station awareness
  - Three-button action layout (Enter Location, Play/Pause, Next Closest)
  - Automatic station skipping when primary station unavailable
  - Next Station cycling feature
  - Improved ScrollView sizing for better content visibility
  - Instructional header in Add Custom Station form

## 13. Future Enhancements

### 13.1 Potential Features

1. **Expanded Station Database**

   - Add all 1000+ NOAA transmitters
   - Include transmitter tower locations
   - Coverage area visualization

2. **Favorites System**

   - Quick access to frequently used stations
   - Manual station selection override

3. **Alerts and Notifications**

   - Push notifications for severe weather
   - Background monitoring
   - Alert audio interruption

4. **Siri Integration**

   - "Hey Siri, play weather radio"
   - "Hey Siri, what's the weather alert?"

5. **CarPlay Support**

   - Dashboard integration
   - Simplified interface for driving

6. **Widget Support**

   - Home screen widget showing current conditions
   - Quick play/pause control

7. **Recording Features**

   - Record alerts for later playback
   - Historical alert archive

8. **Offline Mode**

   - Download and cache recent broadcasts
   - Offline station database

### 13.2 Technical Improvements

1. **Caching**

   - Cache location results
   - Reduce redundant distance calculations

2. **Analytics**

   - Usage statistics (privacy-respecting)
   - Error reporting
   - Stream reliability metrics

3. **Accessibility**

   - VoiceOver optimization
   - Dynamic Type support
   - High contrast mode

4. **Localization**

   - Multi-language support
   - International weather radio systems

## 14. Code Formatting Standards

The project follows strict formatting rules defined in `format_rules.md`:

### 14.1 Key Standards

**Braces**: Always on separate lines

```swift
// Correct
func example()
{
  if condition
  {
    // code
  } // if
} // example

// Incorrect
func example() {
  if condition {
    // code
  }
}
```

**Indentation**: 2 spaces (not tabs)

**Comments**: After closing braces

```swift
} // if
} // for
} // func functionName
} // struct StructName
```

**Parameter Alignment**: Colons aligned vertically

```swift
func example(parameter1: String,
             parameter2: Int,
             parameter3: Bool)
```

**Line Length**: Maximum 80-100 characters (flexible)

## 15. Appendices

### 15.1 File Structure
```
LocalNOAARadio/
├── LocalNOAARadio/
│   ├── LocalNOAARadioApp.swift          # App entry point
│   ├── ContentView.swift                # Main UI
│   ├── LocationSearchView.swift         # Location search UI
│   ├── AddCustomStationView.swift       # Add station form
│   ├── ManageStationsView.swift         # Station management UI
│   ├── NOAAStationService.swift         # Station & location logic
│   ├── AudioPlayerManager.swift         # Audio playback logic
│   ├── CustomStationManager.swift       # Custom station persistence
│   ├── NOAAStations.json                # Station database
│   ├── Info.plist                       # App configuration
│   ├── format_rules.md                  # Code formatting standards
│   └── Assets.xcassets/
│       └── AppIcon.appiconset/          # App icons
└── LocalNOAARadio.xcodeproj/            # Xcode project
```

### 15.2 Key Algorithms

#### Distance Calculation

Uses CoreLocation's built-in geodesic distance:

```swift
let distance = userLocation.distance(from: stationLocation)
// Returns meters along Earth's surface (great circle distance)
let miles = distance / 1609.34
```

#### Station Selection Algorithm

```
Input: User location L, Station set S
Output: Closest streamable station Ss, Closest overall station So

1. Let Ss = null, Ds = ∞
2. Let So = null, Do = ∞

3. For each station s in S:
   a. Calculate d = distance(L, s)
   b. If d < Do:
      - So = s
      - Do = d
   c. If s.hasStream AND d < Ds:
      - Ss = s
      - Ds = d

4. Return (Ss, So)
```

### 15.3 State Diagram

```
[App Launch] → [Request Location]
                      ↓
              [Location Granted?]
                ↙          ↘
              YES           NO
               ↓             ↓
    [Find Closest Station] [Use Default]
               ↓
    [Station Found with Stream?]
        ↙              ↘
       YES              NO
        ↓               ↓
    [Auto Play]   [Show No Stream Message]
        ↓
    [Playing State]
        ↓
    [User Actions: Pause/Search/Settings]
```

### 15.4 Network Diagram

```
┌──────────────┐
│   iPhone     │
│ LocalNOAAApp │
└──────┬───────┘
       │
       │ HTTPS Streaming
       ↓
┌──────────────────────┐
│  Weather Radio CDN   │
│ - weatherusa.net     │
│ - wxradio.org        │
└──────┬───────────────┘
       │
       │ Origination
       ↓
┌──────────────────────┐
│  NOAA Transmitters   │
│  (1000+ locations)   │
└──────────────────────┘
```

---

## Document Revision History

| Version | Date       | Author          | Changes                           |
|---------|------------|-----------------|-----------------------------------|
| 1.0     | 2026-06-16 | Claude Sonnet   | Initial comprehensive SDD         |
| 1.1     | 2026-06-20 | Claude Sonnet   | Updated UI design documentation for three-button layout, Next Station feature, improved ScrollView sizing, and required streaming URLs for custom stations |

---

**End of Document**
