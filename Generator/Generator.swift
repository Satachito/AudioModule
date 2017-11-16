import UIKit

@UIApplicationMain class
AppDelegate: UIResponder, UIApplicationDelegate {
	var
	window: UIWindow?
}

class
GeneratorVC: UIViewController {

	var
	m = try! Generator()

	func
	Sin(
		actionFlags	: UnsafeMutablePointer<AudioUnitRenderActionFlags>
	,	timestamp	: UnsafePointer<AudioTimeStamp>
	,	numberFrames: AUAudioFrameCount
	,	busNumber	: Int
	,	data		: UnsafeMutablePointer<AudioBufferList>
	) -> AUAudioUnitStatus {
		let wABLP = UnsafeMutableAudioBufferListPointer( data )
		var	w: [ UnsafeMutablePointer<Float> ] = []
		for i in 0 ..< wABLP.count { w.append( UnsafeMutablePointer<Float>( OpaquePointer( wABLP[ i ].mData! ) ) ) }
		let wSR = Float( self.m.sampleRate )
		for j in 0 ..< Int( numberFrames ) {
			let	wPhase = Float( ( Int( timestamp.pointee.mSampleTime ) + j ) * 2 ) * Float.pi / wSR
			for i in 0 ..< wABLP.count { w[ i ][ j ] = sin( wPhase * Float( 220 + ( 220 * ( i + 1 ) ) ) ) }
		}
		return 0
	}
	
	func
	Square(
		actionFlags	: UnsafeMutablePointer<AudioUnitRenderActionFlags>
	,	timestamp	: UnsafePointer<AudioTimeStamp>
	,	numberFrames: AUAudioFrameCount
	,	busNumber	: Int
	,	data		: UnsafeMutablePointer<AudioBufferList>
	) -> AUAudioUnitStatus {
		let wABLP = UnsafeMutableAudioBufferListPointer( data )
		var	w: [ UnsafeMutablePointer<Float> ] = []
		for i in 0 ..< wABLP.count { w.append( UnsafeMutablePointer<Float>( OpaquePointer( wABLP[ i ].mData! ) ) ) }
		let wSR = Float( self.m.sampleRate )
		for j in 0 ..< Int( numberFrames ) {
			let	wTimeX2 = Float( ( Int( timestamp.pointee.mSampleTime ) + j ) * 2 ) / wSR
			for i in 0 ..< wABLP.count {
				w[ i ][ j ] = Int( wTimeX2 * Float( 220 + ( 220 * ( i + 1 ) ) ) ) % 2 == 0 ? 1 : -1
			}
		}
		return 0
	}
	
	@IBAction func
	ToggleA( _: Any? ) {
		try! m.Toggle()
	}
	@IBAction func
	SinA( _: Any? ) {
		m.auau.outputProvider = Sin
	}
	@IBAction func
	SquareA( _: Any? ) {
		m.auau.outputProvider = Square
	}
}

import AudioUnit
import AVFoundation

class
Generator {
	
	var
	auau: AUAudioUnit
	
	var
	sampleRate: Int

	var
	isRunning = false

	deinit {
		auau.deallocateRenderResources()
	}

	init( _ sampleRate: Int = 44100, _ numChannels: AVAudioChannelCount = 2 ) throws {
		
		self.sampleRate = sampleRate

		try auau = AUAudioUnit(
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

		auau.isInputEnabled = true
		
		try auau.allocateRenderResources()
	}

	func
	Toggle() throws {
		if isRunning	{ auau.stopHardware() }
		else			{ try auau.startHardware() }
		isRunning = !isRunning
	}
}

