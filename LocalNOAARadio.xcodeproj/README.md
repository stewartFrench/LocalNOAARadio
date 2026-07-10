# LocalNOAARadio

A free, open-source iOS app that provides real-time weather forecasts and alerts from NOAA (National Oceanic and Atmospheric Administration) with text-to-speech capabilities.

## Features

- **Real-Time Weather Data**: Fetches current weather forecasts directly from NOAA's official API (api.weather.gov)
- **Active Weather Alerts**: Displays urgent weather warnings, watches, and advisories
- **Text-to-Speech**: Listen to weather forecasts spoken aloud using iOS speech synthesis
- **Location-Based**: Automatically finds weather for your current location
- **Location Search**: Search for weather at any US location
- **Detailed Forecasts**: View multi-day forecasts with temperature, wind, and detailed descriptions
- **No Ads, No Tracking**: Completely free with no advertisements or data collection

## Requirements

- iOS 17.0 or later
- iPhone (portrait orientation)
- Location services (optional, for automatic location detection)

## How It Works

1. **Location**: The app uses your device's GPS to determine your location (or you can search for any location)
2. **NOAA API**: Fetches official weather data from the National Weather Service API
3. **Display**: Shows current conditions, forecast periods, and active alerts
4. **Listen**: Tap "Listen" to hear the weather forecast read aloud using text-to-speech

## Data Source

This app uses official data from:
- **NOAA Weather API** (api.weather.gov) - Public domain government weather data
- **National Weather Service** - Official US weather forecasts and alerts

No third-party streaming services or unauthorized APIs are used. All weather data comes directly from official NOAA sources.

## Privacy

- **No Data Collection**: Your location and weather preferences stay on your device
- **No Third-Party Services**: Direct connection to official NOAA APIs only
- **No Tracking**: No analytics or user tracking of any kind
- **Location Privacy**: Location is only accessed when you use the app, never in the background

## Installation

### From Source (Xcode)

1. Clone this repository
2. Open `LocalNOAARadio.xcodeproj` in Xcode
3. Build and run on your device or simulator

### App Store

*Coming soon - pending App Store approval*

## Technical Details

- **Language**: Swift 6.0+
- **Framework**: SwiftUI
- **Architecture**: Observable pattern with MVVM
- **APIs Used**: 
  - NOAA Weather API (api.weather.gov)
  - CoreLocation (for GPS)
  - AVSpeechSynthesizer (for text-to-speech)
  - MapKit (for location search)

## License

This project is released into the **public domain**. You are free to use, modify, and distribute this software without any restrictions.

## Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues.

## Support

For issues or questions:
- Open an issue on GitHub
- Contact: stewart.french@gmail.com

## Acknowledgments

- Weather data provided by NOAA (National Oceanic and Atmospheric Administration)
- National Weather Service for maintaining the public weather API
- All weather information is official US government data (public domain)

---

**Note**: This app provides weather information for educational and general awareness purposes. For emergency weather information, always follow official National Weather Service guidance and local emergency management instructions.
