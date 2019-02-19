import XCTest
@testable import Voysis

class UtilTests: XCTestCase {

    private var sessionMock = AudioSessionMock()

    func testGenerateAudioRecordParamsDefaultSampleRate() {
        let config = DataConfig(url: URL(string: "https://test.com")!, refreshToken: "123")
        let audioRecordParams = Utils.generateAudioRecordParams(config, sessionMock)
        XCTAssertEqual(AudioSessionMock.TEST_DEFAULT_SAMPLE_RATE, audioRecordParams.sampleRate)
    }

    func testGenerateAudioRecordParamsOverrideValues() {
        let audioRecordParams = AudioRecordParams(sampleRate: 123.0, readBufferSize: 321)
        let config = DataConfig(url: URL(string: "https://test.com")!, refreshToken: "123", audioRecordParams: audioRecordParams)
        let generatedParams = Utils.generateAudioRecordParams(config, sessionMock)
        XCTAssertEqual(audioRecordParams.sampleRate, generatedParams.sampleRate)
        XCTAssertEqual(audioRecordParams.readBufferSize, generatedParams.readBufferSize)
    }

    func testMaxRecordingLength() {
        XCTAssertEqual(320000, Utils.calculateMaxRecordingLength(16000))
        XCTAssertEqual(820000, Utils.calculateMaxRecordingLength(41000))
        XCTAssertEqual(960000, Utils.calculateMaxRecordingLength(48000))
    }
}
