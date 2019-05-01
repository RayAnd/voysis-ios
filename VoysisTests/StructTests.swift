import XCTest
@testable import Voysis

class StructTests: XCTestCase {

    func testHeaderCreation() {
        let header = Headers(token: "token", xVoysisIgnoreVad: true)
        XCTAssertEqual(header.xVoysisIgnoreVad, true)
        XCTAssertEqual(header.authorization, "Bearer token")
        XCTAssertNotNil(header.audioProfileId)
        XCTAssertNotNil(header.xVoysisClientInfo)
    }

    func testStreamResponse() {
        let streamResponse = generateResponse()
        XCTAssertEqual(streamResponse.id, "1")
        XCTAssertEqual(streamResponse.locale, "US")
        XCTAssertEqual(streamResponse.conversationId, "1")
        XCTAssertEqual(streamResponse.queryType, "audio")
        XCTAssertEqual(streamResponse.audioQuery!.mimeType, "audio/pcm;bits=16;rate=16000")
        XCTAssertEqual(streamResponse.intent, "testIntent")
        XCTAssertEqual(streamResponse.textQuery!.text, "testQuery")
        XCTAssertEqual(streamResponse.reply!.text, "reply")
        XCTAssertEqual(streamResponse.reply!.audioUri, "test.com")
        XCTAssertEqual(streamResponse.hint!.text, "hint")
        XCTAssertEqual(streamResponse.hint!.audioUri, "test.com")
    }

    public func generateResponse() -> StreamResponse<TestContext, TestEntities> {
        let id = "1";
        let locale = "US";
        let conversationId = "1";
        let queryType = "audio";
        let context = TestContext()
        let entities = TestEntities()
        let audioQuery = AudioQuery(mimeType: "audio/pcm;bits=16;rate=16000")
        let textQuery = TextQuery(text: "testQuery")
        let intent = "testIntent"
        let reply = TextWithAudio(text: "reply", audioUri: "test.com")
        let hint = TextWithAudio(text: "hint", audioUri: "test.com")
        let response = StreamResponse<TestContext, TestEntities>(
                id: id,
                locale: locale,
                conversationId: conversationId,
                queryType: queryType,
                audioQuery: audioQuery,
                textQuery: textQuery,
                intent: intent,
                reply: reply,
                hint: hint,
                entities: entities,
                context: context,
                _links: nil)
        return response
    }

}
