import Foundation

class TestContext: Context {
}

class TestEntities: Entities {
}

class CallbackMock: Callback {

    var callback: ((String) -> Void)?
    var success : ((StreamResponse<TestContext, TestEntities>) -> Void)?
    var fail : ((VoysisError) -> Void)?

    func success(response: StreamResponse<TestContext, TestEntities>) {
        success?(response)
    }

    func failure(error: VoysisError) {
        fail?(error)
    }

    func recordingStarted() {
        callback?("recordingStarted")
    }

    func queryResponse(queryResponse: QueryResponse) {
        callback?("queryResponse")
    }

    func recordingFinished(reason: FinishedReason) {
        switch reason {
        case .vadReceived:
            callback?("vadReceived")
        case .manualStop:
            callback?("manualStop")
        }
    }

    func audioData(data: Data) {
        callback?("audioData")
    }
}