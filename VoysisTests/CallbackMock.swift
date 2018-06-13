import Foundation

class TestContext: Context {
}

class TestEntities: Entities {
}

class CallbackMock: Callback {

    var callback: ((String) -> Void)?

    func success(response: StreamResponse<TestContext, TestEntities>) {
        callback?("success")
    }

    func failure(error: VoysisError) {
        callback?("failure")
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