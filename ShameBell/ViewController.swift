
import UIKit
import AVFoundation
import MediaPlayer

private let shameLength: NSTimeInterval = 6

final class ViewController: UIViewController, AVAudioPlayerDelegate {
	enum ShameState {
		case Idle
		case ReadyToShame
		case Shame
		
		var stateByShaking: ShameState {
			if self == .ReadyToShame {
				return .Shame
			} else {
				return self
			}
		}

		var stateByEndingAudio: ShameState {
			if self == .Shame {
				return .ReadyToShame
			} else {
				return self
			}
		}
		
		var stateByEndingTouch: ShameState {
			return .Idle
		}
		
		var stateByBeginningTouch: ShameState {
			if self == .Idle {
				return .ReadyToShame
			} else {
				return self
			}
		}

	}
	
	var shameState: ShameState = .Idle {
		didSet(oldValue) {
			// Audio player
			if shameState == .Shame && !audioPlayer.playing {
				audioPlayer.currentTime = 0
				audioPlayer.play()
			} else if shameState != .Shame && audioPlayer.playing {
				audioPlayer.stop()
			}
			
			// Image view alpha
			switch shameState {
			case .Idle:
				imageView.alpha = 0.5
			case .ReadyToShame, .Shame:
				imageView.alpha = 1
			}
			
			updateInfoLabel()
		}
	}
	
	static let infoAttr = [
		NSFontAttributeName: UIFont(name: "AvenirNext-Bold", size: 20)!,
		NSForegroundColorAttributeName: UIColor(red: 0.384, green: 0.373, blue: 0.439, alpha: 1),
		NSKernAttributeName: 0.3
	]

	@IBOutlet var infoLabel: UILabel!
	@IBOutlet var volumeView: MPVolumeView!
	@IBOutlet var imageView: UIImageView!
	let audioPlayer = AVAudioPlayer(contentsOfURL: NSBundle.mainBundle().URLForResource("shame_sfx_4", withExtension: "m4a")!, error: nil)
	@IBOutlet weak var titleLabel: UILabel!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		volumeView.showsRouteButton = false
		audioPlayer.delegate = self
		
		let session = AVAudioSession.sharedInstance()
		session.setCategory(AVAudioSessionCategoryPlayback, withOptions: .MixWithOthers | .DefaultToSpeaker, error: nil)
		session.setPreferredOutputNumberOfChannels(1, error: nil)
		
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "deviceOrientationChanged", name: UIDeviceOrientationDidChangeNotification, object: UIDevice.currentDevice())
		deviceOrientationChanged()
		
		// force shame state render (ugh)
		let state = shameState
		shameState = state
	}

	func audioPlayerDidFinishPlaying(player: AVAudioPlayer!, successfully flag: Bool) {
		shameState = shameState.stateByEndingAudio
	}
	
	func audioPlayerBeginInterruption(player: AVAudioPlayer!) {
		shameState = shameState.stateByEndingAudio
	}
	
	var touches: Set<NSObject> = [] {
		didSet {
			if touches.isEmpty {
				shameState = shameState.stateByEndingTouch
			} else {
				shameState = shameState.stateByBeginningTouch
			}
		}
	}
	
	override func motionBegan(motion: UIEventSubtype, withEvent event: UIEvent) {
		shameState = shameState.stateByShaking
	}
	
	override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
		for touch in touches {
			self.touches.insert(touch)
		}
	}

	override func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent) {
		for touch in touches {
			self.touches.remove(touch)
		}
	}
	
	override func touchesCancelled(touches: Set<NSObject>!, withEvent event: UIEvent!) {
		for touch in touches {
			self.touches.remove(touch)
		}
	}
	
	override func prefersStatusBarHidden() -> Bool {
		return true
	}
	
	private func updateInfoLabel() {
		let text: String?
		let deviceUpsideDown = UIDevice.currentDevice().orientation == .PortraitUpsideDown
		let deviceIsPortrait = UIDevice.currentDevice().orientation.isPortrait
		let transform = deviceUpsideDown ? CGAffineTransformMakeScale(-1, -1) : CGAffineTransformIdentity
		switch shameState {
		case .Shame:
			text = nil
		case .ReadyToShame:
			text = "RING THE BELL"
		case .Idle:
			if !deviceUpsideDown {
				text = "HOLD PHONE UPSIDE DOWN"
			} else {
				text = "TAP AND HOLD"
			}
		}
		self.infoLabel.attributedText = NSAttributedString(string: text ?? "", attributes: ViewController.infoAttr)
		UIView.animateWithDuration(0.4, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.7, options: .BeginFromCurrentState, animations: {
			if deviceIsPortrait {
				self.infoLabel.transform = transform
			}
			if let text = text {
				self.infoLabel.alpha = 1
			} else {
				self.infoLabel.alpha = 0
			}
			
		}, completion: nil)
		
	}
	
	@objc private func deviceOrientationChanged() {
		updateInfoLabel()
	}

}

