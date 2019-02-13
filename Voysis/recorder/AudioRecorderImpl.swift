import Foundation
import AudioToolbox
import AVFoundation

class AudioRecorderImpl: AudioRecorder {

    internal var onDataResponse: ((Data) -> Void)?
    private var format = AudioStreamBasicDescription()
    private let audioParams: AudioRecordParams
    private var queue: AudioQueueRef?
    private var player: AudioPlayer
    private var inProgress = false
    private var bufferRefs = [UnsafeMutablePointer<AudioQueueBufferRef?>]()

    public convenience init(config: Config) {
        self.init(config: config, session: AudioSession(), player: AudioPlayerImpl())
    }

    public init(config: Config, session: AudioSession, player: AudioPlayer) {
        self.audioParams = Utils.generateAudioRecordParams(config, session)
        self.player = player
        setFormatDescription()
    }

    public func start(onDataResponse: @escaping ((Data) -> Void)) {
        guard !inProgress else {
            return
        }
        self.onDataResponse = onDataResponse
        setupAudioQueue()
        inProgress = true
        player.playStartAudio { [weak self] in
            guard let this = self else {
                return
            }
            guard let queue = this.queue else {
                return
            }
            AudioQueueStart(queue, nil)
        }
    }

    public func stop() {
        guard inProgress else {
            return
        }

        guard let queue = queue else {
            return
        }
        inProgress = false
        AudioQueueFlush(queue)
        AudioQueueStop(queue, true)
        AudioQueueDispose(queue, true)
        clearBuffers()
        player.playStopAudio()
    }

    private func clearBuffers() {
        for buffer in bufferRefs {
            buffer.deallocate()
        }
        bufferRefs.removeAll()
    }

    private func setFormatDescription() {
        var formatFlags = AudioFormatFlags()
        formatFlags |= kLinearPCMFormatFlagIsSignedInteger
        formatFlags |= kLinearPCMFormatFlagIsPacked
        format = AudioStreamBasicDescription(
                mSampleRate: audioParams.sampleRate!,
                mFormatID: kAudioFormatLinearPCM,
                mFormatFlags: formatFlags,
                mBytesPerPacket: UInt32(1 * MemoryLayout<Int16>.stride),
                mFramesPerPacket: 1,
                mBytesPerFrame: UInt32(1 * MemoryLayout<Int16>.stride),
                mChannelsPerFrame: 1,
                mBitsPerChannel: 16,
                mReserved: 0
        )
    }

    private let callback: AudioQueueInputCallback = { data, queue, bufferRef, _, _, _ in
        guard let data = data else {
            return
        }
        let audioRecorder = Unmanaged<AudioRecorderImpl>.fromOpaque(data).takeUnretainedValue()

        let buffer = bufferRef.pointee
        autoreleasepool {
            let data = Data(bytes: buffer.mAudioData, count: Int(buffer.mAudioDataByteSize))
            audioRecorder.onDataResponse?(data)
        }

        // return early if recording is stopped
        guard audioRecorder.inProgress else {
            return
        }

        if let queue = audioRecorder.queue {
            AudioQueueEnqueueBuffer(queue, bufferRef, 0, nil)
        }
    }

    private func setupAudioQueue() {
        let pointer = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        AudioQueueNewInput(&format, callback, pointer, nil, nil, 0, &queue)

        guard let queue = queue else {
            return
        }

        // update audio format
        var formatSize = UInt32(MemoryLayout<AudioStreamBasicDescription>.stride)
        AudioQueueGetProperty(queue, kAudioQueueProperty_StreamDescription, &format, &formatSize)

        // allocate and enqueue buffers
        let numBuffers = 2
        let bufferSize = UInt32(audioParams.readBufferSize!)
        for _ in 0..<numBuffers {
            let bufferRef = UnsafeMutablePointer<AudioQueueBufferRef?>.allocate(capacity: 1)
            bufferRefs.append(bufferRef)
            AudioQueueAllocateBuffer(queue, bufferSize, bufferRef)
            if let buffer = bufferRef.pointee {
                AudioQueueEnqueueBuffer(queue, buffer, 0, nil)
            }
        }
    }
}
