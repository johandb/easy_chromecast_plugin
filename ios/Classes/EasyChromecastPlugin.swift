import Flutter
import UIKit
import GoogleCast

@objc(EasyChromecastPlugin)
public class EasyChromecastPlugin: NSObject, FlutterPlugin, ChromecastHostApi {
  
  private var flutterApi: ChromecastFlutterApi?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = EasyChromecastPlugin()
    let binaryMessenger = registrar.messenger()
    
    // Initialiseer de Google Cast SDK direct op de UI main thread
    DispatchQueue.main.async {
      if !GCKCastContext.isSharedInstanceInitialized() {
        let options = GCKCastOptions(discoveryCriteria: GCKDiscoveryCriteria(applicationID: kGCKDefaultMediaReceiverApplicationID))
        GCKCastContext.setSharedInstanceWith(options)
        GCKCastContext.sharedInstance().sessionManager.add(instance)
        GCKCastContext.sharedInstance().useDefaultExpandedMediaControls = true
      }
    }
    
    // Laat Pigeon de kanalen automatisch koppelen
    ChromecastHostApiSetup.setUp(binaryMessenger: binaryMessenger, api: instance)
    instance.flutterApi = ChromecastFlutterApi(binaryMessenger: binaryMessenger)
  }

  // MARK: - ChromecastHostApi Implementatie
  func initializeCast() throws {
    DispatchQueue.main.async {
      if !GCKCastContext.isSharedInstanceInitialized() {
        let options = GCKCastOptions(discoveryCriteria: GCKDiscoveryCriteria(applicationID: kGCKDefaultMediaReceiverApplicationID))
        GCKCastContext.setSharedInstanceWith(options)
        GCKCastContext.sharedInstance().sessionManager.add(self)
        GCKCastContext.sharedInstance().useDefaultExpandedMediaControls = true
      }
      
      // Dwing de Cast SDK om NU te gaan zoeken op het wifi-netwerk!
      GCKCastContext.sharedInstance().discoveryManager.startDiscovery()
      print("EasyChromecastPlugin: startDiscovery geforceerd gestart!")
    }
  }

  func isConnected() throws -> Bool {
    guard GCKCastContext.isSharedInstanceInitialized() else { return false }
    return GCKCastContext.sharedInstance().sessionManager.hasConnectedSession()
  }

  func showCastDialog() throws {
    DispatchQueue.main.async {
      if GCKCastContext.isSharedInstanceInitialized() {
        GCKCastContext.sharedInstance().presentCastDialog()
      }
    }
  }

  func playMedia(request: CastMediaRequest) throws {
    DispatchQueue.main.async {
      guard GCKCastContext.isSharedInstanceInitialized(),
            let session = GCKCastContext.sharedInstance().sessionManager.currentCastSession,
            let remoteMediaClient = session.remoteMediaClient else { return }

      guard let mediaURL = URL(string: request.url) else { return }
      let mediaInfoBuilder = GCKMediaInformationBuilder(contentURL: mediaURL)
      
      if request.url.lowercased().contains(".m3u8") || request.url.lowercased().contains(".ts") {
        mediaInfoBuilder.streamType = .live
      } else {
        mediaInfoBuilder.streamType = .buffered
      }

      let metadata = GCKMediaMetadata(metadataType: .movie)
      metadata.setString(request.title, forKey: kGCKMetadataKeyTitle)
      mediaInfoBuilder.metadata = metadata

      // Registreer deze klasse als luisteraar voor de media updates van deze sessie
      remoteMediaClient.add(self)

      let mediaLoadOptions = GCKMediaLoadOptions()
      mediaLoadOptions.autoplay = true
      remoteMediaClient.loadMedia(mediaInfoBuilder.build(), with: mediaLoadOptions)
    }
  }

  func stopMedia() throws {
    DispatchQueue.main.async { GCKCastContext.sharedInstance().sessionManager.currentCastSession?.remoteMediaClient?.stop() }
  }

  func disconnectDevice() throws {
    DispatchQueue.main.async { GCKCastContext.sharedInstance().sessionManager.endSessionAndStopCasting(true) }
  }

  func pauseMedia() throws {
    DispatchQueue.main.async { GCKCastContext.sharedInstance().sessionManager.currentCastSession?.remoteMediaClient?.pause() }
  }

  func resumeMedia() throws {
    DispatchQueue.main.async { GCKCastContext.sharedInstance().sessionManager.currentCastSession?.remoteMediaClient?.play() }
  }

  func seekMedia(positionInSeconds: Int64) throws {
    DispatchQueue.main.async {
      if let remoteMediaClient = GCKCastContext.sharedInstance().sessionManager.currentCastSession?.remoteMediaClient {
        let options = GCKMediaSeekOptions()
        options.interval = TimeInterval(positionInSeconds)
        options.resumeState = .unchanged
        remoteMediaClient.seek(with: options)
      }
    }
  }

  // FIX: GCKCastSession gebruikt setDeviceVolume in plaats van setVolume!
  func setVolume(volume: Double) throws {
    DispatchQueue.main.async {
      guard GCKCastContext.isSharedInstanceInitialized(),
            let currentSession = GCKCastContext.sharedInstance().sessionManager.currentCastSession else { return }
      
      // Google Cast verwacht een Float tussen 0.0 en 1.0
      let targetVolume = Float(volume)
      currentSession.setDeviceVolume(targetVolume)
    }
  }
}

// MARK: - GCKRemoteMediaClientListener (Zorgt voor mediaOnchange / Update)
extension EasyChromecastPlugin: GCKRemoteMediaClientListener {
    
    // FIX: mediaStatus moet optioneel (GCKMediaStatus?) zijn om te voldoen aan het protocol
    public func remoteMediaClient(_ client: GCKRemoteMediaClient, didUpdate mediaStatus: GCKMediaStatus?) {
        guard let status = mediaStatus else { return }
        let playerState: String
        
        switch status.playerState {
        case .idle:
            playerState = "IDLE"
        case .playing:
            playerState = "PLAYING"
        case .paused:
            playerState = "PAUSED"
        case .buffering:
            playerState = "BUFFERING"
        case .unknown:
            playerState = "UNKNOWN"
        @unknown default:
            playerState = "UNKNOWN"
        }
        
        // Verzend de update veilig naar Flutter via Pigeon
        Task {
            try? await self.flutterApi?.onMediaStatusChanged(playerState: playerState)
        }
    }
}

// MARK: - GCKSessionManagerListener (Zorgt voor Connection Status)
extension EasyChromecastPlugin: GCKSessionManagerListener {
    
    public func sessionManager(_ sessionManager: GCKSessionManager, didStart session: GCKSession) {
        Task {
            try? await self.flutterApi?.onConnectionStatusChanged(isConnected: true)
        }
        
        if let castSession = session as? GCKCastSession {
            castSession.remoteMediaClient?.add(self)
        }
    }
    
    public func sessionManager(_ sessionManager: GCKSessionManager, didEnd session: GCKSession, withError error: Error?) {
        Task {
            try? await self.flutterApi?.onConnectionStatusChanged(isConnected: false)
        }
    }
    
    public func sessionManager(_ sessionManager: GCKSessionManager, didFailToStart session: GCKSession, withError error: Error) {
        Task {
            try? await self.flutterApi?.onConnectionStatusChanged(isConnected: false)
        }
    }
    
    public func sessionManager(_ sessionManager: GCKSessionManager, didResumeCastSession session: GCKCastSession) {
        Task {
            try? await self.flutterApi?.onConnectionStatusChanged(isConnected: true)
        }
        session.remoteMediaClient?.add(self)
    }
}

