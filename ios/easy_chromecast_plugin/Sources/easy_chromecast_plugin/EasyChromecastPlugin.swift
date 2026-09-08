import Flutter
import UIKit
import GoogleCast

public class EasyChromecastPlugin: NSObject, FlutterPlugin, ChromecastHostApi {
  
  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = EasyChromecastPlugin()
    // Registreer de plugin bij de door Pigeon gegenereerde setup
    ChromecastHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: instance)
  }

  // MARK: - ChromecastHostApi Implementatie

  public func initializeCast() throws {
    // De Google Cast SDK moet altijd op de main thread worden geïnitialiseerd
    DispatchQueue.main.async {
      if !GCKCastContext.isSharedInstanceInitialized() {
        // We gebruiken de standaard Google App ID. 
        // Als gebruikers een custom ontvanger hebben, moeten ze dit in hun eigen AppDelegate configureren.
        let options = GCKCastOptions(discoveryCriteria: GCKDiscoveryCriteria(applicationID: kGCKDefaultMediaReceiverApplicationID))
        GCKCastContext.setSharedInstanceWith(options)
        
        // Zorg dat de SDK luistert naar de juiste netwerk- en cast-events
        GCKCastContext.sharedInstance().useDefaultExpandedMediaControls = true
      }
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
}
