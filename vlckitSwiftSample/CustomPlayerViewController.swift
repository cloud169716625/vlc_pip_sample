//
//  CustomPlayerViewController.swift
//  Example Swift
//
//  Created by KY1VSTAR on 11.04.2019.
//  Copyright © 2019 KY1VSTAR. All rights reserved.
//

import UIKit
import AVKit
import MobileVLCKit
import MediaPlayer

protocol CustomPlayerViewControllerDelegate: class {
    
    func customPlayerViewController(_ customPlayerViewController: CustomPlayerViewController, restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void)
    
}

class CustomPlayerViewController: UIViewController {
    
    @IBOutlet weak var playerView: PlayerView!
    @IBOutlet weak var movieView: UIView!
    @IBOutlet weak var pipToggleButton: UIButton!
    
    var mediaPlayer: VLCMediaPlayer = VLCMediaPlayer()
    weak var delegate: CustomPlayerViewControllerDelegate?
    var player: AVPlayer?
    private var pictureInPictureController: AVPictureInPictureController!
    private var pictureInPictureObservations = [NSKeyValueObservation]()
    private var strongSelf: Any?
    
    deinit {
        // without this line vanilla AVPictureInPictureController will crash due to KVO issue
        pictureInPictureObservations = []
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if AVPictureInPictureController.isPictureInPictureSupported() {
            print("supported")
        } else {
            print("unsupported")
        }
                        
        self.setupAV()
        self.setupVLC()
        
        setupPictureInPicture()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        mediaPlayer.play()
        mediaPlayer.audio.volume = 0
        player?.play()
    }
    
    func setupAV() {
        guard let path = Bundle.main.path(forResource: "BigBuckBunny", ofType:"mp4") else {
            debugPrint("video.mp4 not found")
            return
        }
        
        let url = URL(fileURLWithPath: path)
        
        let playerItem = AVPlayerItem(url: url)
        
        self.player = AVQueuePlayer(items: [playerItem])
        playerView.playerLayer.player = player
    }
    
    // - VLCMediaPlayer
    func setupVLC() {
        
        guard let path = Bundle.main.path(forResource: "BigBuckBunny", ofType:"mp4") else {
            debugPrint("video.mp4 not found")
            return
        }
        
        let url = URL(fileURLWithPath: path)

        let media = VLCMedia(url: url)

        // Set media options
        // https://wiki.videolan.org/VLC_commandaqa-line_help
        media.addOptions([
            "network-caching": 5000,
            "hardware-decoding": false
        
        ])

        mediaPlayer.media = media
        mediaPlayer.delegate = self
        mediaPlayer.drawable = self.movieView
    }
    
    // https://developer.apple.com/documentation/avkit/adopting_picture_in_picture_in_a_custom_player
    func setupPictureInPicture() {
        pipToggleButton.setImage(AVPictureInPictureController.pictureInPictureButtonStartImage(compatibleWith: nil), for: .normal)
        pipToggleButton.setImage(AVPictureInPictureController.pictureInPictureButtonStopImage(compatibleWith: nil), for: .selected)
        pipToggleButton.setImage(AVPictureInPictureController.pictureInPictureButtonStopImage(compatibleWith: nil), for: [.selected, .highlighted])
        
        guard AVPictureInPictureController.isPictureInPictureSupported(),
            let pictureInPictureController = AVPictureInPictureController(playerLayer: playerView.playerLayer) else {
                
                pipToggleButton.isEnabled = false
                return
        }
        
        self.pictureInPictureController = pictureInPictureController
        pictureInPictureController.delegate = self
        pipToggleButton.isEnabled = pictureInPictureController.isPictureInPicturePossible
        
        pictureInPictureObservations.append(pictureInPictureController.observe(\.isPictureInPictureActive) { [weak self] pictureInPictureController, change in
            guard let `self` = self else { return }
            
            self.pipToggleButton.isSelected = pictureInPictureController.isPictureInPictureActive
        })
        
        pictureInPictureObservations.append(pictureInPictureController.observe(\.isPictureInPicturePossible) { [weak self] pictureInPictureController, change in
            guard let `self` = self else { return }
            
            self.pipToggleButton.isEnabled = pictureInPictureController.isPictureInPicturePossible
            
            if #available(iOS 14.2, *) {
                pictureInPictureController.canStartPictureInPictureAutomaticallyFromInline = true
            } else {
                // Fallback on earlier versions
            }
        })
    }
    
    // MARK: - Actions
    @IBAction func pipToggleButtonTapped() {
        if pipToggleButton.isSelected {
            self.movieView.isHidden = false
            self.playerView.isHidden = false
            pictureInPictureController.stopPictureInPicture()
        } else {
            self.playerView.isHidden = true
            self.movieView.isHidden = true
            pictureInPictureController.startPictureInPicture()
        }
    }
    
}

// MARK: - AVPictureInPictureControllerDelegate
extension CustomPlayerViewController: AVPictureInPictureControllerDelegate {
    
    func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        strongSelf = self
    }
    
    func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        strongSelf = nil
        self.movieView.isHidden = false
        self.playerView.isHidden = false
    }
    
    func picture(_ pictureInPictureController: AVPictureInPictureController, restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void) {
        
        self.movieView.isHidden = false
        self.playerView.isHidden = false
        
        if let delegate = delegate {
            delegate.customPlayerViewController(self, restoreUserInterfaceForPictureInPictureStopWithCompletionHandler: completionHandler)
        } else {
            completionHandler(true)
        }
    }
    
}

extension CustomPlayerViewController: VLCMediaPlayerDelegate {
    func mediaPlayerTimeChanged(_ aNotification: Notification!) {
        print("mediaPlayerItmeChanged")        
    }
    
    func mediaPlayerStateChanged(_ aNotification: Notification!) {
        print("stateChanged")
    }
}
