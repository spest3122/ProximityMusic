# Proximity Music 🎵

Proximity Music is an interactive iOS and macOS application that plays different music tracks depending on which of your devices are physically close to you. Built with SwiftUI and CoreBluetooth, it turns your Apple devices into a fun, location-aware music ensemble.

## 💡 Inspiration

This project was inspired by an amazing experience at the **Multilingual Switzerland** exhibition in Switzerland. Visitors were given an iPhone and headphones, and as they walked into different areas of the exhibition, the iPhone would seamlessly switch to a new soundtrack corresponding to that specific zone. This app is an attempt to recreate a similar location-aware audio experience using Bluetooth proximity detection!

## 🌟 Features

- **Device Simulation (Broadcasting):** Turn your device into a broadcaster. You can make your current device advertise itself over Bluetooth as an iPad, a MacBook M1, or a MacBook M3.
- **Proximity Detection:** Using Bluetooth Low Energy (BLE), a central device scans the area for broadcasting devices. It calculates the physical distance based on signal strength (RSSI).
- **Dynamic Audio Playback:** As soon as a broadcasting device gets close enough (RSSI > -70), the app locks onto it and plays a specific, looping retro funk track associated with that device type. When the device is moved away, the music automatically pauses.
- **Retro Cartoon UI:** The app features a playful, bold, and vintage cartoon aesthetic with custom fonts, thick strokes, and vibrant colors.

## 🛠️ How it Works

The app operates in two primary modes:

1. **Broadcasting Mode:**
   Select a device type (iPad, MacBook M1, or MacBook M3) and hit "Start Broadcasting". Your device will begin emitting a specific Bluetooth Service UUID corresponding to that device type.

2. **Detecting Mode:**
   Take another device running the app and hit "Start Detecting". It scans for the specific UUIDs. When a broadcast is detected and the distance is close enough:
   - **iPad** triggers the `funkbreakbeat` track.
   - **MacBook M1** triggers the `gvidongvidon` track.
   - **MacBook M3** triggers the `rhythmwalkfunk` track.

## 🚀 Tech Stack

- **SwiftUI**: For a reactive, cross-platform user interface (iOS 16+ / macOS 13+).
- **CoreBluetooth**: For BLE Peripheral (Broadcasting) and Central (Scanning/Detecting) management.
- **AVFoundation**: For seamless audio playback and looping.
- **XcodeGen**: The project configuration is defined in a `project.yml` file, making it easy to generate the Xcode project without merge conflicts.

## 🎧 Setup & Running

1. Install [XcodeGen](https://github.com/yonaskolb/XcodeGen) if you haven't already (`brew install xcodegen`).
2. Run `xcodegen generate` in the `ProximityMusic` folder to generate the `ProximityMusic.xcodeproj`.
3. Open the project in Xcode and run it on a physical iOS device or Mac. *(Note: CoreBluetooth features require physical devices to test proximity effectively; the iOS simulator does not support Bluetooth).*
4. Run the app on at least two physical devices to test the broadcasting and detecting interactions!
