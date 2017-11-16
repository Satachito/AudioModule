import UIKit

@UIApplicationMain class
AppDelegate: UIResponder, UIApplicationDelegate {
	var
	window: UIWindow?
}

class
PassThroughVC: UIViewController {

	var
	m = try! PassThrough()

	@IBAction func
	ToggleA( _: Any? ) {
		try! m.Toggle()
	}
}

import AudioUnit
import AVFoundation

class
PassThrough {
	
	var
	auau: AUAudioUnit
	
	var
	isRunning = false

	var
	abl: UnsafeMutablePointer<AudioBufferList>?
	
	deinit {
		auau.deallocateRenderResources()
	}

	init( _ sampleRate: Int = 44100, _ numChannels: AVAudioChannelCount = 2 ) throws {
		
		auau = try AUAudioUnit(
			componentDescription: AudioComponentDescription(
				componentType			: kAudioUnitType_Output
			,	componentSubType		: kAudioUnitSubType_RemoteIO
			,	componentManufacturer	: kAudioUnitManufacturer_Apple
			,	componentFlags			: 0
			,	componentFlagsMask		: 0
			)
		)

		try auau.inputBusses[ 0 ].setFormat(
			AVAudioFormat( standardFormatWithSampleRate: Double( sampleRate ), channels: numChannels )!
		)
		try auau.outputBusses[ 1 ].setFormat( auau.inputBusses[ 0 ].format )

		auau.isInputEnabled = true
		auau.inputHandler = {
			( actionFlags, timestamp, numberFrames, busNumber ) in
			guard let wABL = self.abl else { return }
			let _ = self.auau.renderBlock(
				actionFlags
			,	timestamp
			,	numberFrames
			,	busNumber
			,	wABL
			,	nil
			)
		}

		auau.outputProvider = {
			( actionFlags, timestamp, numberFrames, busNumber, data ) -> AUAudioUnitStatus in
			self.abl = data
			return 0
		}

		try auau.allocateRenderResources()
	}

	func
	Toggle() throws {
		if isRunning	{ auau.stopHardware() }
		else			{ try auau.startHardware() }
		isRunning = !isRunning
	}
}

