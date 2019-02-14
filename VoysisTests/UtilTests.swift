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
}
