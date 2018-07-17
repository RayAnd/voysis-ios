import XCTest
@testable import Voysis

class VoysisTests: XCTestCase {

    let textResponse = "{\"type\":\"response\",\"entity\":{\"id\":\"1\",\"locale\":\"en-US\",\"conversationId\":\"1\",\"queryType\":\"text\",\"textQuery\":{\"text\":\"go to my cart\"},\"intent\":\"goToCart\",\"reply\":{\"text\":\"Here's what's in your cart\"},\"entities\":{\"products\":[]},\"_links\":{\"self\":{\"href\":\"/queries/1\"},\"audio\":{\"href\":\"/queries/1/audio\"}},\"_embedded\":{}},\"requestId\":\"0\",\"responseCode\":201,\"responseMessage\":\"Created\"}"
    let token = "{\"type\":\"response\",\"entity\":{\"token\":\"1\",\"expiresAt\":\"2018-04-17T14:14:06.701Z\"},\"requestId\":\"0\",\"responseCode\":200,\"responseMessage\":\"OK\"}"
    let feedback = "{\"type\":\"response\",\"entity\":{},\"requestId\":\"0\",\"responseCode\":200,\"responseMessage\":\"OK\"}"

    private var voysis: ServiceImpl!
    private var audioRecordManager: AudioRecordManagerMock!
    private var client: ClientMock!
    private var context: TestContext?
    private var tokenManager: TokenManager!
    private var refreshToken = "token"
    private var callbackMock = CallbackMock()

    override func setUp() {
        super.setUp()
        client = ClientMock()
        audioRecordManager = AudioRecordManagerMock()
        tokenManager = TokenManager(refreshToken: refreshToken, dispatchQueue: DispatchQueue.main)
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
        client.stringEvent.append(token)
        client.setupStreamEvent = "{\"type\":\"notification\",\"notificationType\":\"vad_stop\"}"
        audioRecordManager.onDataResponse = { (data: Data) in

        }
        audioRecordManager.stopWithData = true
        let callback = { (call: String) in
            if (call == "vadReceived") {
                vadReceived.fulfill()
            }
        }
        callbackMock.callback = callback
        voysis!.startAudioQuery(context: context, callback: callbackMock)
        waitForExpectations(timeout: 5, handler: nil)
    }

    func testSendTextRequest() {
        let decodedExpectation = expectation(description: "string decoded correctly")
        client.stringEvent.append(token)
        client.stringEvent.append(textResponse)
        let success = { (response: StreamResponse<TestContext, TestEntities>) in
            if (response.id == "1") {
                decodedExpectation.fulfill()
            }
        }
        callbackMock.success = success
        voysis!.sendTextQuery(text: "show me shoes", context: context, callback: callbackMock)
        waitForExpectations(timeout: 5, handler: nil)
    }

    func testSendTextRequestDecodingFail() {
        let failExpectation = expectation(description: "string decoded incorrectly")
        client.stringEvent.append(token)
        client.stringEvent.append("fail")
        let error = { (response: VoysisError) in
            switch response {
            case .serializationError:
                failExpectation.fulfill()
            default:
                XCTFail("Wrong Error")
            }
        }
        callbackMock.fail = error
        voysis!.sendTextQuery(text: "show me shoes", context: context, callback: callbackMock)
        waitForExpectations(timeout: 5, handler: nil)
    }

    func testSuccessFeedbackResponse() {
        let successResponse = expectation(description: "success")
        tokenManager.token = Token(expiresAt: "2018-04-17T14:14:06.701Z", token: "")
        client.stringEvent.append(token)
        client.stringEvent.append(feedback)
        let feedbackHandler = { (response: Int) in
            if response == 200 {
                successResponse.fulfill()
            }
        }
        voysis.sendFeedback(queryId: "1", feedback: FeedbackData(), feedbackHandler: feedbackHandler, errorHandler: { (_: VoysisError) in })
        waitForExpectations(timeout: 5, handler: nil)
    }

    func testCreateAndManualFinishRequest() {
        let endData = expectation(description: "one bytes sent at end")
        let startData = expectation(description: "two bytes sent at end")
        audioRecordManager.stopWithData = false
        client.stringEvent.append(token)
        client.dataCallback = { ( data: Data) in
            if data.count == 2 {
                startData.fulfill()
            } else if data.count == 1 {
                endData.fulfill()
            }
        }
        voysis.startAudioQuery(context: context, callback: callbackMock)
        voysis.finish()
        waitForExpectations(timeout: 5, handler: nil)

    }

    func testErrorResponse() {
        let errorReceived = expectation(description: "error received")
        client.error = VoysisError.unknownError
        client.stringEvent.append(token)
        let error = { (response: VoysisError) in
            switch response {
            case .unknownError:
                errorReceived.fulfill()
            default:
                XCTFail("Wrong Error")
            }
        }
        callbackMock.fail = error
        voysis.startAudioQuery(context: context, callback: callbackMock)
        waitForExpectations(timeout: 5, handler: nil)
    }

    func testStateChanges() {
        XCTAssertEqual(voysis.state, State.idle)
        client.stringEvent.append(token)
        client.setupStreamEvent = "{\"type\":\"notification\",\"notificationType\":\"vad_stop\"}"
        audioRecordManager.onDataResponse = { (data: Data) in
        }
        audioRecordManager.stopWithData = true
        let completed = expectation(description: "completed")
        let callback = { (call: String) in
            if (call == "vadReceived") {
                completed.fulfill()
                XCTAssertEqual(self.voysis.state, State.processing)
            }
        }
        callbackMock.callback = callback
        voysis.startAudioQuery(context: context, callback: callbackMock)
        XCTAssertEqual(voysis.state, State.recording)
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
        client.stringEvent.append(token)
        voysis.startAudioQuery(context: context, callback: callbackMock)
        waitForExpectations(timeout: 5, handler: nil)
    }
}
