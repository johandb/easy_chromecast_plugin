import Flutter
import UIKit
import GoogleCast

@objc(EasyChromecastPlugin)
public class EasyChromecastPlugin: NSObject, FlutterPlugin, ChromecastHostApi, GCKSessionManagerListener {
  
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

  @objc private func contextInitialized() {
    DispatchQueue.main.async {
      if GCKCastContext.isSharedInstanceInitialized() {
        GCKCastContext.sharedInstance().sessionManager.add(self)
      }
    }
  }

  // MARK: - GCKSessionManagerListener (Status terugsturen naar Dart - FIX: Concurrency & Try/Await)
  public func sessionManager(_ sessionManager: GCKSessionManager, didStart session: GCKSession) {
    Task {
      try? await flutterApi?.onConnectionStatusChanged(isConnected: true)
    }
  }

  public func sessionManager(_ sessionManager: GCKSessionManager, didEnd session: GCKSession, error: Error?) {
    Task {
      try? await flutterApi?.onConnectionStatusChanged(isConnected: false)
    }
  }
  
  public func sessionManager(_ sessionManager: GCKSessionManager, didFailToStart session: GCKSession, error: Error) {
    Task {
      try? await flutterApi?.onConnectionStatusChanged(isConnected: false)
    }
  }
  
  public func sessionManager(_ sessionManager: GCKSessionManager, didResumeSession session: GCKSession) {
    Task {
      try? await flutterApi?.onConnectionStatusChanged(isConnected: true)
    }
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
      
      // FIX: Dwing de Cast SDK om NU te gaan zoeken op het wifi-netwerk!
      // Dit triggert per direct de officiële iOS Lokaal Netwerk permissie-popup!
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
}

