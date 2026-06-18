//
//  AudioPlayerManager.swift
//  LocalNOAARadio
//
//  Created by Stewart French on 6/15/26.
//

import Foundation
import AVFoundation


//------------
        // Manages audio streaming for NOAA weather radio
@Observable
class AudioPlayerManager: NSObject
{
  var isPlaying = false
  var statusText = "Ready to play"
  
  private var player: AVPlayer?
  private var playerItem: AVPlayerItem?
  private var statusObserver: NSKeyValueObservation?
  

  override init()
  {
    super.init()
    configureAudioSession()
  } // init


  //----
          // Configure the audio session to allow playback
  private func configureAudioSession()
  {
    do
    {
      let audioSession = AVAudioSession.sharedInstance()
      try audioSession.setCategory(.playback,
                                    mode   : .spokenAudio,
                                    options: [])
      try audioSession.setActive(true)
      print("🔊 Audio session configured successfully")
    } // do
    catch
    {
      print("❌ Audio setup error: \(error.localizedDescription)")
      statusText = "Audio setup error: \(error.localizedDescription)"
    } // catch
  } // configureAudioSession


  //----
          // Play audio from the given URL
  func play(url: URL)
  {
    print("▶️ Attempting to play: \(url)")
    
            // Check if we need to change the stream URL
    if player != nil
    {
      if let currentItem = player?.currentItem,
         let currentURL = (currentItem.asset as? AVURLAsset)?.url,
         currentURL == url
      {
        print("♻️ Reusing existing player for same URL")
        player?.play()
        isPlaying = true
        statusText = "Playing NOAA Weather Radio"
        return
      } // if
      else
      {
        print("🔄 Switching to new station stream")
        stop()
      } // else
    } // if
    
            // Create new player item and player
    playerItem = AVPlayerItem(url: url)
    guard let playerItem = playerItem else
    {
      statusText = "Failed to create player"
      return
    } // guard
    
    player = AVPlayer(playerItem: playerItem)
    
            // Observe player item status
    statusObserver = playerItem.observe(\.status,
                                         options: [.new])
    { [weak self] item, _ in
      DispatchQueue.main.async
      {
        switch item.status
        {
          case .readyToPlay:
            print("✅ Player ready to play")
            self?.statusText = "Playing NOAA Weather Radio"

          case .failed:
            if let error = item.error
            {
              print("❌ Player failed: \(error.localizedDescription)")
              self?.statusText = "Stream error: \(error.localizedDescription)"
            } // if

          case .unknown:
            print("⚠️ Player status unknown")
            self?.statusText = "Connecting to stream..."

          @unknown default:
            break
        } // switch
      } // DispatchQueue.main.async
    } // statusObserver
    
            // Observe errors
    NotificationCenter.default.addObserver(forName  : .AVPlayerItemFailedToPlayToEndTime,
                                           object  : playerItem,
                                           queue   : .main)
    { [weak self] notification in
      if let error = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error
      {
        print("❌ Playback error: \(error.localizedDescription)")
        self?.statusText = "Playback error: \(error.localizedDescription)"
      } // if
    } // addObserver
    
            // Set volume to maximum
    player?.volume = 1.0
    
            // Start playing
    player?.play()
    isPlaying = true
    statusText = "Connecting to stream..."
    
    print("🎵 Player started, volume: \(player?.volume ?? 0)")
  } // play


  //----
          // Pause the audio
  func pause()
  {
    print("⏸️ Pausing playback")
    player?.pause()
    isPlaying = false
    statusText = "Paused"
  } // pause


  //----
          // Toggle between play and pause
  func togglePlayPause(url: URL)
  {
    if isPlaying
    {
      pause()
    } // if
    else
    {
      play(url: url)
    } // else
  } // togglePlayPause


  //----
          // Stop and cleanup
  func stop()
  {
    print("⏹️ Stopping playback")
    player?.pause()
    statusObserver?.invalidate()
    statusObserver = nil
    player = nil
    playerItem = nil
    isPlaying = false
    statusText = "Stopped"
  } // stop

} // class AudioPlayerManager
