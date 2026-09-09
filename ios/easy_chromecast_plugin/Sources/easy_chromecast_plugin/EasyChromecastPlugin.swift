import Flutter
import UIKit
import GoogleCast

public class EasyChromecastPlugin: NSObject, FlutterPlugin, ChromecastHostApi, GCKSessionManagerListener {
  
  private var flutterApi: ChromecastFlutterApi?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let messenger = registrar.messenger()
    let instance = EasyChromecastPlugin()
    
    // Initialiseer de Pigeon Flutter API om data terug te kunnen sturen naar Dart
    instance.flutterApi = ChromecastFlutterApi(binaryMessenger: messenger)
    
    // Registreer de plugin bij de door Pigeon gegenereerde setup
    ChromecastHostApiSetup.setUp(binaryMessenger: messenger, api: instance)
  }

  // MARK: - ChromecastHostApi Implementatie

  public func initializeCast() throws {
    // De Google Cast SDK moet altijd op de main thread worden geïnitialiseerd
    DispatchQueue.main.async {
      if !GCKCastContext.isSharedInstanceInitialized() {
        // We gebruiken de standaard Google App ID. 
        let options = GCKCastOptions(discoveryCriteria: GCKDiscoveryCriteria(applicationID: kGCKDefaultMediaReceiverApplicationID))
        GCKCastContext.setSharedInstanceWith(options)
        
        // Zorg dat de SDK luistert naar de juiste netwerk- en cast-events
        GCKCastContext.sharedInstance().useDefaultExpandedMediaControls = true
      }
      
      // Registreer deze klasse als listener voor verbindingssessies
      GCKCastContext.sharedInstance().sessionManager.add(self)
    }
  }

  public func isConnected() throws -> Bool {
    guard GCKCastContext.isSharedInstanceInitialized() else { return false }
    return GCKCastContext.sharedInstance().sessionManager.hasConnectedSession()
  }

  public func showCastDialog() throws {
    DispatchQueue.main.async {
      if GCKCastContext.isSharedInstanceInitialized() {
        // Dit opent het native iOS Chromecast menu (verbinden / verbreken / apparatenlijst)
        GCKCastContext.sharedInstance().presentCastDialog()
      }
    }
  }

  public func playMedia(request: CastMediaRequest) throws {
    DispatchQueue.main.async {
      guard GCKCastContext.isSharedInstanceInitialized(),
            let session = GCKCastContext.sharedInstance().sessionManager.currentCastSession,
            let remoteMediaClient = session.remoteMediaClient else {
        return
      }

      // Maak de media URL aan
      guard let mediaURL = URL(string: request.url) else { return }
      let mediaInfoBuilder = GCKMediaInformationBuilder(contentURL: mediaURL)
      
      // Optimalisatie voor Live IPTV (.m3u8 / .ts) versus VOD (.mp4)
      let urlString = request.url.lowercased()
      if urlString.contains(".m3u8") || urlString.contains(".ts") {
        mediaInfoBuilder.streamType = .live
      } else {
        mediaInfoBuilder.streamType = .buffered
      }

      // Metadata toevoegen (zoals de titel van de stream)
      let metadata = GCKMediaMetadata(metadataType: .movie)
      metadata.setString(request.title, forKey: kGCKMetadataKeyTitle)
      mediaInfoBuilder.metadata = metadata

      // Start het afspelen direct (autoplay)
      let mediaLoadOptions = GCKMediaLoadOptions()
      mediaLoadOptions.autoplay = true

      remoteMediaClient.loadMedia(mediaInfoBuilder.build(), with: mediaLoadOptions)
    }
  }

  public func stopMedia() throws {
    DispatchQueue.main.async {
      if GCKCastContext.isSharedInstanceInitialized() {
        GCKCastContext.sharedInstance().sessionManager.currentCastSession?.remoteMediaClient?.stop()
      }
    }
  }
  
  public func disconnectDevice() throws {
    DispatchQueue.main.async {
      // True betekent dat ook de receiver app op de KPN Box netjes wordt afgesloten
      GCKCastContext.sharedInstance().sessionManager.endSessionAndStopCasting(true)
    }
  }  

  public func pauseMedia() throws {
    DispatchQueue.main.async {
      if GCKCastContext.isSharedInstanceInitialized() {
        GCKCastContext.sharedInstance().sessionManager.currentCastSession?.remoteMediaClient?.pause()
      }
    }
  }

  public func resumeMedia() throws {
    DispatchQueue.main.async {
      if GCKCastContext.isSharedInstanceInitialized() {
        GCKCastContext.sharedInstance().sessionManager.currentCastSession?.remoteMediaClient?.play()
      }
    }
  }

  public func seekMedia(positionInSeconds: Int64) throws {
    DispatchQueue.main.async {
      if GCKCastContext.isSharedInstanceInitialized(),
         let remoteMediaClient = GCKCastContext.sharedInstance().sessionManager.currentCastSession?.remoteMediaClient {
        
        let options = GCKMediaSeekOptions()
        options.interval = TimeInterval(positionInSeconds)
        options.resumeState = .unchanged // Behoud de huidige status (pauze of spelend) na het spoelen
        
        remoteMediaClient.seek(with: options)
      }
    }
  }

  // MARK: - GCKSessionManagerListener Implementatie (Native -> Dart)

  public func sessionManager(_ sessionManager: GCKSessionManager, didStart session: GCKSession) {
	// Korte vertraging op de main queue
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        if session.remoteMediaClient != nil {
            self.flutterApi?.onConnectionStatusChanged(isConnected: true) { _ in }
        }
    }	
  }
  
  public func sessionManager(_ sessionManager: GCKSessionManager, didResumeSession session: GCKSession) {
    flutterApi?.onConnectionStatusChanged(isConnected: true) { _ in }
  }
  
  public func sessionManager(_ sessionManager: GCKSessionManager, didEnd session: GCKSession, withError error: Error?) {
    flutterApi?.onConnectionStatusChanged(isConnected: false) { _ in }
  }
  
  public func sessionManager(_ sessionManager: GCKSessionManager, didSuspendSession session: GCKSession, with reason: GCKConnectionSuspendReason) {
    flutterApi?.onConnectionStatusChanged(isConnected: false) { _ in }
  }
}
