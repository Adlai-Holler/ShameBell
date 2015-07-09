
import UIKit
import AVFoundation
import MediaPlayer

final class ViewController: UIViewController, AVAudioPlayerDelegate {
	enum ShameState {
		case Idle
		case ReadyToShame
		case Shame
		
		private init(touchingScreen: Bool, playingAudio: Bool) {
			if playingAudio {
				self = .Shame
			} else if touchingScreen {
				self = .ReadyToShame
			} else {
				self = .Idle
			}
		}
	}
	
	var shameState: ShameState = .Idle {
		didSet(oldValue) {
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

	
	var touchingScreen: Bool {
		return !touches.isEmpty
	}
	
	var playingAudio: Bool {
		return audioPlayer.playing
	}
	
	private func updateShameState() {
		shameState = ShameState(touchingScreen: touchingScreen, playingAudio: playingAudio)
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		volumeView.showsRouteButton = false
		updateShameState()
		audioPlayer.delegate = self
		
		let session = AVAudioSession.sharedInstance()
		session.setCategory(AVAudioSessionCategoryPlayback, withOptions: .MixWithOthers | .DefaultToSpeaker, error: nil)
		session.setPreferredOutputNumberOfChannels(1, error: nil)
		
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "deviceOrientationChanged", name: UIDeviceOrientationDidChangeNotification, object: UIDevice.currentDevice())
		deviceOrientationChanged()
	}

	func audioPlayerDidFinishPlaying(player: AVAudioPlayer!, successfully flag: Bool) {
		updateShameState()
	}
	
	func audioPlayerBeginInterruption(player: AVAudioPlayer!) {
		player.stop()
		updateShameState()
	}
	
	func pauseAudio() {
		audioPlayer.stop()
		updateShameState()
	}
	
	func playAudio() {
		audioPlayer.currentTime = 0
		audioPlayer.play()
		updateShameState()
	}
	
	var active = false {
		didSet {
			if !active {
				pauseAudio()
			}
		}
	}
	
	var touches: Set<NSObject> = [] {
		didSet {
			let newActive = !touches.isEmpty
			if newActive != active {
				active = newActive
			}
			updateShameState()
		}
	}
	
	override func motionBegan(motion: UIEventSubtype, withEvent event: UIEvent) {
		if active && !audioPlayer.playing {
			playAudio()
		}
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
	
	override func shouldAutorotate() -> Bool {
		return false
	}
	
	private func updateInfoLabel() {
		let text: String?
		let deviceUpsideDown = UIDevice.currentDevice().orientation == .PortraitUpsideDown
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
			self.infoLabel.transform = transform
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
	
	override func supportedInterfaceOrientations() -> Int {
		return UIInterfaceOrientation.Portrait.rawValue | UIInterfaceOrientation.PortraitUpsideDown.rawValue
	}
}

