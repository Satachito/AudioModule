import UIKit

@UIApplicationMain class
AppDelegate: UIResponder, UIApplicationDelegate {
	var
	window: UIWindow?
}

class
NSecVC: UIViewController {

	var
	m = try! NSec()

	@IBAction func
	ToggleA( _: Any? ) {
		try! m.Toggle()
	}
}

import AudioUnit
import AVFoundation

class
NSec {
	
	var
	auau: AUAudioUnit
	
	var
	isRunning = false

	var
	abl: UnsafeMutablePointer<AudioBufferList>?
	
	var
	buffer = [ [ Float ] ]()
	
	var
	writeHead: Int
	
	var
	readHead: Int
	
	deinit {
		auau.deallocateRenderResources()
	}
	
	init( _ sampleRate: Int = 44100, _ numChannels: AVAudioChannelCount = 2 ) throws {
		
		let	wBufferLength = sampleRate * 2
		writeHead = 0
		readHead = sampleRate
		
		for _ in 0 ..< numChannels {
			buffer.append( Array( repeating: Float( 0.0 ), count: wBufferLength ) )
		}
		
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
		try auau.outputBusses[ 1 ].setFormat( auau.inputBusses[ 0 ].format )

		auau.isInputEnabled = true
		auau.inputHandler = {
			( actionFlags, timestamp, numberFrames, busNumber ) in
			guard let wABL = self.abl else { return }
			if self.auau.renderBlock(
				actionFlags
			,	timestamp
			,	numberFrames
			,	busNumber
			,	wABL
			,	nil
			) == 0 {
				let wABLP = UnsafeMutableAudioBufferListPointer( wABL )
				var	w = [ UnsafePointer<Float> ]()
				for i in 0 ..< wABLP.count { w.append( UnsafePointer<Float>( OpaquePointer( wABLP[ i ].mData! ) ) ) }
				for j in 0 ..< Int( numberFrames ) {
					for i in 0 ..< wABLP.count { self.buffer[ i ][ self.writeHead ] = w[ i ][ j ] }
					self.writeHead += 1
					if self.writeHead == wBufferLength { self.writeHead = 0 }
				}
			}
		}

		auau.outputProvider = {
			( actionFlags, timestamp, numberFrames, busNumber, data ) -> AUAudioUnitStatus in
			self.abl = data
			let wABLP = UnsafeMutableAudioBufferListPointer( data )
			var	w = [ UnsafeMutablePointer<Float> ]()
			for i in 0 ..< wABLP.count { w.append( UnsafeMutablePointer<Float>( OpaquePointer( wABLP[ i ].mData! ) ) ) }
			for j in 0 ..< Int( numberFrames ) {
				for i in 0 ..< wABLP.count { w[ i ][ j ] = self.buffer[ i ][ self.readHead ] }
				self.readHead += 1
				if self.readHead == wBufferLength { self.readHead = 0 }
			}
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


