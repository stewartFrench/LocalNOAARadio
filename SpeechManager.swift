//
//  SpeechManager.swift
//  LocalNOAARadio
//
//  Created by Stewart French on 6/20/26.
//

import Foundation
import AVFoundation


//------------
@Observable
class SpeechManager: NSObject, AVSpeechSynthesizerDelegate
{
  private var synthesizer: AVSpeechSynthesizer?
  var isSpeaking: Bool = false
  var statusText: String = "Ready to listen"
  
  
  //----
  override init()
  {
    super.init()
    synthesizer = AVSpeechSynthesizer()
    synthesizer?.delegate = self
    configureAudioSession()
  } // init
  
  
  //----
          // Configure audio session for speech
  private func configureAudioSession()
  {
    do
    {
      let audioSession = AVAudioSession.sharedInstance()
      try audioSession.setCategory(.playback,
                                   mode: .spokenAudio,
                                   options: [])
      try audioSession.setActive(true)
    } // do
    catch
    {
      print("❌ Failed to configure audio session: \(error)")
    } // catch
  } // configureAudioSession
  
  
  //----
          // Speak the provided text
  func speak(_ text: String)
  {
    guard let synthesizer = synthesizer else { return }
    
    // Stop any current speech
    if synthesizer.isSpeaking
    {
      synthesizer.stopSpeaking(at: .immediate)
    } // if
    
    // Create utterance
    let utterance = AVSpeechUtterance(string: text)
    utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
    utterance.rate = 0.5  // Slightly slower for clarity
    utterance.pitchMultiplier = 1.0
    utterance.volume = 1.0
    
    // Start speaking
    isSpeaking = true
    statusText = "Speaking forecast..."
    synthesizer.speak(utterance)
  } // speak
  
  
  //----
          // Stop speaking
  func stop()
  {
    synthesizer?.stopSpeaking(at: .immediate)
    isSpeaking = false
    statusText = "Ready to listen"
  } // stop
  
  
  //----
          // Pause speaking
  func pause()
  {
    synthesizer?.pauseSpeaking(at: .word)
    isSpeaking = false
    statusText = "Paused"
  } // pause
  
  
  //----
          // Resume speaking
  func resume()
  {
    synthesizer?.continueSpeaking()
    isSpeaking = true
    statusText = "Speaking forecast..."
  } // resume
  
  
  //----
          // Toggle pause/resume
  func togglePause()
  {
    guard let synthesizer = synthesizer else { return }
    
    if synthesizer.isPaused
    {
      resume()
    } // if
    else if synthesizer.isSpeaking
    {
      pause()
    } // else if
  } // togglePause
  
  
  //----
          // AVSpeechSynthesizerDelegate methods
  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                        didStart utterance: AVSpeechUtterance)
  {
    isSpeaking = true
    statusText = "Speaking forecast..."
  } // didStart
  
  
  //----
  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                        didFinish utterance: AVSpeechUtterance)
  {
    isSpeaking = false
    statusText = "Ready to listen"
  } // didFinish
  
  
  //----
  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                        didPause utterance: AVSpeechUtterance)
  {
    isSpeaking = false
    statusText = "Paused"
  } // didPause
  
  
  //----
  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                        didContinue utterance: AVSpeechUtterance)
  {
    isSpeaking = true
    statusText = "Speaking forecast..."
  } // didContinue

} // class SpeechManager
