import Foundation
#if os(iOS)
import NearbyInteraction
import MultipeerConnectivity
import UIKit
#endif

class UWBManager: NSObject, ObservableObject {
    @Published var distance: Float? = nil
    @Published var detectedDeviceType: DeviceType? = nil
    
#if os(iOS)
    private var mcSession: MCSession?
    private var mcAdvertiser: MCNearbyServiceAdvertiser?
    private var mcBrowser: MCNearbyServiceBrowser?
    private var localPeerID: MCPeerID!
    
    private var niSession: NISession?
    private var peerDiscoveryToken: NIDiscoveryToken?
    
    private var broadcastingDeviceType: DeviceType?
    private let serviceType = "proxmusic" // Max 15 chars, must match Info.plist
#endif
    
    override init() {
        super.init()
        #if os(iOS)
        let deviceName = UIDevice.current.name
        localPeerID = MCPeerID(displayName: deviceName)
        #endif
    }
    
    func startBroadcasting(as deviceType: DeviceType) {
#if os(iOS)
        guard NISession.isSupported else { return }
        
        self.broadcastingDeviceType = deviceType
        setupMCSession()
        
        let discoveryInfo = ["deviceType": deviceType.rawValue]
        mcAdvertiser = MCNearbyServiceAdvertiser(peer: localPeerID, discoveryInfo: discoveryInfo, serviceType: serviceType)
        mcAdvertiser?.delegate = self
        mcAdvertiser?.startAdvertisingPeer()
#endif
    }
    
    func startDetecting() {
#if os(iOS)
        guard NISession.isSupported else { return }
        
        setupMCSession()
        
        mcBrowser = MCNearbyServiceBrowser(peer: localPeerID, serviceType: serviceType)
        mcBrowser?.delegate = self
        mcBrowser?.startBrowsingForPeers()
#endif
    }
    
    func stop() {
#if os(iOS)
        mcAdvertiser?.stopAdvertisingPeer()
        mcBrowser?.stopBrowsingForPeers()
        mcSession?.disconnect()
        niSession?.invalidate()
        
        mcAdvertiser = nil
        mcBrowser = nil
        mcSession = nil
        niSession = nil
        
        DispatchQueue.main.async {
            self.distance = nil
            self.detectedDeviceType = nil
        }
#endif
    }
    
#if os(iOS)
    private func setupMCSession() {
        if mcSession == nil {
            mcSession = MCSession(peer: localPeerID, securityIdentity: nil, encryptionPreference: .required)
            mcSession?.delegate = self
        }
    }
    
    private func setupNISession() {
        niSession = NISession()
        niSession?.delegate = self
    }
    
    private func sendDiscoveryToken(to peer: MCPeerID) {
        guard let token = niSession?.discoveryToken else { return }
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: true)
            try mcSession?.send(data, toPeers: [peer], with: .reliable)
        } catch {
            print("Failed to send discovery token: \(error)")
        }
    }
#endif
}

#if os(iOS)
extension UWBManager: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        if state == .connected {
            setupNISession()
            sendDiscoveryToken(to: peerID)
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        do {
            if let token = try NSKeyedUnarchiver.unarchivedObject(ofClass: NIDiscoveryToken.self, from: data) {
                let config = NINearbyPeerConfiguration(peerToken: token)
                niSession?.run(config)
            }
        } catch {
            print("Failed to decode token: \(error)")
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

extension UWBManager: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        invitationHandler(true, mcSession)
    }
}

extension UWBManager: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        if let typeStr = info?["deviceType"], let type = DeviceType(rawValue: typeStr) {
            DispatchQueue.main.async {
                self.detectedDeviceType = type
            }
        }
        browser.invitePeer(peerID, to: mcSession!, withContext: nil, timeout: 10)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        DispatchQueue.main.async {
            self.distance = nil
            self.detectedDeviceType = nil
        }
    }
}

extension UWBManager: NISessionDelegate {
    func session(_ session: NISession, didUpdate nearbyObjects: [NINearbyObject]) {
        guard let object = nearbyObjects.first, let distance = object.distance else { return }
        DispatchQueue.main.async {
            self.distance = distance
        }
    }
    
    func session(_ session: NISession, didRemove nearbyObjects: [NINearbyObject], reason: NINearbyObject.RemovalReason) {
        DispatchQueue.main.async {
            self.distance = nil
        }
    }
    
    func sessionWasSuspended(_ session: NISession) {}
    func sessionSuspensionEnded(_ session: NISession) {}
    func session(_ session: NISession, didInvalidateWith error: Error) {}
}
#endif
