import XCTest
@testable import Voysis

class StructTests: XCTestCase {

    func testHeaderCreation() {
        let header = Headers(token: "token")
        XCTAssertEqual(header.xVoysisIgnoreVad, false)
        XCTAssertEqual(header.authorization, "Bearer token")
        XCTAssertNotNil(header.audioProfileId)
        XCTAssertNotNil(header.userAgent)
    }

}

class QueryTest: XCTestCase {

    func testAudioQueryCreation() {
        let query = AudioQuery()
        XCTAssertEqual(query.mimeType, "audio/pcm;bits=16;rate=16000")
    }
}
