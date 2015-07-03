
import UIKit
import AVFoundation

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

