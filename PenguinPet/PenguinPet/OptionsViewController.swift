//
//  OptionsViewController.swift
//  PenguinPet
//
//  Created by Michael Briscoe on 12/17/15.
//  Copyright © 2015 Razeware. All rights reserved.
//

import UIKit

class OptionsViewController: UIViewController {
  
  @IBOutlet weak var volumeSlider: UISlider!
  @IBOutlet weak var panSlider: UISlider!
  @IBOutlet weak var rateSlider: UISlider!
  @IBOutlet weak var loopSwitch: UISwitch!
  
  let defaults = NSUserDefaults.standardUserDefaults()
  unowned var vc: ViewController = ViewController()
  
  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
    volumeSlider.value = defaults.floatForKey("Volume")
    panSlider.value = defaults.floatForKey("Pan")
    rateSlider.value = defaults.floatForKey("Rate")
    loopSwitch.on = defaults.boolForKey("Loop Audio")
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  override func prefersStatusBarHidden() -> Bool {
    return true
  }
  
  
  @IBAction func closeOptions(sender: AnyObject) {
    dismissViewControllerAnimated(true, completion: nil)
  }
  
  @IBAction func setVolume(sender: AnyObject) {
    defaults.setFloat(sender.value, forKey: "Volume")
    defaults.synchronize()
    vc.setVolume(sender.value)
    
  }
  
  @IBAction func setPan(sender: AnyObject) {
    defaults.setFloat(sender.value, forKey: "Pan")
    defaults.synchronize()
    vc.setPan(sender.value)
  }
  
  @IBAction func setRate(sender: AnyObject) {
    defaults.setFloat(sender.value, forKey: "Rate")
    defaults.synchronize()
    vc.setRate(sender.value)
  }
  
  @IBAction func loopAudio(sender: UISwitch) {
    defaults.setBool(sender.on, forKey: "Loop Audio")
    defaults.synchronize()
    vc.setLoopPlayback(sender.on)
  }
  
  @IBAction func previewAudio(sender: AnyObject) {
    vc.play()
  }
  
}
