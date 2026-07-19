import SwiftUI

struct ContentView: View {
    @StateObject private var bluetoothManager = BluetoothManager()
    @StateObject private var audioManager = AudioManager()
    @State private var selectedDeviceType: DeviceType = .iPad
    
    // Retro Cartoon Theme Colors
    let bgColor = Color(red: 0.96, green: 0.94, blue: 0.89) // Vintage cream
    let strokeColor = Color.black
    let strokeWidth: CGFloat = 4
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 40) {
                    
                    // Status Area
                    VStack(spacing: 15) {
                        if audioManager.isPlaying {
                            cartoonIcon(systemName: "music.note", color: .blue)
                            if let locked = bluetoothManager.lockedDeviceType {
                                cartoonText("Playing: \(locked.rawValue)")
                            } else {
                                cartoonText("Playing Music")
                            }
                            Text("Distance: \(bluetoothManager.proximityState)")
                                .font(.custom("Marker Felt", size: 18))
                                .foregroundColor(.black)
                                .fontWeight(.bold)
                        } else if bluetoothManager.isDetecting {
                            cartoonIcon(systemName: "antenna.radiowaves.left.and.right", color: .orange)
                            cartoonText("Searching...")
                            Text("Proximity: \(bluetoothManager.proximityState)")
                                .font(.custom("Marker Felt", size: 18))
                                .foregroundColor(.black)
                                .fontWeight(.bold)
                        } else if bluetoothManager.isBroadcasting {
                            cartoonIcon(systemName: "dot.radiowaves.up.forward", color: .green)
                            cartoonText("Broadcasting as \(selectedDeviceType.rawValue)")
                        } else {
                            cartoonIcon(systemName: "wave.3.left", color: .gray)
                            cartoonText("Idle")
                        }
                    }
                    .frame(height: 250)
                    
                    // Controls
                    VStack(spacing: 30) {
                        if !bluetoothManager.isBroadcasting && !bluetoothManager.isDetecting {
                            // Custom Cartoon Picker
                            VStack(spacing: 10) {
                                cartoonText("Select Device:")
                                HStack(spacing: 8) {
                                    ForEach(DeviceType.allCases) { device in
                                        Button(action: {
                                            selectedDeviceType = device
                                        }) {
                                            Text(device.rawValue)
                                                .font(.custom("Marker Felt", size: 16))
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.5)
                                                .foregroundColor(selectedDeviceType == device ? .white : .black)
                                                .padding(.vertical, 10)
                                                .padding(.horizontal, 8)
                                                .background(selectedDeviceType == device ? Color.black : bgColor)
                                                .cornerRadius(10)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 10)
                                                        .stroke(strokeColor, lineWidth: 3)
                                                )
                                                .compositingGroup()
                                                .shadow(color: .black, radius: 0, x: 2, y: 2)
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Action Buttons
                        cartoonButton(
                            title: bluetoothManager.isBroadcasting ? "Stop Broadcasting" : "Start Broadcasting",
                            bgColor: bluetoothManager.isBroadcasting ? Color(red: 0.9, green: 0.3, blue: 0.3) : Color(red: 0.3, green: 0.8, blue: 0.4),
                            action: {
                                if bluetoothManager.isBroadcasting {
                                    bluetoothManager.stopBroadcasting()
                                } else {
                                    bluetoothManager.stopDetecting() // Stop other mode if active
                                    audioManager.pause()
                                    bluetoothManager.startBroadcasting(as: selectedDeviceType)
                                }
                            }
                        )
                        
                        cartoonButton(
                            title: bluetoothManager.isDetecting ? "Stop Detecting" : "Start Detecting (iPhone)",
                            bgColor: bluetoothManager.isDetecting ? Color(red: 0.9, green: 0.3, blue: 0.3) : Color(red: 0.9, green: 0.6, blue: 0.1),
                            action: {
                                if bluetoothManager.isDetecting {
                                    bluetoothManager.stopDetecting()
                                    audioManager.pause()
                                } else {
                                    bluetoothManager.stopBroadcasting() // Stop other mode if active
                                    bluetoothManager.startDetecting()
                                }
                            }
                        )
                    }
                    .padding(.horizontal, 30)
                    .padding(.bottom, 40)
                    
                }
                .padding(.top, 20)
            }
            .background(bgColor.edgesIgnoringSafeArea(.all))
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Proximity Music")
                        .font(.custom("Marker Felt", size: 28))
                        .fontWeight(.black)
                        .foregroundColor(.black)
                }
            }
            .onAppear {
                bluetoothManager.onProximityChange = { isClose, detectedDeviceType in
                    if isClose, let type = detectedDeviceType {
                        if !audioManager.isPlaying {
                            audioManager.play(for: type)
                        }
                    } else {
                        if audioManager.isPlaying {
                            audioManager.pause()
                        }
                    }
                }
            }
        }
    }
    
    // Helper view for cartoon-style text
    @ViewBuilder
    private func cartoonText(_ text: String) -> some View {
        Text(text)
            .font(.custom("Marker Felt", size: 24))
            .foregroundColor(.black)
            .fontWeight(.bold)
            .multilineTextAlignment(.center)
    }
    
    // Helper view for cartoon-style status icon
    @ViewBuilder
    private func cartoonIcon(systemName: String, color: Color) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 60, weight: .black))
            .foregroundColor(.black)
            .padding(30)
            .background(color)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(strokeColor, lineWidth: strokeWidth)
            )
            .compositingGroup()
            .shadow(color: .black, radius: 0, x: 4, y: 4)
            .padding(.bottom, 10)
    }
    
    // Helper view for cartoon-style buttons
    @ViewBuilder
    private func cartoonButton(title: String, bgColor: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.custom("Marker Felt", size: 22))
                .fontWeight(.bold)
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding()
                .background(bgColor)
                .cornerRadius(15)
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(strokeColor, lineWidth: strokeWidth)
                )
                .compositingGroup()
                .shadow(color: .black, radius: 0, x: 5, y: 5)
        }
    }
}
