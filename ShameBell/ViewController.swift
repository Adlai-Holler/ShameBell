
import UIKit
import AVFoundation

final class ActiveView: UIView {
	static let onColor = UIColor(red: 0.8, green: 0.2, blue: 0.1, alpha: 1)
	override class func layerClass() -> AnyClass {
		return CAShapeLayer.self
	}
	
	override func drawRect(rect: CGRect) {
		ActiveView.onColor.setFill()
		UIBezierPath(ovalInRect: bounds).fill()
	}
	
	override func intrinsicContentSize() -> CGSize {
		let dim: CGFloat = 198
		return CGSize(width: dim, height: dim)
	}
}

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
				titleLabel.hidden = true
			case .ReadyToShame:
				titleLabel.hidden = false
				titleLabel.alpha = 0.5
				titleLabel.text = "Shame?"
			case .Shame:
				titleLabel.hidden = false
				titleLabel.alpha = 1
				titleLabel.text = "Shame"
			}
		}
	}
	
	let audioPlayer: AVAudioPlayer = AVAudioPlayer(contentsOfURL: NSBundle.mainBundle().URLForResource("shame_sfx", withExtension: "mp3")!, error: nil)
	@IBOutlet weak var titleLabel: UILabel!
	let activeView = ActiveView()
	
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
		updateShameState()
		audioPlayer.delegate = self
		view.addSubview(activeView)
		
		// center active view in self
		let centerX = NSLayoutConstraint(item: activeView, attribute: .CenterX, relatedBy: .Equal, toItem: view, attribute: .CenterX, multiplier: 1.0, constant: 0)
		view.addConstraint(centerX)
		
		// active view starts at 200pt down from top
		let topSpace = NSLayoutConstraint(item: activeView, attribute: .Top, relatedBy: .Equal, toItem: view, attribute: .Top, multiplier: 1.0, constant: 200)
		view.addConstraint(topSpace)
		
		view.backgroundColor = UIColor.blackColor()
		
		AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, error: nil)
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
}

