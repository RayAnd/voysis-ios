import AVFoundation

internal class ServiceImpl: Service {
    private let session = AVAudioSession.sharedInstance()
    private let feedbackManager: FeedbackManager
    private let dispatchQueue: DispatchQueue
    private let tokenManager: TokenManager
    private let audioQueue: OperationQueue
    private let recorder: AudioRecorder
    private let client: Client
    private let userId: String?

    private var finishedReason: FinishedReason?
    private var byteSender: ByteSender?
    private var maxBytes = 320000

    public var state = State.idle

    init(client: Client,
         recorder: AudioRecorder,
         dispatchQueue: DispatchQueue,
         feedbackManager: FeedbackManager,
         tokenManager: TokenManager,
         userId: String?) {
        self.client = client
        self.recorder = recorder
        self.tokenManager = tokenManager
        self.userId = userId
        self.dispatchQueue = dispatchQueue
        self.feedbackManager = feedbackManager
        audioQueue = OperationQueue()
        audioQueue.name = "VoysisAudioRequests"
        audioQueue.maxConcurrentOperationCount = 1
        audioQueue.isSuspended = true
    }

    public func startAudioQuery<C, E, T: Callback>(context: C?, callback: T) where T.C == C, T.E == E {
        let dispatcher = CallbackDispatcher(dispatchQueue, callback)
        if state != .idle {
            dispatcher.failure(.duplicateProcessingRequest)
            return
        }
        session.requestRecordPermission { granted in
            guard granted else {
                dispatcher.failure(.permissionNotGrantedError)
                return
            }
            self.performAudioQuery(context, dispatcher)
        }
    }

    public func finish() {
        state = .processing
        stop(.manualStop, Data([4]))
    }

    public func cancel() {
        stop(.manualStop)
        client.cancelAudioStream()
        state = .idle
    }

    public func refreshSessionToken(tokenHandler: @escaping TokenHandler, errorHandler: @escaping ErrorHandler) {
        tokenManager.tokenHandler = tokenHandler
        tokenManager.tokenErrorHandler = errorHandler
        do {
            let requestEntity = RequestEntity(userId: userId, context: nil as EmptyContext?)
            let request = SocketRequest(entity: requestEntity, method: "POST", headers: Headers(token: tokenManager.refreshToken), restURI: "/tokens")
            let entity = try Converter.encodeRequest(socketRequest: request)
            client.sendString(entity: entity!, onMessage: tokenManager.onTokenMessage, onError: tokenManager.onError)
        } catch {
            if let error = error as? VoysisError {
                tokenManager.onError(error)
            }
        }
    }

    public func sendFeedback(queryId: String, feedback: FeedbackData, feedbackHandler: @escaping FeedbackHandler, errorHandler: @escaping ErrorHandler) {
        feedbackManager.feedbackHandler = feedbackHandler
        feedbackManager.feedbackErrorHandler = errorHandler
        if tokenManager.tokenIsValid() {
            sendFeedback(feedback: feedback, queryId: queryId)
        } else {
            refreshSessionToken(tokenHandler: { _ in self.sendFeedback(feedback: feedback, queryId: queryId) }, errorHandler: feedbackManager.onError)
        }
    }

    private func sendFeedback(feedback: FeedbackData, queryId: String) {
        do {
            let request = SocketRequest(entity: feedback, method: "PATCH", headers: Headers(token: tokenManager.token!.token), restURI: "/queries/\(queryId)/feedback")
            let entity = try Converter.encodeRequest(socketRequest: request)
            client.sendString(entity: entity!, onMessage: feedbackManager.onMessage, onError: feedbackManager.onError)
        } catch {
            if let error = error as? VoysisError {
                feedbackManager.onError(error)
            }
        }
    }

    private func performAudioQuery<C: Context, T: Callback>(_ context: C?, _ dispatcher: CallbackDispatcher<T>) {
        state = .recording
        startRecording(dispatcher)
        if tokenManager.tokenIsValid() {
            startAudioQuery(context, dispatcher)
        } else {
            refreshSessionToken(tokenHandler: { _ in self.startAudioQuery(context, dispatcher) }, errorHandler: { self.onError($0, dispatcher) })
        }
    }

    private func startAudioQuery<C: Context, T: Callback>(_ context: C?, _ dispatcher: CallbackDispatcher<T>) {
        do {
            let entity = RequestEntity(userId: userId, context: context)
            let request = SocketRequest(entity: entity, method: "POST", headers: Headers(token: tokenManager.token!.token), restURI: "/queries")
            if let entity = try Converter.encodeRequest(socketRequest: request) {
                byteSender = client.setupAudioStream(entity: entity, onMessage: { self.onMessage($0, dispatcher) }, onError: { self.onError($0, dispatcher) })
                audioQueue.isSuspended = false
            }
        } catch {
            dispatcher.failure(.requestEncodingError)
        }
    }

    private func startRecording<T: Callback>(_ callback: CallbackDispatcher<T>) {
        audioQueue.cancelAllOperations()
        audioQueue.isSuspended = true
        byteSender = nil
        var bytesRead = 0
        recorder.start {
            self.audioCallback($0, &bytesRead, callback)
        }
        callback.recordingStarted()
    }

    private func audioCallback<T: Callback>(_ data: Data, _ bytesRead: inout Int, _ dispatcher: CallbackDispatcher<T>) {
        guard !data.isEmpty else {
            return
        }
        queueAudio(data)
        dispatcher.audioData(data)
        bytesRead += data.count
        if bytesRead >= maxBytes {
            finish()
        }
        if finishedReason != nil && state == .processing {
            dispatcher.recordingFinished(finishedReason!)
            finishedReason = nil
        }
    }

    private func stop(_ reason: FinishedReason, _ data: Data? = nil) {
        finishedReason = reason
        recorder.stop()
        queueAudio(data)
    }

    private func queueAudio(_ data: Data?) {
        audioQueue.addOperation {
            if data != nil {
                self.byteSender?(data!)
            }
        }
    }

    private func onError<T: Callback>(_ error: VoysisError, _ dispatcher: CallbackDispatcher<T>) {
        cancel()
        dispatcher.failure(error)
    }

    private func onMessage<T: Callback>(_ data: String, _ dispatcher: CallbackDispatcher<T>) {
        do {
            let event = try Converter.decodeResponse(json: data, context: T.C.self, entity: T.E.self)
            switch event.type {
            case .vadReceived:
                state = .processing
                stop(.vadReceived)
            case .audioQueryCompleted:
                state = .idle
                dispatcher.success(event.response! as! StreamResponse<T.C, T.E>)
            case .audioQueryCreated:
                dispatcher.queryResponse(event.response as! QueryResponse)
            }
        } catch {
            cancel()
            if let error = error as? VoysisError {
                dispatcher.failure(error)
            }
        }
    }

}
