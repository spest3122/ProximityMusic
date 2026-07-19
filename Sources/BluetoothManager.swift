import Foundation
import CoreBluetooth

enum DeviceType: String, CaseIterable, Identifiable {
    case iPad = "iPad"
    case macbookM1 = "Macbook M1"
    case macbookM3 = "Macbook M3"
    
    var id: String { self.rawValue }
    
    var serviceUUID: CBUUID {
        switch self {
        case .iPad: return CBUUID(string: "A1B2C3D4-E5F6-7890-1234-56789ABCDEF1")
        case .macbookM1: return CBUUID(string: "A1B2C3D4-E5F6-7890-1234-56789ABCDEF2")
        case .macbookM3: return CBUUID(string: "A1B2C3D4-E5F6-7890-1234-56789ABCDEF3")
        }
    }
    
    static var allServiceUUIDs: [CBUUID] {
        return Self.allCases.map { $0.serviceUUID }
    }
    
    static func from(serviceUUID: CBUUID) -> DeviceType? {
        return Self.allCases.first { $0.serviceUUID == serviceUUID }
    }
}

class BluetoothManager: NSObject, ObservableObject {
    @Published var isBroadcasting = false
    @Published var isDetecting = false
    @Published var detectedRSSI: Int = -100
    @Published var proximityState: String = "Unknown" // "Far", "Near", "Immediate"
    @Published var distance: Double = -1.0
    @Published var lockedDeviceType: DeviceType? = nil
    
    private var broadcastingDeviceType: DeviceType?
    
    // Broadcaster
    private var peripheralManager: CBPeripheralManager?
    
    // Detector
    private var centralManager: CBCentralManager?
    private var discoveredPeripheral: CBPeripheral?
    
    // Closure passes (isClose, detectedDeviceType?)
    var onProximityChange: ((Bool, DeviceType?) -> Void)?
    
    override init() {
        super.init()
    }
    
    func startBroadcasting(as deviceType: DeviceType) {
        self.broadcastingDeviceType = deviceType
        if peripheralManager == nil {
            peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
        } else if peripheralManager?.state == .poweredOn {
            startAdvertising()
        }
    }
    
    func stopBroadcasting() {
        peripheralManager?.stopAdvertising()
        DispatchQueue.main.async {
            self.isBroadcasting = false
            self.broadcastingDeviceType = nil
        }
    }
    
    private func startAdvertising() {
        guard let deviceType = broadcastingDeviceType else { return }
        let advertisementData: [String: Any] = [
            CBAdvertisementDataServiceUUIDsKey: [deviceType.serviceUUID]
        ]
        peripheralManager?.startAdvertising(advertisementData)
        DispatchQueue.main.async {
            self.isBroadcasting = true
        }
    }
    
    func startDetecting() {
        if centralManager == nil {
            centralManager = CBCentralManager(delegate: self, queue: nil)
        } else if centralManager?.state == .poweredOn {
            startScanning()
        }
    }
    
    func stopDetecting() {
        centralManager?.stopScan()
        discoveredPeripheral = nil
        DispatchQueue.main.async {
            self.isDetecting = false
            self.detectedRSSI = -100
            self.proximityState = "Unknown"
            self.distance = -1.0
            self.lockedDeviceType = nil
        }
        onProximityChange?(false, nil)
    }
    
    private func startScanning() {
        centralManager?.scanForPeripherals(withServices: DeviceType.allServiceUUIDs, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        DispatchQueue.main.async {
            self.isDetecting = true
        }
    }
    
    private func calculateDistance(rssi: Int) -> Double {
        let txPower = -59.0
        let n = 2.0 // Path loss exponent
        let power = (txPower - Double(rssi)) / (10.0 * n)
        return pow(10.0, power)
    }
}

extension BluetoothManager: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        if peripheral.state == .poweredOn {
            if isBroadcasting {
                startAdvertising()
            }
        } else {
            DispatchQueue.main.async {
                self.isBroadcasting = false
            }
        }
    }
}

extension BluetoothManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            if isDetecting {
                startScanning()
            }
        } else {
            DispatchQueue.main.async {
                self.isDetecting = false
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let rssiValue = RSSI.intValue
        
        // Ignore invalid RSSI values
        if rssiValue == 127 { return }
        
        // Identify the device type from advertisement data
        var detectedDeviceType: DeviceType? = nil
        if let uuids = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] {
            for uuid in uuids {
                if let type = DeviceType.from(serviceUUID: uuid) {
                    detectedDeviceType = type
                    break
                }
            }
        }
        
        guard let deviceType = detectedDeviceType else { return }
        
        DispatchQueue.main.async {
            // Locking logic
            if let lockedType = self.lockedDeviceType {
                if lockedType != deviceType {
                    return // Ignore devices we are not locked onto
                }
            }
            
            self.detectedRSSI = rssiValue
            let dist = self.calculateDistance(rssi: rssiValue)
            self.distance = dist
            
            let isClose: Bool
            if self.lockedDeviceType == deviceType {
                // Already locked: use looser release threshold (-80)
                if rssiValue > -80 {
                    self.proximityState = String(format: "%.1fm", dist)
                    isClose = true
                } else {
                    self.proximityState = "Far"
                    isClose = false
                    self.lockedDeviceType = nil
                }
            } else {
                // Not locked: use stricter lock threshold (-70)
                if rssiValue > -70 {
                    self.proximityState = String(format: "%.1fm", dist)
                    isClose = true
                    self.lockedDeviceType = deviceType
                } else {
                    self.proximityState = "Far"
                    isClose = false
                }
            }
            
            self.onProximityChange?(isClose, deviceType)
        }
    }
}
