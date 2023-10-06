//
//  ViewController.swift
//  vlckitSwiftSample
//
//  Created by Mark Knapp on 11/18/15.
//  Copyright © 2015 Mark Knapp. All rights reserved.
//

import UIKit
import AVKit
import PiPhone
import AVFoundation

class ViewController: UIViewController {
    
    let adjustmentBehaviors = [(behavior: PiPManagerContentInsetAdjustmentBehavior.navigationBar, title: "Navigation bar"),
                               (.tabBar, "Tab bar"),
                               (.navigationAndTabBars, "Navigation and Tab bars"),
                               (.safeArea, "Safe area"),
                               (.none, "None")]
    
    var topPresentedViewController: UIViewController {
        var viewController: UIViewController = self
        
        while let vc = viewController.presentedViewController {
            viewController = vc
        }
        
        return viewController
    }
    
    var playerController : AVPlayerViewController!
    
    @IBOutlet var containerView: UIView!
    @IBOutlet var pickerView: UIPickerView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController!.tabBarItem.image = AVPictureInPictureController.pictureInPictureButtonStartImage(compatibleWith: nil)
        
        if !PiPManager.isSettedUp {
            containerView.isUserInteractionEnabled = false
            containerView.alpha = 0.6
            
            pickerView.isUserInteractionEnabled = false
            pickerView.alpha = 0.6
        }
    }
    
    func constructPlayer() -> AVPlayer {
//        let playerItems = urls.compactMap(URL.init(string:)).map(AVPlayerItem.init)
        
        guard let path = Bundle.main.path(forResource: "BigBuckBunny", ofType:"mp4") else {
            debugPrint("video.mp4 not found")
            return AVPlayer()
        }
        
        let url = URL(fileURLWithPath: path)
        
        let playerItem = AVPlayerItem(url: url)
        
        return AVQueuePlayer(items: [playerItem])
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let controller = segue.destination as? CustomPlayerViewController else {
            return
        }
        
        controller.delegate = self
        controller.player = constructPlayer()
    }
    
    // MARK: - Actions
    @IBAction func avPlayerViewControllerButtonTapped() {
        
        guard let path = Bundle.main.path(forResource: "BigBuckBunny", ofType:"mp4") else {
            debugPrint("video.mp4 not found")
            return
        }
        
        let url = URL(fileURLWithPath: path)
        
        let player = AVPlayer(url: url)
        
        playerController = AVPlayerViewController()
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.didfinishPlaying(note:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: player.currentItem)
        
        playerController.player = player
        
        playerController.allowsPictureInPicturePlayback = true
        
        playerController.delegate = self
        
        playerController.player?.play()
        
        self.present(playerController, animated: true, completion : nil)
    }
    
    @objc func didfinishPlaying(note : NSNotification)  {
        playerController.dismiss(animated: true, completion: nil)
        let alertView = UIAlertController(title: "Finished", message: "Video finished", preferredStyle: .alert)
        alertView.addAction(UIAlertAction(title: "Okey", style: .default, handler: nil))
        self.present(alertView, animated: true, completion: nil)
    }

    @IBAction func switchValueChanged(_ switchView: UISwitch) {
        PiPManager.isPictureInPicturePossible = switchView.isOn
    }

}

// MARK: - UIPickerViewDataSource
extension ViewController: UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return adjustmentBehaviors.count
    }
    
}

// MARK: - UIPickerViewDelegate
extension ViewController: UIPickerViewDelegate {
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return adjustmentBehaviors[row].title
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        UIView.animate(withDuration: 0.25) {
            PiPManager.contentInsetAdjustmentBehavior = self.adjustmentBehaviors[row].behavior
        }
    }
    
}

// MARK: - AVPlayerViewControllerDelegate
extension ViewController: AVPlayerViewControllerDelegate {
    
    func playerViewController(_ playerViewController: AVPlayerViewController, restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void) {
        if playerViewController.presentingViewController != nil {
            completionHandler(true)
            return
        }
        
        topPresentedViewController.present(playerViewController, animated: true)
        completionHandler(true)
    }
    
//    func playerViewControllerShouldAutomaticallyDismissAtPictureInPictureStart(_ playerViewController: AVPlayerViewController) -> Bool {
//        return false
//    }
    
}

// MARK: - CustomPlayerViewControllerDelegate
extension ViewController: CustomPlayerViewControllerDelegate {
    
    func customPlayerViewController(_ customPlayerViewController: CustomPlayerViewController, restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void) {
        
        if navigationController!.viewControllers.firstIndex(of: customPlayerViewController) != nil {
            completionHandler(true)
        } else {
            navigationController!.pushViewController(customPlayerViewController, animated: true)
            completionHandler(true)
        }
    }

}

