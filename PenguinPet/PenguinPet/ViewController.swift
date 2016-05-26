//
//  ViewController.swift
//  PenguinPet
//
//  Created by Michael Briscoe on 1/13/16.
//  Copyright © 2016 Razeware LLC. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {

  @IBOutlet weak var penguin: UIImageView!
  @IBOutlet weak var timeLabel: UILabel!
  @IBOutlet weak var recordButton: UIButton!
  @IBOutlet weak var playButton: UIButton!
  
  var audioStatus: AudioStatus = AudioStatus.Stopped
  
  var audioRecorder: AVAudioRecorder!
  var audioPlayer: AVAudioPlayer?
  
  var soundTimer: CFTimeInterval = 0.0
  var updateTimer: CADisplayLink!
  
  let meterTable = MeterTable(tableSize: 100)
  
  // MARK: - Setup
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let nc = NSNotificationCenter.defaultCenter()
    let session = AVAudioSession.sharedInstance()
    
    nc.addObserver(self, selector: "handleInterruption:", name: AVAudioSessionInterruptionNotification, object: session)
    nc.addObserver(self, selector: "handleRouteChange:", name: AVAudioSessionRouteChangeNotification, object: session)

    setupRecorder()
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  override func prefersStatusBarHidden() -> Bool {
    return true
  }
  
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier == "optionsSeque" {
      let optionsVC = segue.destinationViewController as! OptionsViewController
      optionsVC.vc = self
    }
  }
  
  // MARK: - Controls
  @IBAction func onRecord(sender: UIButton) {
    if appHasMicAccess == true {
      if audioStatus != .Playing {
        
        switch audioStatus {
        case .Stopped:
          recordButton.setBackgroundImage(UIImage(named: "button-record1"), forState: UIControlState.Normal)
          record()
        case .Recording:
          recordButton.setBackgroundImage(UIImage(named: "button-record"), forState: UIControlState.Normal)
          stopRecording()
        default:
          break
        }
      }
    } else {
      recordButton.enabled = false
      let theAlert = UIAlertController(title: "Requires Microphone Access",
        message: "Go to Settings > PenguinPet > Allow PenguinPet to Access Microphone.\nSet switch to enable.",
        preferredStyle: UIAlertControllerStyle.Alert)
      
      theAlert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
      self.view?.window?.rootViewController?.presentViewController(theAlert, animated: true, completion:nil)
    }

  }

  @IBAction func onPlay(sender: UIButton) {
    if audioStatus != .Recording {
      
      switch audioStatus {
      case .Stopped:
        play()
      case .Playing:
        stopPlayback()
      default:
        break
      }
    }
  }

  func setPlayButtonOn(flag: Bool) {
    if flag == true {
      playButton.setBackgroundImage(UIImage(named: "button-play1"), forState: UIControlState.Normal)
    } else {
      playButton.setBackgroundImage(UIImage(named: "button-play"), forState: UIControlState.Normal)
    }
  }
  
  // MARK: - Update Loop
  func startUpdateLoop() {
    if updateTimer != nil {
      updateTimer.invalidate()
    }
    updateTimer = CADisplayLink(target: self, selector: "updateLoop")
    updateTimer.frameInterval = 1
    updateTimer.addToRunLoop(NSRunLoop.currentRunLoop(), forMode: NSRunLoopCommonModes)
  }
  
  func stopUpdateLoop() {
    updateTimer.invalidate()
    updateTimer = nil
    // Update UI
    timeLabel.text = formattedCurrentTime(UInt(0))
    animateMouth(1)
  }
  
  func updateLoop() {
    if audioStatus == .Recording {
      if CFAbsoluteTimeGetCurrent() - soundTimer > 0.5 {
        timeLabel.text = formattedCurrentTime(UInt(audioRecorder.currentTime))
        soundTimer = CFAbsoluteTimeGetCurrent()
      }
    }
    
    if audioStatus == .Playing {
      if CFAbsoluteTimeGetCurrent() - soundTimer > 0.5 {
        timeLabel.text = formattedCurrentTime(UInt(audioPlayer!.currentTime))
        soundTimer = CFAbsoluteTimeGetCurrent()
      }
      animateMouth(meterLevelsToFrame())
    }
  }
  
  func animateMouth(frame: Int) {
    let frameName = "penguin_0\(frame)"
    let frame = UIImage(named: frameName)
    penguin.image = frame
  }

}

// MARK: - AVFoundation Methods
extension ViewController: AVAudioPlayerDelegate, AVAudioRecorderDelegate {
  
  // MARK: Recording
  func setupRecorder() {
    let fileURL = getURLforMemo()
    
    let recordSettings = [
      AVFormatIDKey: Int(kAudioFormatLinearPCM),
      AVSampleRateKey: 44100.0,
      AVNumberOfChannelsKey: 1,
      AVEncoderAudioQualityKey: AVAudioQuality.High.rawValue
    ]
    
    do {
      audioRecorder = try AVAudioRecorder(URL: fileURL, settings: recordSettings as! [String : AnyObject])
      audioRecorder.delegate = self
      audioRecorder.prepareToRecord()
    } catch {
      print("Error creating audioRecorder.")
    }
  }
  
  func record() {
    audioRecorder.record()
    startUpdateLoop()
    audioStatus = .Recording
  }
  
  func stopRecording() {
    audioRecorder.stop()
    stopUpdateLoop()
    audioStatus = .Stopped
  }
  
  // MARK: Playback
  func  play() {
    let fileURL = getURLforMemo()
    
    do {
      audioPlayer = try AVAudioPlayer(contentsOfURL: fileURL)
      audioPlayer!.delegate = self
      if audioPlayer!.duration > 0.0 {
        setPlayButtonOn(true)
        
        audioPlayer!.enableRate = true
        setRate(NSUserDefaults.standardUserDefaults().floatForKey("Rate"))
        
        setVolume(NSUserDefaults.standardUserDefaults().floatForKey("Volume"))
        setPan(NSUserDefaults.standardUserDefaults().floatForKey("Pan"))
        setLoopPlayback(NSUserDefaults.standardUserDefaults().boolForKey("Loop Audio"))
        
        audioPlayer!.meteringEnabled = true

        audioPlayer!.play()
        startUpdateLoop()
        audioStatus = .Playing
      }
    } catch {
      print("Error loading audioPlayer.")
    }
  }
  
  func stopPlayback() {
    audioPlayer!.stop()
    setPlayButtonOn(false)
    audioStatus = .Stopped
    stopUpdateLoop()
  }
  
  func setVolume(value: Float) {
    audioPlayer!.volume = value
  }
  
  func setPan(value: Float) {
    audioPlayer!.pan = value
  }
  
  func setRate(value: Float) {
    audioPlayer!.rate = value
  }
  
  func setLoopPlayback(loop: Bool) {
    if loop == true {
      audioPlayer!.numberOfLoops = -1
    } else {
      audioPlayer!.numberOfLoops = 0
    }
  }
  
  func meterLevelsToFrame() -> Int {
    audioPlayer!.updateMeters()
    let avgPower = audioPlayer!.averagePowerForChannel(0)
    let linearLevel = meterTable.valueForPower(avgPower)
    
    // Convert to percentage
    let powerPercentage = Int(round(linearLevel * 100))
    
    // Divide percentage by number of frames
    let totalFrames = 5
    let frame = (powerPercentage / totalFrames) + 1
    
    return min(frame, totalFrames)
  }

  // MARK: Delegates
  func audioRecorderDidFinishRecording(recorder: AVAudioRecorder, successfully flag: Bool) {
    audioStatus = .Stopped
  }
  
  func audioPlayerDidFinishPlaying(player: AVAudioPlayer, successfully flag: Bool) {
    setPlayButtonOn(false)
    audioStatus = .Stopped
    stopUpdateLoop()
  }

  
  // MARK: Notifications
  func handleInterruption(notification: NSNotification) {
    if let info = notification.userInfo {
      let type = AVAudioSessionInterruptionType(rawValue: info[AVAudioSessionInterruptionTypeKey] as! UInt)
      if type == .Began {
        if audioStatus == .Playing {
          stopPlayback()
        } else if audioStatus == .Recording {
          stopRecording()
        }
      } else {
        let options = AVAudioSessionInterruptionOptions(rawValue: info[AVAudioSessionInterruptionOptionKey] as! UInt)
        
        if options == .ShouldResume {
          // Do something here...
        }
      }
    }
  }
  
  func handleRouteChange(notification: NSNotification) {
    if let info = notification.userInfo {
      
      let reason = AVAudioSessionRouteChangeReason(rawValue: info[AVAudioSessionRouteChangeReasonKey] as! UInt)
      if reason == .OldDeviceUnavailable {
        let previousRoute = info[AVAudioSessionRouteChangePreviousRouteKey] as? AVAudioSessionRouteDescription
        let previousOutput = previousRoute!.outputs.first!
        if previousOutput.portType == AVAudioSessionPortHeadphones {
          if audioStatus == .Playing {
            stopPlayback()
          } else if audioStatus == .Recording {
            stopRecording()
          }
        }
      }
    }
  }
  
  // MARK: - Helpers
  
  func getURLforMemo() -> NSURL {
    let tempDir = NSTemporaryDirectory()
    let filePath = tempDir + "/TempMemo.caf"
    
    return NSURL.fileURLWithPath(filePath)
  }
  
  func formattedCurrentTime(time: UInt) -> String {
    let hours = time / 3600
    let minutes = (time / 60) % 60
    let seconds = time % 60
    
    return String(format: "%02i:%02i:%02i", arguments: [hours, minutes, seconds])
  }

}


