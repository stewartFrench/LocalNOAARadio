# LocalNOAARadio - Software Design Document v2.0

## 1. Introduction

### 1.1 Purpose
This document provides a comprehensive technical overview of LocalNOAARadio, an iOS application that provides real-time NOAA weather forecasts and alerts with text-to-speech capabilities.

### 1.2 Scope
LocalNOAARadio is a native iOS application built with SwiftUI that:
- Automatically detects user location
- Fetches real-time weather data from official NOAA APIs
- Displays detailed forecasts and active weather alerts
- Provides text-to-speech for listening to weather information
- Enables location-based weather searches

### 1.3 Definitions and Acronyms
- **NOAA**: National Oceanic and Atmospheric Administration
- **NWS**: National Weather Service
- **API**: Application Programming Interface
- **TTS**: Text-to-Speech
- **CoreLocation**: Apple's framework for location services
- **MapKit**: Apple's framework for maps and location search
- **AVSpeechSynthesizer**: Apple's text-to-speech framework

## 2. System Overview

### 2.1 System Context
LocalNOAARadio is a standalone iOS application that:
- Uses device GPS for location detection
- Fetches weather data from official NOAA API (api.weather.gov)
- Synthesizes speech from text forecasts
- Operates in foreground mode
- No data persistence required (real-time data only)

### 2.2 System Architecture

The application follows the Model-View-ViewModel (MVVM) pattern using SwiftUI's modern declarative approach with the `@Observable` macro for state management.

```
┌──────────────────────────────────────────────┐
│            User Interface                    │
│     (ContentView, LocationSearchView)        │
└────────────┬─────────────────────────────────┘
             │
             ├──────────────┬──────────────┐
             │              │              │
    ┌────────▼───────┐ ┌───▼──────┐ ┌─────▼────────┐
    │NOAAWeather     │ │Speech    │ │Location      │
    │Service         │ │Manager   │ │Manager       │
    └────────┬───────┘ └───┬──────┘ └─────┬────────┘
             │             │              │
    ┌────────▼───────┐ ┌───▼──────┐ ┌─────▼────────┐
    │NOAA API        │ │AVSpeech  │ │CoreLocation  │
    │api.weather.gov │ │Synthesizer│ │CLLocation    │
    └────────────────┘ └──────────┘ └──────────────┘
```

## 3. Architectural Design

### 3.1 Design Patterns

#### 3.1.1 Observable Pattern
Uses Swift's `@Observable` macro for reactive state management:
- `NOAAWeatherService`: Manages weather data fetching and state
- `SpeechManager`: Manages text-to-speech playback
- `LocationManager`: Manages location services

#### 3.1.2 Delegation Pattern
Implements:
- `CLLocationManagerDelegate` for location updates
- `AVSpeechSynthesizerDelegate` for speech events

#### 3.1.3 Async/Await Pattern
Modern Swift concurrency for API calls and background operations

### 3.2 Component Architecture

#### 3.2.1 Presentation Layer
**Views (SwiftUI)**:
- `ContentView`: Main application interface with forecasts and controls
- `LocationSearchView`: Location search functionality

#### 3.2.2 Business Logic Layer
**Services**:
- `NOAAWeatherService`: Weather data fetching from NOAA API
- `SpeechManager`: Text-to-speech synthesis
- `LocationManager`: Location detection and management

#### 3.2.3 Data Layer
**Models**:
- `NOAAPointResponse`: API response for location points
- `NOAAForecastResponse`: API response for forecasts
- `NOAAAlertResponse`: API response for weather alerts
- `ForecastPeriod`: Individual forecast period
- `AlertFeature`: Individual weather alert

## 4. Detailed Design

### 4.1 Data Models

#### 4.1.1 NOAAPointResponse
```swift
struct NOAAPointResponse: Codable
{
  let properties: PointProperties
  
  struct PointProperties: Codable
  {
    let forecast: String
    let forecastHourly: String
    let forecastGridData: String
    let observationStations: String
  }
}
```

**Purpose**: Response from api.weather.gov/points endpoint containing URLs for detailed forecasts

#### 4.1.2 NOAAForecastResponse
```swift
struct NOAAForecastResponse: Codable
{
  let properties: ForecastProperties
  
  struct ForecastProperties: Codable
  {
    let periods: [ForecastPeriod]
  }
  
  struct ForecastPeriod: Codable, Identifiable
  {
    let number: Int
    let name: String              // "Tonight", "Wednesday", etc.
    let startTime: String
    let endTime: String
    let isDaytime: Bool
    let temperature: Int
    let temperatureUnit: String   // "F" or "C"
    let windSpeed: String
    let windDirection: String
    let shortForecast: String     // Brief description
    let detailedForecast: String  // Full description
    
    var id: Int { number }
  }
}
```

**Purpose**: Contains forecast periods with detailed weather information

#### 4.1.3 NOAAAlertResponse
```swift
struct NOAAAlertResponse: Codable
{
  let features: [AlertFeature]
  
  struct AlertFeature: Codable, Identifiable
  {
    let id: String
    let properties: AlertProperties
  }
  
  struct AlertProperties: Codable
  {
    let event: String           // "Tornado Warning", etc.
    let headline: String?
    let description: String
    let instruction: String?
    let severity: String        // "Extreme", "Severe", etc.
    let urgency: String
    let certainty: String
  }
}
```

**Purpose**: Contains active weather alerts and warnings

### 4.2 Service Components

#### 4.2.1 NOAAWeatherService

**Responsibilities**:
- Fetch weather data from NOAA API
- Parse JSON responses
- Manage forecast and alert state
- Provide formatted text for display and speech

**Key Methods**:
```swift
func fetchWeather(for location: CLLocation) async
```

**State Properties**:
- `forecastPeriods: [ForecastPeriod]` - Array of forecast periods
- `activeAlerts: [AlertFeature]` - Array of active alerts
- `currentLocation: CLLocation?` - Current location
- `statusMessage: String` - User-facing status
- `isLoading: Bool` - Loading state
- `errorMessage: String?` - Error message if fetch fails

**Computed Properties**:
- `weatherSummary: String` - Formatted text for display
- `speechText: String` - Formatted text optimized for TTS

**API Workflow**:
```
1. Get forecast URL:
   GET https://api.weather.gov/points/{lat},{lon}
   Response: forecast URL

2. Fetch forecast:
   GET {forecast URL from step 1}
   Response: forecast periods

3. Fetch alerts:
   GET https://api.weather.gov/alerts/active?point={lat},{lon}
   Response: active alerts
```

#### 4.2.2 SpeechManager

**Responsibilities**:
- Configure audio session for speech
- Manage AVSpeechSynthesizer
- Handle speech playback (play/pause/stop)
- Track speech state

**Key Methods**:
```swift
func speak(_ text: String)
func stop()
func pause()
func resume()
func togglePause()
```

**State Properties**:
- `isSpeaking: Bool` - Whether speech is active
- `statusText: String` - Current speech status

**Audio Session Configuration**:
```swift
Category: .playback
Mode: .spokenAudio
Options: []
```

**Speech Configuration**:
- Voice: en-US
- Rate: 0.5 (slightly slower for clarity)
- Pitch: 1.0
- Volume: 1.0

#### 4.2.3 LocationManager

**Responsibilities**:
- Request location permissions
- Get current device location
- Reverse geocode for location names
- Track location state

**Key Methods**:
```swift
func requestLocation()
func locationManager(_:didUpdateLocations:)
func locationManager(_:didFailWithError:)
```

**State Properties**:
- `currentLocation: CLLocation?` - Current device location
- `locationName: String?` - Human-readable location name
- `locationStatus: String` - Location status message

**Accuracy Configuration**:
```swift
desiredAccuracy = kCLLocationAccuracyKilometer
```

### 4.3 User Interface Design

#### 4.3.1 ContentView

**Layout Structure**:
```
VStack
├── Header
│   ├── Cloud/Sun icon
│   ├── "NOAA Weather" title
│   ├── Location name (if available)
│   └── Coordinates (if available)
├── Status Message
│   └── Loading/Ready/Error status
├── Action Buttons (HStack)
│   ├── Enter Location (Blue)
│   │   ├── Magnifying glass icon
│   │   └── "Enter\nLocation" text
│   ├── Listen (Green/Gray)
│   │   ├── Play/Stop icon
│   │   └── "Listen"/"Stop" text
│   └── Refresh (Blue)
│       ├── Refresh icon
│       └── "Refresh" text
├── Speech Status
│   └── "Speaking forecast..." (when active)
├── Active Alerts (if any)
│   ├── Alert header with warning icon
│   └── Alert cards (red background)
│       ├── Event name
│       └── Headline
└── Forecast ScrollView
    └── Forecast Period Cards
        ├── Period name + Temperature
        ├── Day/Night icon + Short forecast
        ├── Detailed forecast
        └── Wind information
```

**Button Styling**:
- All buttons: Equal width, 50pt min height
- Layout: VStack with icon above text
- Enter Location: Blue, always enabled
- Listen: Green when forecast available, gray when disabled
- Refresh: Blue, disabled during loading

**State Transitions**:
1. **Initial**: "Finding your location..." + welcome message
2. **Loading**: Progress indicator + "Loading weather data..."
3. **Ready**: Forecast cards displayed
4. **Error**: Error icon + error message
5. **Speaking**: Speech status indicator visible

#### 4.3.2 LocationSearchView

**Purpose**: Enable users to search for weather at any US location

**Layout**:
```
NavigationView
├── Instructions text
├── Search field + Search button
├── Progress indicator (when searching)
└── Toolbar
    └── Cancel button
```

**Search Implementation**:
Uses `MKLocalSearch` API:
```swift
let request = MKLocalSearch.Request()
request.naturalLanguageQuery = searchText
request.resultTypes = [.address, .pointOfInterest]
```

**Workflow**:
1. User enters location text
2. Tap search button
3. MKLocalSearch finds coordinates
4. Update location and fetch weather
5. Dismiss sheet

### 4.4 Data Flow

**Location → Weather Flow**:
```
1. LocationManager.requestLocation()
2. CLLocationManager returns location
3. LocationManager updates currentLocation
4. ContentView observes location change
5. Task { await weatherService.fetchWeather(for: location) }
6. NOAAWeatherService fetches from API
7. SwiftUI re-renders with new data
```

**Speech Flow**:
```
1. User taps Listen button
2. ContentView calls speechManager.speak(weatherService.speechText)
3. SpeechManager creates AVSpeechUtterance
4. AVSpeechSynthesizer speaks text
5. Delegate methods update isSpeaking state
6. SwiftUI re-renders button to show Stop
```

## 5. External Dependencies

### 5.1 iOS Frameworks

#### 5.1.1 SwiftUI
- **Purpose**: User interface framework
- **Usage**: All views, navigation, state management
- **Minimum Version**: iOS 17.0+

#### 5.1.2 AVFoundation
- **Purpose**: Text-to-speech synthesis
- **Components Used**:
  - `AVSpeechSynthesizer`: Speech generation
  - `AVSpeechUtterance`: Speech content
  - `AVAudioSession`: Audio session configuration

#### 5.1.3 CoreLocation
- **Purpose**: Location services
- **Components Used**:
  - `CLLocationManager`: Location updates
  - `CLLocation`: Geographic coordinates
  - `CLLocationManagerDelegate`: Location callbacks
- **Permissions**: "When In Use" location access

#### 5.1.4 MapKit
- **Purpose**: Location search
- **Components Used**:
  - `MKLocalSearch`: Natural language location search
  - `MKLocalSearch.Request`: Search configuration
- **Usage**: Converting place names to coordinates

#### 5.1.5 Foundation
- **Purpose**: Core utilities
- **Components Used**:
  - `URLSession`: Network requests
  - `JSONDecoder`: JSON parsing
  - `URL`: Network resource handling

### 5.2 External Services

#### 5.2.1 NOAA Weather API (api.weather.gov)

**Endpoints Used**:
1. Points: `GET /points/{latitude},{longitude}`
2. Forecast: `GET /gridpoints/{office}/{grid}/forecast`
3. Alerts: `GET /alerts/active?point={latitude},{longitude}`

**Data Format**: JSON
**Authentication**: None required (public API)
**Rate Limits**: Not officially documented, reasonable use expected
**Availability**: 24/7 official government service

**Response Times**: Typically < 1 second

## 6. Security and Privacy

### 6.1 Location Privacy

**Permission Model**:
- "When In Use" authorization only
- Location only accessed when app is active
- Clear purpose string in Info.plist

**Info.plist Entry**:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Location is used to fetch weather forecasts for your area.</string>
```

**Data Handling**:
- Location never transmitted except to NOAA API
- No location storage or tracking
- Reverse geocoding for display only

### 6.2 Network Security

**API Communication**:
- HTTPS only (api.weather.gov uses TLS)
- No authentication tokens or credentials
- Public government data only

### 6.3 Data Privacy

**User Data**:
- No data persistence beyond current session
- No analytics or tracking
- No personal information collected
- No third-party data sharing
- No advertisements

## 7. Performance Considerations

### 7.1 API Calls

**Optimization**:
- Single location request per session
- Weather data refreshes only on user action
- No automatic background updates
- Responses cached during app session

**Network Performance**:
- Typical API response: < 1 second
- All calls use async/await (non-blocking)
- Error handling with user feedback

### 7.2 Speech Synthesis

**Performance**:
- Speech generation is instant (local processing)
- No network dependency for TTS
- Background audio capable

### 7.3 Memory Management

**Resource Usage**:
- Minimal data storage (current session only)
- No large data structures
- Forecast data: ~10-50KB per fetch
- SwiftUI automatic memory management

## 8. Error Handling

### 8.1 API Errors

**Scenarios**:
1. **Network Unavailable**
   - Display: "Failed to fetch weather data: [error]"
   - User Action: Tap refresh to retry

2. **Invalid Location**
   - Display: "No forecast data available"
   - User Action: Search different location

3. **API Rate Limiting** (rare)
   - Display error message
   - User Action: Wait and retry

### 8.2 Location Errors

**Scenarios**:
1. **User Denies Permission**
   - Display: "Failed to get location"
   - Fallback: User must search manually

2. **Location Unavailable**
   - Display error with description
   - Fallback: User must search manually

### 8.3 Speech Errors

**Scenarios**:
1. **No Forecast Data**
   - Button disabled (gray)
   - No action available

2. **Audio Session Error**
   - Logged to console
   - Speech may fail silently

## 9. Configuration and Settings

### 9.1 App Configuration (Info.plist)

**Required Keys**:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Location is used to fetch weather forecasts for your area.</string>
```

**Note**: Background audio not required (TTS is foreground only)

### 9.2 Build Settings

**Target**: iOS 17.0+
**Language**: Swift 6.0+
**Architecture**: Universal (iPhone only, portrait orientation)

## 10. Testing Considerations

### 10.1 Unit Testing Opportunities

**NOAAWeatherService**:
- JSON decoding accuracy
- Error handling for network failures
- Data formatting for display and speech

**SpeechManager**:
- State transitions (speaking/stopped)
- Delegate method handling

**LocationManager**:
- Permission handling
- Location update processing

### 10.2 Integration Testing

**API Integration**:
- Real API calls with various locations
- Alert handling when alerts are active
- Error scenarios (invalid coordinates, etc.)

**User Flow**:
1. Launch app → location requested → weather displayed
2. Search location → weather updates
3. Tap Listen → speech plays
4. Tap Stop → speech stops

### 10.3 UI Testing

**Scenarios**:
- Launch app → verify initial state
- Grant location → verify weather loads
- Tap Listen → verify speech starts
- Search location → verify results update
- Handle errors gracefully

## 11. Deployment

### 11.1 App Store Submission

**Requirements**:
- App icon (all sizes)
- Privacy policy (optional for this simple app)
- Screenshots for multiple device sizes
- Description and keywords

**Privacy Declarations**:
- Location usage: For fetching local weather forecasts
- Network usage: For accessing NOAA weather API
- Data source: Official NOAA government data

**Key Advantage**: No third-party services or unauthorized APIs

### 11.2 Versioning

**Current Version**: 2.0
**Versioning Scheme**: Semantic (major.minor.patch)

**Version History**:
- 1.0: Initial release with streaming (rejected by App Store)
- 2.0: Complete redesign using NOAA API with TTS
  - Official NOAA weather API integration
  - Text-to-speech forecast reading
  - Active weather alerts display
  - Location-based weather search
  - No streaming or third-party services

## 12. Future Enhancements

### 12.1 Potential Features

1. **Extended Forecasts**
   - Hourly forecasts (using forecastHourly endpoint)
   - 7-day detailed forecasts

2. **Weather Maps**
   - Radar imagery
   - Satellite views
   - Temperature maps

3. **Notifications**
   - Push notifications for severe weather alerts
   - Background monitoring (requires additional permissions)

4. **Siri Integration**
   - "Hey Siri, what's the weather forecast?"
   - Shortcuts support

5. **Widget Support**
   - Home screen widget showing current conditions
   - Lock screen widget

6. **Multiple Locations**
   - Save favorite locations
   - Quick switch between locations

7. **Customization**
   - Voice selection for TTS
   - Speech rate adjustment
   - Dark mode optimization

8. **Offline Mode**
   - Cache recent forecasts
   - Last known conditions

### 12.2 Technical Improvements

1. **Caching**
   - Cache API responses with expiration
   - Reduce redundant API calls

2. **Accessibility**
   - VoiceOver optimization
   - Dynamic Type support
   - High contrast mode

3. **Localization**
   - Multi-language support
   - International weather services

4. **Performance**
   - Image caching for weather icons
   - Pagination for long forecasts

## 13. Code Formatting Standards

The project follows strict formatting rules defined in `format_rules.md`:

### 13.1 Key Standards

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
```

**Indentation**: 2 spaces (not tabs)

**Comments**: After closing braces
```swift
} // if
} // for
} // func functionName
} // struct StructName
```

**Line Length**: Maximum 80-100 characters (flexible)

## 14. Appendices

### 14.1 File Structure
```
LocalNOAARadio/
├── LocalNOAARadio/
│   ├── LocalNOAARadioApp.swift       # App entry point
│   ├── ContentView.swift             # Main UI
│   ├── LocationSearchView.swift      # Location search UI
│   ├── NOAAWeatherService.swift      # Weather API service
│   ├── SpeechManager.swift           # Text-to-speech manager
│   ├── Info.plist                    # App configuration
│   ├── format_rules.md               # Code formatting standards
│   ├── SoftwareDesignDocument.md     # This document
│   └── Assets.xcassets/
│       └── AppIcon.appiconset/       # App icons
└── LocalNOAARadio.xcodeproj/         # Xcode project
```

### 14.2 API Examples

**Get Forecast for Location**:
```
1. GET https://api.weather.gov/points/32.7767,-96.7970
   Response: { "properties": { "forecast": "..." } }

2. GET [forecast URL from step 1]
   Response: { "properties": { "periods": [...] } }
```

**Get Active Alerts**:
```
GET https://api.weather.gov/alerts/active?point=32.7767,-96.7970
Response: { "features": [...] }
```

### 14.3 State Diagram

```
[App Launch] → [Request Location]
                     ↓
              [Location Received]
                     ↓
              [Fetch Weather API]
                     ↓
         [Display Forecast + Alerts]
                     ↓
         [User Taps Listen Button]
                     ↓
         [Text-to-Speech Plays]
                     ↓
         [User Can Stop/Refresh/Search]
```

### 14.4 Network Flow

```
┌──────────────┐
│   iPhone     │
│ LocalNOAAApp │
└──────┬───────┘
       │
       │ HTTPS REST API
       ↓
┌──────────────────────┐
│  api.weather.gov     │
│  (NOAA Weather API)  │
└──────┬───────────────┘
       │
       │ Official Data
       ↓
┌──────────────────────┐
│  National Weather    │
│  Service (NWS)       │
└──────────────────────┘
```

---

## Document Revision History

| Version | Date       | Author          | Changes                           |
|---------|------------|-----------------|-----------------------------------|
| 1.0     | 2026-06-16 | Claude Sonnet   | Initial comprehensive SDD for streaming version |
| 2.0     | 2026-06-20 | Claude Sonnet   | Complete redesign for NOAA API with TTS, removed all streaming functionality |

---

**End of Document**
