import XCTest
@testable import Voysis

class VoysisTests: XCTestCase {

    let token = "{\"type\":\"response\",\"entity\":{\"token\":\"1\",\"expiresAt\":\"2018-04-17T14:14:06.701Z\"},\"requestId\":\"0\",\"responseCode\":200,\"responseMessage\":\"OK\"}"
    let feedback = "{\"type\":\"response\",\"entity\":{},\"requestId\":\"0\",\"responseCode\":200,\"responseMessage\":\"OK\"}"

    private var voysis: ServiceImpl!
    private var audioRecordManager: AudioRecordManagerMock!
    private var client: ClientMock!
    private var context: TestContext?
    private var tokenManager: TokenManager!
    private var resreshToken = "token"
    private var callbackMock = CallbackMock()

    override func setUp() {
        super.setUp()
        client = ClientMock()
        audioRecordManager = AudioRecordManagerMock()
        tokenManager = TokenManager(refreshToken: resreshToken, dispatchQueue: DispatchQueue.main)
        let feedbackManager = FeedbackManager(DispatchQueue.main)
        voysis = ServiceImpl(client: client,
                recorder: audioRecordManager,
                dispatchQueue: DispatchQueue.main,
                feedbackManager: feedbackManager,
                tokenManager: tokenManager,
                userId: "")

        //closure cannot be null but is not required for most tests.
        client.dataCallback = { ( data: Data) in
        }
    }

    override func tearDown() {
        super.tearDown()
        voysis = nil
        audioRecordManager = nil
        client = nil

    }

    func testCreateAndFinishRequestWithVad() {
        let vadReceived = expectation(description: "vad received")
        client.stringEvent = token
        client.setupStreamEvent = "{\"type\":\"notification\",\"notificationType\":\"vad_stop\"}"
        audioRecordManager.onDataResponse = { (data: Data, isRecording: FinishedReason?) in
        }
        let callback = { (call: String) in
            if (call == "vadReceived") {
                vadReceived.fulfill()
            }
        }
        callbackMock.callback = callback
        voysis!.startAudioQuery(context: context, callback: callbackMock)
        waitForExpectations(timeout: 5, handler: nil)
    }

    func testSuccessFeedbackResponse() {
        let successResponse = expectation(description: "success")
        tokenManager.token = Token(expiresAt: "2018-04-17T14:14:06.701Z", token: "")
        client.stringEvent = token
        let feedbackHandler = { (response: Int) in
            if response == 200 {
                successResponse.fulfill()
            }
        }
        voysis.sendFeedback(queryId: "1", feedback: FeedbackData(), feedbackHandler: feedbackHandler, errorHandler: { (_: VoysisError) in })
        waitForExpectations(timeout: 5, handler: nil)
    }

    func testCreateAndManualFinishRequest() {
        let endData = expectation(description: "4 bytes sent at end")
        client.dataCallback = { ( data: Data) in
            XCTAssertTrue(data.count == 1)
            endData.fulfill()
        }
        client.stringEvent = token
        voysis.startAudioQuery(context: context, callback: callbackMock)
        voysis.finish()
        waitForExpectations(timeout: 5, handler: nil)

    }

    func testErrorResponse() {
        let errorReceived = expectation(description: "error received")
        client.error = VoysisError.unknownError
        let callback = { (call: String) in
            if call == "failure" {
                errorReceived.fulfill()
            }
        }
        callbackMock.callback = callback
        voysis.startAudioQuery(context: context, callback: callbackMock)
        waitForExpectations(timeout: 5, handler: nil)
    }

    func testStateChanges() {
        XCTAssertEqual(voysis.state, State.idle)
        client.stringEvent = token
        client.setupStreamEvent = "{\"type\":\"notification\",\"notificationType\":\"vad_stop\"}"
        audioRecordManager.onDataResponse = { (data: Data, isRecording: Bool) in
        }
        let completed = expectation(description: "completed")
        let callback = { (call: String) in
            if (call == "vadReceived") {
                completed.fulfill()
            }
        }
        callbackMock.callback = callback
        voysis.startAudioQuery(context: context, callback: callbackMock)
        XCTAssertEqual(voysis.state, State.busy)
        waitForExpectations(timeout: 5, handler: nil)
    }

    func testMaxByteLimitOnRequest() {
        let completed = expectation(description: "max bytes exceeded. byte(4) sent at end ")
        audioRecordManager.data = Data(bytes: [0xFF, 0xD9] as [UInt8], count: 320001)
        client.dataCallback = { ( data: Data) in
            if (data.count == 1) {
                completed.fulfill()
            }
        }
        client.stringEvent = token
        voysis.startAudioQuery(context: context, callback: callbackMock)
        waitForExpectations(timeout: 5, handler: nil)
    }
}
